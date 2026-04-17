import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import 'components/dashboard/recent_incidents_section.dart';

/// Dashboard view: Uptizm authenticated landing page.
///
/// Shows the account-wide uptime snapshot: five status counters and a
/// monitors list placeholder. Numbers wire up to the API in a later pass.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          title: trans('dashboard.title'),
          subtitle: trans('dashboard.subtitle'),
          inlineActions: true,
        ),
        _buildStatsGrid(),
        const RecentIncidentsSection(),
        _buildMonitorsEmpty(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return WDiv(
      className: 'grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3',
      children: [
        _statCard(
          icon: Icons.dns_outlined,
          labelKey: 'dashboard.stats.total',
          value: '0',
          tone: 'total',
        ),
        _statCard(
          icon: Icons.check_circle_outline,
          labelKey: 'dashboard.stats.up',
          value: '0',
          tone: 'up',
        ),
        _statCard(
          icon: Icons.highlight_off,
          labelKey: 'dashboard.stats.down',
          value: '0',
          tone: 'down',
        ),
        _statCard(
          icon: Icons.warning_amber_outlined,
          labelKey: 'dashboard.stats.degraded',
          value: '0',
          tone: 'degraded',
        ),
        _statCard(
          icon: Icons.pause_circle_outline,
          labelKey: 'dashboard.stats.paused',
          value: '0',
          tone: 'paused',
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String labelKey,
    required String value,
    required String tone,
  }) {
    return WDiv(
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-3
      ''',
      children: [
        WDiv(
          states: {tone},
          className: '''
            w-9 h-9 rounded-lg
            flex items-center justify-center
            total:bg-primary-50 total:text-primary-600
            dark:total:bg-primary-900/20 dark:total:text-primary-400
            up:bg-up-50 up:text-up-600
            dark:up:bg-up-900/20 dark:up:text-up-400
            down:bg-down-50 down:text-down-600
            dark:down:bg-down-900/20 dark:down:text-down-400
            degraded:bg-degraded-50 degraded:text-degraded-600
            dark:degraded:bg-degraded-900/20 dark:degraded:text-degraded-400
            paused:bg-paused-100 paused:text-paused-600
            dark:paused:bg-paused-800/40 dark:paused:text-paused-300
          ''',
          child: WIcon(icon, className: 'text-lg'),
        ),
        WText(
          value,
          className: '''
            text-2xl font-bold
            text-gray-900 dark:text-white
          ''',
        ),
        WText(
          trans(labelKey),
          className: 'text-xs text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _buildMonitorsEmpty() {
    return WDiv(
      className: '''
        w-full rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        p-8 flex flex-col items-center text-center gap-3
      ''',
      children: [
        WDiv(
          className: '''
            w-12 h-12 rounded-full
            bg-paused-100 dark:bg-paused-800/40
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.monitor_heart_outlined,
            className: 'text-xl text-paused-500 dark:text-paused-300',
          ),
        ),
        WText(
          trans('dashboard.monitors.empty_title'),
          className: '''
            text-base font-semibold
            text-gray-900 dark:text-white
          ''',
        ),
        WText(
          trans('dashboard.monitors.empty_subtitle'),
          className: 'text-sm text-gray-500 dark:text-gray-400 max-w-md',
        ),
        WButton(
          onTap: () => MagicRoute.to('/monitors/create'),
          className: '''
            mt-2 px-4 py-3 rounded-lg
            bg-primary hover:bg-primary-700
            dark:bg-primary-500 dark:hover:bg-primary-400
          ''',
          child: WText(
            trans('dashboard.monitors.add_first'),
            className: 'text-sm font-semibold text-white dark:text-white',
          ),
        ),
      ],
    );
  }
}
