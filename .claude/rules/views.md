---
path: "lib/resources/views/**/*.dart"
description: "Wind UI className discipline and MagicView resolution"
---

- Resolve controllers via `controller` getter from `MagicView<T>` / `MagicStatefulView<T>` — never pass them through constructors, never call `Magic.find<T>()` inside `build`.
- Render controller state with `controller.renderState((state) => ..., onLoading: ..., onError: (msg) => ..., onEmpty: ...)`. When `T` is nullable, success+null falls through to `onEmpty` — always supply an explicit `onEmpty` for nullable states.
- `MagicStatefulViewState<T, V>`: own `MagicFormData` (or `TextEditingController`s) in the state class and dispose every one of them in `onClose()` — state leaks are silent.
- `MagicFormData` auto-infers field types: `String` initial → `TextEditingController` (reads auto-trim via `form.get('key')`), anything else → `ValueNotifier<T>` read as `form.value<bool>('key')` and written as `form.setValue('key', v)`. `form.data` returns the full map for API submission.
- Wrap async submits with `form.process(() => controller.submit(form.data))` — it flips `form.processingListenable` around the future. Bind the submit button's disabled state to that listenable instead of a local `isSubmitting` bool.
- Field validators: `validator: FormValidator.rules<String>([Required(), Email()], field: 'email', controller: controller)` wires a `TextFormField` validator that lets server-side errors from the controller win over the client rules.
- `className` is multi-line triple-quoted when it spans more than one concern. One concern per line (layout / sizing / color / border / state). Group `dark:` pairs beside their light variant, not at the bottom.
- Every `bg-*`, `text-*`, `border-*`, `fill-*`, `ring-*` token needs a matching `dark:` token in the same className block. Missing dark pair = bug.
- Conditional styling goes through the `states:` parameter plus prefixed classes (`hover:`, `active:`, `disabled:`, `selected:`). Never build className by string interpolation or ternary over token strings.
- Bottom sheets mirror `MetricDetailSheet` shape — fixed header, scrollable body via `Expanded` + `SingleChildScrollView`, action row pinned outside the scroll.
- `Row` with `items-stretch` inside a scroll needs `IntrinsicHeight` in the parent; unbounded flex-1 inside scroll throws at layout time.
- Feedback and navigation go through facades (`Magic.snackbar`, `Magic.toast`, `Magic.dialog`, `Magic.confirm`, `MagicRoute.to`) — never depend on `BuildContext` inside callbacks that may fire after unmount.
- User-facing strings always go through `trans('section.key')` — hardcoded English in widgets breaks locale switching and the i18n lint.
