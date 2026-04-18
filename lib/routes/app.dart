import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../app/controllers/ai/ai_agent_run_controller.dart';
import '../app/controllers/ai/ai_settings_controller.dart';
import '../app/controllers/dashboard/dashboard_controller.dart';
import '../app/controllers/metrics/metrics_library_controller.dart';
import '../app/controllers/monitors/monitor_controller.dart';
import '../app/controllers/settings/appearance_controller.dart';
import '../app/controllers/settings/settings_controller.dart';
import '../app/controllers/status_pages/status_pages_controller.dart';

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

      // Settings hub + sub-screens. Grouped so the `/settings` prefix is
      // declared once and child URLs read as relative paths.
      MagicRoute.group(
        prefix: '/settings',
        routes: () {
          MagicRoute.page('/', () => SettingsController.instance.index());
          MagicRoute.page('/ai', () => AiSettingsController.instance.index());
          MagicRoute.page(
            '/ai/activity',
            () => AiAgentRunController.instance.index(),
          );
          MagicRoute.page(
            '/metrics-library',
            () => MetricsLibraryController.instance.index(),
          );
          MagicRoute.page(
            '/appearance',
            () => AppearanceController.instance.index(),
          );
        },
      );
    },
  );
}
