import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../resources/views/dashboard_view.dart';
import '../resources/views/monitors/monitor_create_view.dart';
import '../resources/views/monitors/monitor_edit_view.dart';
import '../resources/views/monitors/monitor_list_view.dart';
import '../resources/views/monitors/monitor_show_view.dart';
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

      MagicRoute.page('/monitors', () => const MonitorListView());
      MagicRoute.page('/monitors/create', () => const MonitorCreateView());
      MagicRoute.page(
        '/monitors/sample',
        () => const MonitorShowView(monitorId: 'sample'),
      );
      MagicRoute.page(
        '/monitors/sample/edit',
        () => const MonitorEditView(monitorId: 'sample'),
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
