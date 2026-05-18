# CLAUDE.md

Uptizm — website monitoring (up/down + custom metrics) on web, Android, iOS.
Stack: **magic** (Laravel-inspired Flutter) + **magic_starter** (auth/profile/teams) + **wind** (Tailwind-for-Flutter).
Backend API: sibling repo `../uptizm-api`.

## In-House SDKs (read-only vendored source)

| Package       | Source                     |
|---------------|----------------------------|
| magic         | `references/magic`         |
| magic_starter | `references/magic_starter` |
| wind          | `references/wind`          |

Research only. NEVER patch in-place — open a GitHub issue on the upstream repo instead.

## Commands

| Command                                 | Description                         |
|-----------------------------------------|-------------------------------------|
| `flutter test`                          | Run all tests (baseline: 145 green) |
| `dart format lib/ test/`                | Format (must produce no diff)       |
| `dart analyze`                          | Static analysis (zero issues)       |
| `flutter run -d chrome` / `-d <device>` | Run on web / Android / iOS          |
| `dart run magic:magic <cmd>`            | Magic CLI (no global install)       |

## Architecture

```
lib/
├── main.dart              # Magic.init() + configFactories, then runApp(MagicApplication())
├── app/
│   ├── controllers/       # MagicController + MagicStateMixin<T> (grouped by domain)
│   ├── enums/             # Backed enums (MonitorStatus, IncidentSeverity, MetricType, SignalSource, AiTrigger, ...)
│   ├── events/ listeners/ # Broadcast/app event plumbing
│   ├── helpers/           # Pure functions, no IO
│   ├── middleware/        # MagicMiddleware (EnsureAuthenticated, RedirectIfAuthenticated)
│   ├── models/            # Eloquent-style models (mock/ = design-only fixtures)
│   ├── policies/          # Gate policies
│   ├── providers/         # ServiceProvider — register (sync) vs boot (async)
│   ├── requests/          # FormRequest subclasses (prepared + rules)
│   └── kernel.dart        # Named middleware registry
├── config/                # app, auth, network, routing, wind, magic_starter, ... (configFactories consume these)
├── database/              # migrations/, factories/, seeders/
├── resources/views/       # Screens grouped by domain; views/components/ = reusable widgets
└── routes/app.dart        # MagicRoute.page() / .group() / .layout()
assets/lang/en.json        # trans('section.key') strings
```

## Stack Decisions

- **State**: `ChangeNotifier` + `MagicStateMixin<T>`. No Riverpod/Bloc/GetX.
- **HTTP**: `Http` facade → uptizm-api. Never raw Dio.
- **Routing**: `MagicRoute.page()` / `.group()`. Never raw GoRouter.
- **Feedback/nav**: `MagicRoute.to()`, `Magic.snackbar()`, `Magic.toast()`, `Magic.dialog()`, `Magic.confirm()`. Never
  `BuildContext` for feedback or nav.
- **UI**: Wind UI W-prefix + `className`. Every color token (`bg-` / `text-` / `border-`) needs a `dark:` pair.
  Conditional styling via `states` + prefixed classes, not string interpolation. Multi-line `className` via triple
  quotes, one concern per line.
- **i18n**: `trans('section.key')` from `assets/lang/en.json`. No hardcoded user-facing strings.

## Project Patterns (match the nearest neighbor before writing new code)

**Controller** — `class X extends MagicController with MagicStateMixin<T>, ValidatesRequests`. Singleton via
`static X get instance => Magic.findOrPut(X.new);`. State lives in `rxState`. Optimistic mutations: snapshot `previous`,
restore with `setState(previous, status: rxStatus, notify: false)` on failure. Surface 422s with
`handleApiError(response, fallback: trans('...'))`. List loads use `fetchList(url, X.fromMap)`; polling uses a separate
`reload()` that skips `setLoading()`.

**Request** — `class StoreXRequest extends FormRequest { const StoreXRequest(); }`. `prepared()` trims strings,
collapses enums to `.name`, drops blank optional fields (absent ≠ empty). `rules()` returns the validation map.
Controllers never build payloads inline — expose a typed `submitCreate({...})` that calls
`const StoreXRequest().validate({...})` behind an `isSubmitting` guard.

**View** — `MagicView<T>` for display. Forms: `MagicStatefulView<T>` + `MagicStatefulViewState<T, V>`, owning a
`MagicFormData` disposed in `onClose()`. Feedback/nav via the facades above, never `context`.

**Model** — `extends Model with HasTimestamps, InteractsWithPersistence`. Declare `table`, `resource`, `incrementing`,
`fillable`, `casts` (enums → `EnumCast(MyEnum.values)`). Factory:
`static fromMap(map) => X()..fill(map)..syncOriginal()..exists = map.containsKey('id');`. Typed access via
`getAttribute('key') as T?` — never raw maps.

**Enum** — backed enums for every status/type/source. Snake_case wire values go through an explicit `switch` mapper (see
`MetricSource`, `SignalSource`).

## Testing

