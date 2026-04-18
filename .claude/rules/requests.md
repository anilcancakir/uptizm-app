---
path: "lib/app/requests/**/*.dart"
description: "FormRequest shape — prepared normalization + rules map"
---

# Form Requests

- Class shape: `class StoreXRequest extends FormRequest { const StoreXRequest(); }`. Always a `const` constructor — callers instantiate as `const StoreXRequest().validate({...})`.
- `prepared(Map<String, dynamic> data)` is a pure transform: copy into `final next = Map<String, dynamic>.from(data);`, never mutate the incoming map, no IO, no `trans()` lookups.
- Normalize in this order inside `prepared`: (1) collapse enum instances to wire via `.name`, (2) trim required strings (falling back to `''` so `Required()` fires), (3) trim optional strings and `next.remove(key)` when blank so absent and empty never both reach the server.
- Snake_case keys match the backend Laravel request (`monitor_id`, `metric_key`). Do not camelCase here — `prepared` runs before the HTTP layer.
- `rules()` returns `Map<String, List<Rule>>`. Use `Required()`, `Max(N)`, `Min(N)`, `InList<E>(E.values)` for enums. Empty list (`[]`) documents that a key is accepted but unvalidated — keep it instead of omitting.
- Add numbered `// 1. / 2. / 3.` step comments inside `prepared` when it does three or more distinct normalizations (per my-coding Rule 10).
- The controller wrapper (`submitCreate`, `submitUpdate`) owns the `isSubmitting` flag and the `Magic.snackbar` feedback — requests only validate and return the validated map.
