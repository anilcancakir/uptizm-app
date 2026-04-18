---
path: "lib/**/*.dart"
description: "Magic framework — facade-first idioms and framework-wide APIs (routing, policies, events, broadcasting, cache, storage)"
---

# Magic Framework

Every import comes from the single barrel `package:magic/magic.dart` — it re-exports `dio`, `go_router`, `intl`, `jiffy`, `image_picker`, `flutter_secure_storage`, `shared_preferences`, `timezone`, `url_launcher`, `file_picker`. Never import those packages directly.

Facade-first for everything cross-cutting. Reach for these before writing raw Dio / Hive / `jsonDecode` / `launchUrl`:

- **Auth / Http / Cache / DB / Schema** — HTTP, query, migration. `Http` is the only network surface.
- **Echo / Event** — broadcast channels, in-app events.
- **Gate / Session** — authorization, short-lived flash/old form state.
- **Lang / Log** — i18n + structured logging (levels: `Log.info/warning/error/debug`).
- **Storage / Pick / Vault / Crypt / Launch / MagicRoute** — files, uploads, secure storage, encryption, url_launcher, routing.

## Routing

- `MagicRoute.page('/x/:id', () => View()).title('X')` — `.title()` is the supported fluent chain; the string flows into `MagicApplication.titleSuffix`.
- `MagicRoute.group(middleware: [...], routes: () { ... })` nests guarded routes. `MagicRoute.layout(builder, routes: () {...})` wraps children in a shell (sidebar, etc.).
- `MagicRoute.resource('/monitors', () => MonitorController.instance)` auto-wires `/monitors` → `index()`, `/monitors/create` → `create()`, `/monitors/:id` → `show(id)`, `/monitors/:id/edit` → `edit(id)`; the controller mixes in `ResourceController` and overrides those four widget builders.
- Navigation is context-free: `MagicRoute.to('/x')`, `.push('/x')`, `.back(fallback: '/')`, `.replace('/x')`, `.toNamed('x.show', params: {...})`. `MagicRoute.setTitle('...')` updates the browser tab imperatively; read `MagicRoute.currentTitle`.

## Authorization

- Define abilities in a policy class (`const MonitorPolicy()` → `register()`) called from `PolicyServiceProvider.boot()`. Under the hood each ability becomes `Gate.define('monitors.destroy', (user, monitor) => ...)`.
- Check with `Gate.allows('monitors.destroy', monitor)` / `Gate.denies(...)` / `Gate.allowsAny([...])` / `Gate.allowsAll([...])`. Never branch on `user.role` directly.
- Guard UI fragments with `<MagicCan ability="monitors.destroy" arguments={monitor} child: ...>` — it rebuilds on `AuthLoginSucceeded` / `AuthLogoutSucceeded` automatically.
- Inside controllers: `authorize('monitors.destroy', monitor)` throws `AuthorizationException` — let it bubble to the global error boundary instead of returning bool.

## Events & Broadcasting

- `Event.dispatch(MyEvent(...))` for app-internal side effects. Wire listeners in a provider's `boot()` via `Event.listen<MyEvent>(MyListener.new)`. Framework fires `AuthLoginSucceeded`, `AuthLogoutSucceeded`, `ModelCreated<T>`, `ModelSaved<T>`, `ModelDeleted<T>`, `AppBooted` — subscribe to those instead of hooking every controller.
- `Echo.private('monitors.$teamId').listen('.MonitorChecked', (payload) => ...)` for Reverb broadcasts. Use `Echo.presence(...)` for who's-online channels. `Echo.connectionState` is a `ValueListenable<BroadcastConnectionState>` — bind a status chip to it instead of polling.

## Cache, Session, Carbon

- `Cache.remember('key', ttl: Duration(minutes: 5), () => fetch())` memoizes futures. The repo's `HttpCache.get(url)` wraps this for GET polling — use it for background reloads, bypass (raw `Http.get`) for user-initiated refresh.
- `Session.flash('key', value)` survives exactly one navigation tick; `Session.old('field')` reads the last submitted form value after a validation round-trip. Prefer over stuffing maps through route extras.
- `Carbon.parse(iso).diffForHumans()` for every relative time string in the UI. `Carbon.now()` respects `Jiffy` locale; never call `DateTime.now()` for user-facing output.

## Files & Feedback

- `Pick.image(source: ImageSource.gallery)` / `Pick.file()` / `Pick.files()` return `MagicFile`; call `.save(disk: 'public')` to persist via `Storage`. Never touch `ImagePicker` / `FilePicker` directly.
- `Magic.confirm(title:, message:, confirmText:, cancelText:, isDangerous: true)` → `Future<bool>` with i18n defaults. Use it for every destructive action instead of hand-rolling `AlertDialog`.
- `Magic.loading(message: '...')` / `Magic.closeLoading()` guard a persistent overlay — pair them in `try/finally`. Read `Magic.isLoading` when you need to skip a duplicate call.
- `Magic.snackbar/success/error/toast/dialog` are the only feedback surfaces — context-free, safe to call from controllers, listeners, event handlers.
