import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../app/controllers/monitors/monitor_controller.dart';
import '../resources/views/dashboard_view.dart';
import '../resources/views/settings/settings_ai_activity_view.dart';
import '../resources/views/settings/settings_ai_view.dart';
import '../resources/views/settings/settings_appearance_view.dart';
import '../resources/views/settings/settings_hub_view.dart';
import '../resources/views/settings/settings_metrics_library_view.dart';
import '../resources/views/status_pages/status_page_create_view.dart';
import '../resources/views/status_pages/status_page_list_view.dart';
import '../resources/views/status_pages/status_page_show_view.dart';

/// Application Route Definitions.
///
/// Four top-level destinations: Dashboard, Monitors, Status Pages, Settings.
void registerAppRoutes() {
  MagicRoute.group(
    layout: (child) => MagicStarter.view.makeLayout('layout.app', child: child),
    middleware: ['auth'],
    layoutId: 'app',
    routes: () {
      MagicRoute.page('/', () => const DashboardView());

      MagicRoute.page('/monitors', () => MonitorController.instance.index());
      MagicRoute.page(
        '/monitors/create',
        () => MonitorController.instance.create(),
      );
      MagicRoute.page(
        '/monitors/:id/edit',
        (id) => MonitorController.instance.edit(id),
      );
      MagicRoute.page(
        '/monitors/:id',
        (id) => MonitorController.instance.show(id),
      );

      MagicRoute.page('/status-pages', () => const StatusPageListView());
      MagicRoute.page(
        '/status-pages/create',
        () => const StatusPageCreateView(),
      );
      MagicRoute.page(
        '/status-pages/sample',
        () => const StatusPageShowView(statusPageId: 'sample'),
      );

      MagicRoute.page('/settings', () => const SettingsHubView());
      MagicRoute.page('/settings/ai', () => const SettingsAiView());
      MagicRoute.page(
        '/settings/ai/activity',
        () => const SettingsAiActivityView(),
      );
      MagicRoute.page(
        '/settings/metrics-library',
        () => const SettingsMetricsLibraryView(),
      );
      MagicRoute.page(
        '/settings/appearance',
        () => const SettingsAppearanceView(),
      );
    },
  );
}
