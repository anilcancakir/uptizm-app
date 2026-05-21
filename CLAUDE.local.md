# uptizm-app local context (not checked in scope by default)

## Plan: artisan-install-command-magic (2026-05-20)

Migration completed across 3 repos: substrate `consumer:scaffold` rename to `install`, magic delegation refactor, uptizm-app scaffold swap. See `.ac/plans/artisan-install-command-magic/report.md` for the full execution log + Phase 3 review findings + post-deliver follow-up fixes.

### Step 22 deviation (post-deliver: now mostly moot)

uptizm-app's Wave 3 scaffolding used `dart run fluttersdk_artisan install --force` (substrate direct path) instead of the plan's prescribed `dart run magic:artisan magic:install --preserve`. Reason at the time: pre-existing magic baseline brokenness (`InstallStubs.appConfigContent` routed through global `StubLoader` instead of `installContext.stubs`) blocked every `magic:install` invocation with a `FileSystemException`.

Magic baseline was subsequently fixed in `references/magic/` commit chain (R4 follow-up — install_stubs.dart now takes a `StubDriver` parameter; 39 pre-existing failures dropped to 0). `dart run magic:artisan magic:install --preserve` now works on fresh consumers.

For uptizm-app specifically: the magic-specific extras (conditional configs, dynamic `lib/config/app.dart` provider list, `lib/main.dart` smart-merge, sqlite3.wasm download) were NOT applied during the migration. The existing `lib/main.dart` + `lib/config/app.dart` + sqlite3.wasm setup were already correctly customized for this app's Sentry + Dusk + Telescope wiring. Future contributors running `magic:install --preserve` after fresh-cloning should expect the smart-merger to attempt to inject Magic.init + provider list into `lib/main.dart`; review the diff before accepting. The customizations are intentional.

### Canonical commands post-migration

```bash
./bin/fsa <cmd>                     # primary entry (110ms warm AOT; falls through to dart build cli on staleness)
dart run fluttersdk_artisan <cmd>   # substrate fallback (~3s startup)
dart run magic:artisan <cmd>        # magic-stack fallback (~3s startup + magic providers)
```

Examples: `./bin/fsa list` shows 60 commands (22 substrate + 29 dusk + 9 telescope). MCP server at `./bin/fsa mcp:serve` (wired via `.mcp.json`).

### Maintenance

- After `dart pub upgrade` or pubspec edits, `./bin/fsa` auto-rebuilds the AOT bundle on next invocation (4-condition staleness check).
- If `./bin/fsa` deadlocks with `fsa: waiting for another fsa invocation to finish...`, the post-deliver lock-staleness fix (PID-aware reclaim) should handle it. If it doesn't, `rm -rf .artisan/.fsa.lock` + retry.
- After `plugin:install <name>`, the codegen barrel at `lib/app/_plugins.g.dart` is regenerated; force-rebuild via `rm -rf .artisan/cli-bundle .artisan/build.stamp && ./bin/fsa list` if the AOT was compiled before the barrel update.

## Plan: wind-dusk-decouple (2026-05-21)

### Wave 5: wind alpha-10 migration

`WindDuskIntegration.install()` is removed in wind 1.0.0-alpha.10. The replacement call in `lib/main.dart` is `Wind.installDebugResolver()`. Import path: main barrel only (`package:fluttersdk_wind/fluttersdk_wind.dart`); no sub-barrel import required.

**New transitive dep: `fluttersdk_wind_diagnostics_contracts`**

Both `wind` (prod dep) and `fluttersdk_dusk` (prod dep) now depend on `fluttersdk_wind_diagnostics_contracts: ^1.0.0-alpha.1`. This package is automatically transitive through both paths. The outer `pubspec.yaml` carries an explicit `dependency_overrides: path: references/fluttersdk_wind_diagnostics_contracts` while the upstream GitHub repository does not yet exist; the local path override makes `pub get` succeed without a published package.

```yaml
# pubspec.yaml (outer uptizm-app)
dependency_overrides:
  fluttersdk_wind_diagnostics_contracts:
    path: references/fluttersdk_wind_diagnostics_contracts
```

**`.gitmodules` entry deferred:** The `.gitmodules` git-submodule entry for `fluttersdk_wind_diagnostics_contracts` is intentionally omitted until the upstream `fluttersdk/fluttersdk_wind_diagnostics_contracts` GitHub repository is created and published. Until then the local `path:` override in `dependency_overrides` is the only mechanism. Do not add a submodule entry for a repo that does not exist yet.
