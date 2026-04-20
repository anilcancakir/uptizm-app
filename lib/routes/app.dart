import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../app/controllers/ai/ai_agent_run_controller.dart';
import '../app/controllers/ai/ai_settings_controller.dart';
import '../app/controllers/dashboard/dashboard_controller.dart';
import '../app/controllers/metrics/metrics_library_controller.dart';
import '../app/controllers/monitors/monitor_controller.dart';
import '../app/controllers/settings/settings_controller.dart';
import '../app/controllers/status_pages/status_page_subscriber_controller.dart';
import '../app/controllers/status_pages/status_pages_controller.dart';
import '../resources/views/settings/settings_appearance_view.dart';
import '../resources/views/status_pages/status_page_subscribers_view.dart';

/// Application route definitions.
///
/// Every route is a controller-delegated entry point. Top-level domains with
/// CRUD shape (monitors, status-pages) use `MagicRoute.resource()`; flat
/// single-page routes delegate to the controller's `index()` method so the
/// controller remains the single source of truth per screen (Laravel-style).
void registerAppRoutes() {
  MagicRoute.group(
    layout: (child) => MagicStarter.view.makeLayout('layout.app', child: child),
    middleware: ['auth'],
    layoutId: 'app',
    routes: () {
      // Dashboard (root).
      MagicRoute.page('/', () => DashboardController.instance.index());

      // CRUD resources.
      MagicRoute.resource('monitors', MonitorController.instance);
      MagicRoute.resource('status-pages', StatusPagesController.instance);
      MagicRoute.page('/status-pages/:id/subscribers', (String id) {
        // Prime the singleton so MagicStatefulView can resolve it — no
        // other screen references this controller, so without eager
        // init the view throws "Controller not found".
        StatusPageSubscriberController.instance;
        return StatusPageSubscribersView(statusPageId: id);
      });

      // Settings hub + sub-screens. The hub sits at `/settings` directly;
      // child URLs share the `/settings` prefix via the nested group.
      MagicRoute.page('/settings', () => SettingsController.instance.index());
      MagicRoute.group(
        prefix: '/settings',
        routes: () {
          MagicRoute.page('/ai', () => AiSettingsController.instance.index());
          MagicRoute.page(
            '/ai/activity',
            () => AiAgentRunController.instance.index(),
          );
          MagicRoute.page(
            '/metrics-library',
            () => MetricsLibraryController.instance.index(),
          );
          MagicRoute.page('/appearance', () => const SettingsAppearanceView());
        },
      );
    },
  );
}
