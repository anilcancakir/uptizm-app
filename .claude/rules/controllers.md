---
path: "lib/app/controllers/**/*.dart"
description: "Magic controller shape — optimistic mutations, load/reload split, resource builders"
---

# Controllers

- Resource controllers mix in `ResourceController` and override `index() / show(id) / create() / edit(id)` returning the view widget — the router calls these directly (wired via `MagicRoute.resource`).
- Single-entity load: `await fetchOne('/resource/$id', X.fromMap);` after `clearErrors()`. List load: prefer `fetchList('/resource', X.fromMap)` for `rxState`; use a separate `ValueNotifier` triad (`list`, `listLoading`, `listError`) only when the list must coexist with a single-entity `rxState`.
- `fetchList` expects the envelope `{"data": [...]}`; `fetchOne` expects `{"data": {...}}`. Pass `dataKey: 'items'` when the API envelope differs. Both auto-flip to empty status when the list is `[]` or the key is missing.
- `Http` resource helpers for anything outside fetch helpers: `Http.index('/x')`, `.show('/x', id)`, `.store('/x', data)`, `.update('/x', id, data)`, `.destroy('/x', id)`. Compose URLs by hand only for non-RESTful endpoints.
- Polling uses a separate `reload(id)` that calls `HttpCache.get()` and skips `setLoading()` — on failure, return silently so the UI never flickers into error/empty.
- Optimistic mutations: capture `final previous = rxState;` before the request, and on EVERY failure branch (non-200, null data, caught exception) call `setState(previous, status: rxStatus, notify: false);` before returning — never leave `rxState` half-updated. `notify: false` is also the only safe form inside `initState` or any code path that may run during build.
- Error surfacing order inside mutations: `handleApiError(response, fallback: trans('...'))` for non-2xx — it auto-parses a 422 payload into `validationErrors` AND flips the mixin's status, so never touch `response.errors` by hand. Then `setError(trans('errors.unexpected'))` inside the catch block after `Log.error('[Class.method] $e\n$stackTrace')`.
- Concurrent-submit guards are plain bools (`_isSubmitting`, `_isDeleting`) exposed via getters; wrap the mutation body in `try { ... } finally { _isSubmitting = false; refreshUI(); }` and call `refreshUI()` after flipping to true.
- Destroy never prompts — the caller must `Magic.confirm()` first. Controllers only execute.
- Never build request payloads inline: delegate to a `FormRequest` (`const StoreXRequest().validate(...)`) or a dedicated service (`MonitorFormService.buildPayload`).
- `Http` facade only — never raw Dio, never `package:http`. Log unexpected exceptions with the `[Controller.method]` prefix before swallowing.
