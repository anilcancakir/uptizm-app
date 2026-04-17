# CLAUDE.md

## Mission

Uptizm — website monitoring service (up/down status + custom metrics) across web, Android, and iOS.
Built on **magic** + **magic_starter** framework (Laravel-inspired Flutter architecture) + **wind** (Tailwind-for-Flutter design system).

## Flutter SDK Packages (In-House)

| Package                            | Source Path                |
|------------------------------------|----------------------------|
| **Magic** (core framework)         | `references/magic`         |
| **Magic Starter** (app scaffold)   | `references/magic_starter` |
| **Wind UI** (Tailwind-for-Flutter) | `references/wind`          |

- **Read-only**: Research source locally for debugging and understanding internals
- **STRICT: NEVER fix bugs or make changes directly.** File a GitHub issue → the project's LLM agent handles implementation

## Commands

| Command | Description |
|---------|-------------|
| `flutter test` | Run all tests |
| `dart format lib/ test/` | Format code |
| `dart analyze` | Static analysis (zero warnings) |
| `flutter run -d chrome` | Run on web |
| `flutter run -d <device>` | Run on Android/iOS |
| `dart run magic:magic <command>` | Magic CLI |

## Architecture

```
lib/
├── main.dart              # Magic.init() + configFactories + runApp(MagicApplication())
├── app/
│   ├── controllers/       # Magic controllers (one per domain action)
│   ├── enums/             # MonitorStatus, IncidentSeverity, MetricType, SignalSource, AiTrigger, ...
│   ├── events/            # Broadcast/app events
│   ├── helpers/           # Pure-function utilities (no IO)
│   ├── listeners/         # Event listeners
│   ├── middleware/        # MagicMiddleware subclasses (auth guards, etc.)
│   ├── models/            # user.dart, team.dart; mock/ holds design-mock models (Monitor, Incident, ...)
│   ├── policies/          # Authorization gates
│   ├── providers/         # ServiceProvider (register = sync bindings, boot = async)
│   └── kernel.dart        # Kernel.registerAll() named middleware
├── config/                # app, auth, broadcasting, cache, database, logging, magic_starter, network, routing, view, wind
├── database/
│   ├── factories/         # Model factories for tests/seeds
│   ├── migrations/        # Schema migrations
│   └── seeders/           # Seed data
├── resources/
│   └── views/
│       ├── dashboard_view.dart
│       ├── monitors/      # Full-screen monitor pages (list, show, edit, tabs)
│       ├── settings/      # Settings pages (ai, metrics library, appearance, ...)
│       ├── status_pages/  # Status page management screens
│       └── components/    # Reusable widgets grouped by domain
│           ├── ai/        # ai_avatar, ai_mode_selector, ...
│           ├── common/    # app_tab_bar, segmented_choice, color_swatch, ...
│           ├── dashboard/ # recent_incidents_section, ...
│           ├── incidents/ # incident_create_sheet, incident_timeline, ...
│           ├── monitors/  # response_sparkline, check_detail_sheet, metric_*, ...
│           ├── settings/
│           └── status_pages/  # status_page_card, logo_upload_zone, color_chip_grid, ...
├── routes/app.dart        # MagicRoute.page() / .group() / .layout()
assets/
└── lang/en.json           # trans('key') i18n strings
```

Backend API lives in sibling repo `../uptizm-api`.

## Key Decisions

- **State**: `ChangeNotifier` + `MagicStateMixin` (no Riverpod/Bloc/GetX)
- **HTTP**: `Http` facade against uptizm-api (never raw Dio)
- **Routing**: `MagicRoute.page()` / `.group()` (never raw GoRouter)
- **UI**: Wind UI W-prefix + `className` for all layout/styling. Every `bg-`/`text-`/`border-` needs a `dark:` pair. Conditional styling via `states` param + prefixed classes, never string interpolation. Multi-line `className` via triple quotes, one concern per line.
- **Feedback/nav**: `MagicRoute.to()`, `Magic.snackbar()`, `Magic.toast()` (never BuildContext)
- **i18n**: `trans('section.key')` from `assets/lang/en.json` (never hardcoded strings)
- **Platforms**: web, Android, iOS (design responsive from the start)
- **TDD**: red-green-refactor, no exceptions. Write a failing test first, make it pass with minimum code, then refactor. Every new controller, model, helper, and view ships with tests.

## Skills

| Skill | Coverage |
|-------|----------|
| `magic-framework` | Facades, ORM, providers, controllers, routing, testing |
| `wind-ui` | W-components, className tokens, states, responsive, theme |

Via `fluttersdk` CC plugin. Full API refs + templates + anti-patterns. Defer to skills for details.

## Testing

- `setUp()`: `MagicApp.reset()` + `Magic.flush()`
- Mock via contract inheritance (no mockito)
- `Magic.put<T>(controller)` for controller injection
- Wind UI layouts: `tester.view.physicalSize = const Size(1440, 900); addTearDown(tester.view.resetPhysicalSize)`

## Gotchas

- `.env` = Flutter asset (`pubspec.yaml`), not dart-define
- `Auth.manager.setUserFactory()` in provider `boot()`, not `register()`
- `configFactories` (not `configs`) when values need `Env.get()`
- `BroadcastServiceProvider`/`EncryptionServiceProvider`/`LaunchServiceProvider` NOT auto-registered
- `routerConfig` only after `Magic.init()` completes
- Web SQLite = in-memory; mobile/desktop = file-based — don't rely on local persistence for cross-platform caches
- Backend API is in `../uptizm-api` — coordinate contract changes across both repos
