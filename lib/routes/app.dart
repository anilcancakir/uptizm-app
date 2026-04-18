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

/// Application Route Definitions.
///
/// Four top-level destinations: Dashboard, Monitors, Status Pages, Settings.
/// Every route delegates to a resource controller so the controller stays
/// the single entry point per domain (Laravel-style).
void registerAppRoutes() {
  MagicRoute.group(
    layout: (child) => MagicStarter.view.makeLayout('layout.app', child: child),
    middleware: ['auth'],
    layoutId: 'app',
    routes: () {
      MagicRoute.page('/', () => DashboardController.instance.index());

      MagicRoute.resource('monitors', MonitorController.instance);
      MagicRoute.resource('status-pages', StatusPagesController.instance);

      MagicRoute.page('/settings', () => SettingsController.instance.hub());
      MagicRoute.page(
        '/settings/ai',
        () => AiSettingsController.instance.index(),
      );
      MagicRoute.page(
        '/settings/ai/activity',
        () => AiAgentRunController.instance.index(),
      );
      MagicRoute.page(
        '/settings/metrics-library',
        () => MetricsLibraryController.instance.index(),
      );
      MagicRoute.page(
        '/settings/appearance',
        () => AppearanceController.instance.index(),
      );
    },
  );
}
