---
path: "test/**/*_test.dart"
description: "Magic test harness — reset hooks, facade fakes, widget sizing"
---

- Every file starts with `setUp(() { MagicApp.reset(); Magic.flush(); });` — skipping it leaks singletons into the next test.
- Stub network with `Http.fake([HttpFake.get('/monitors', body: {...})])` — assert calls via the returned fake's `assertSent(...)`. Never use mockito.
- Auth state: `Auth.fake(user: User.fromMap({...}))` for authenticated tests, bare `Auth.fake()` for guest. Call before the controller is constructed — `MagicStateMixin` reads during init.
- Inject controllers under test with `Magic.put<MonitorController>(controller)` before pumping the view; `MagicView` resolves via the container.
- Widget tests of Wind UI layouts must size the surface: `tester.view.physicalSize = const Size(1440, 900); tester.view.devicePixelRatio = 1.0; addTearDown(tester.view.resetPhysicalSize);` — the default 800x600 collapses multi-column layouts.
- Mirror the `lib/` tree: `lib/app/controllers/monitors/monitor_controller.dart` → `test/app/controllers/monitors/monitor_controller_test.dart`. One production file, one test file.
- Assert controller state against `controller.rxState` and `controller.rxStatus`, not render output — render assertions belong in view tests.
- FormRequest tests call `const StoreXRequest().validate({...})` directly and assert on the returned map or thrown `ValidationException` — do not spin up a controller.
- Pump after async: `await tester.pumpAndSettle();` after every awaited facade call that triggers `refreshUI()`, otherwise `find.byType` sees the pre-rebuild tree.