- `setUp()` must call `MagicApp.reset()` + `Magic.flush()`.
- Fakes: `Http.fake([...])` + `Auth.fake()`. No mockito. Mock via contract inheritance if needed.
- Controller injection: `Magic.put<T>(controller)`.
- Wind UI layouts: `tester.view.physicalSize = const Size(1440, 900); addTearDown(tester.view.resetPhysicalSize);`.
- Tree mirrors `lib/` — one test file per controller/model/helper/view.

## Gotchas

- `.env` is a Flutter asset (`pubspec.yaml`), not a `--dart-define`.
- `Auth.manager.setUserFactory()` belongs in provider `boot()`, not `register()`.
- Use `configFactories` (not `configs`) whenever a config value reads `Env.get()` — `configs` evaluates before env
  loads.
- `BroadcastServiceProvider` / `EncryptionServiceProvider` / `LaunchServiceProvider` are NOT auto-registered.
- `routerConfig` only resolves after `Magic.init()` completes.
- Web SQLite is in-memory; mobile/desktop is file-backed. Don't rely on local persistence for cross-platform caches.
- Contract changes cross repos — keep `../uptizm-api` in sync.

## fluttersdk Dev-Tooling (debug-only)

Four vendored packages under `references/fluttersdk_*` + `references/magic_tinker` give an LLM agent eyes-and-hands over the running app. MCP server now ships INSIDE `fluttersdk_artisan` (no separate `fluttersdk_mcp` package; renamed from that). Single binary `dart run fluttersdk_artisan:mcp` serves stdio JSON-RPC. 11 V1 tools surfaced from registered providers. Filter via `.artisan/mcp.json` + env vars + CLI flags. Replaces the V3 ai-test monolith.

Stack:
- `fluttersdk_artisan` — pure Dart CLI framework (start/stop/status/logs/restart/doctor/list/help/make:command builtins + ArtisanServiceProvider abstraction + VmServiceClient + StateFile) + integrated MCP server (`dart run fluttersdk_artisan:mcp`, stdio JSON-RPC, 11 V1 tools).
- `fluttersdk_dusk` — E2E driver (gesture/snap/screenshot/wait/find/modal) over `ext.dusk.*` VM Service extensions.
- `fluttersdk_telescope` — runtime inspector (HTTP + log + exception + Magic Model + Magic Cache watchers) over `ext.telescope.*`.
- `magic_tinker` — connected REPL over `ext.tinker.evaluate` (VM Service evaluate); Magic-aware autocomplete via MagicTinkerIntegration.

Magic-side glue lives in `references/magic/lib/src/cli/`:
- `MagicArtisanProvider` — 16 make:* + magic:install + key:generate commands.
- `MagicDuskIntegration` — MagicForm field + MagicRoute location enrichers.
- `MagicTelescopeIntegration` — Magic.Http facade adapter + Model lifecycle + Cache watchers.
- `MagicTinkerIntegration` — 31 Magic facade autocomplete symbols + Eloquent model caster.

Wind-side: `WindDuskIntegration` enriches Dusk snapshots with W-widget resolved className metadata (6 fields: breakpoint, brightness, platform, states, bgColor, textColor).

All install() gates live under `kDebugMode` at `lib/main.dart`; release builds tree-shake the entire branch on every platform (dart2js for web, dart2native for desktop + mobile AOT).

Launch (consumer-side `bin/artisan.dart`):

```bash
dart run artisan start                  # web (chrome, default)
dart run artisan start --device=macos   # desktop
dart run artisan status                 # JSON status of recorded process
dart run artisan stop                   # SIGTERM + state.json delete
dart run artisan list                   # all registered commands (9 builtin + per-provider)
dart run artisan dusk:snap              # capture Semantics YAML snapshot
dart run artisan telescope:tail         # live HTTP/log feed
dart run artisan tinker                 # connected REPL
```

MCP server (for LLM agent tool access):

```bash
dart run fluttersdk_artisan:mcp         # stdio JSON-RPC; 11 V1 tools from registered providers
```

Configure tool visibility via `.artisan/mcp.json`, env vars, or CLI flags passed to the command above.

State inspection pattern (Magic-stack apps): `tinker_eval("Magic.find<MonitorController>().rxState.value.toString()")` via MCP. Form data lives in the snapshot YAML's `magicFormField:` enrichment.

Plugin source: `references/fluttersdk_artisan/` (Dart CLI framework + MCP server), `references/fluttersdk_dusk/` (E2E), `references/fluttersdk_telescope/` (inspector), `references/magic_tinker/` (REPL). Adapter glue: `references/magic/lib/src/cli/` + `references/wind/lib/src/dusk_integration.dart`.

Provider wiring: `lib/config/artisan.dart` exposes `artisanProviders` (9 factories); `bin/artisan.dart` registers builtins + expands the providers list into ArtisanRegistry (fail-fast on collision).

## Skills

| Skill             | Coverage                                                  |
|-------------------|-----------------------------------------------------------|
| `magic-framework` | Facades, ORM, providers, controllers, routing, testing    |
| `wind-ui`         | W-components, className tokens, states, responsive, theme |
| `e2e-testing`     | E2E testing for Flutter for LLM agents                    |

Defer to the skills for full APIs, templates, and anti-patterns.
