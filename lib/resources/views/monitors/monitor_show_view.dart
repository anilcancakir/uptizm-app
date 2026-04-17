import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/enums/ai_mode.dart';
import '../../../app/enums/metric_type.dart';
import '../../../app/enums/monitor_status.dart';
import '../../../app/models/mock/monitor_metric.dart';
import '../components/common/app_back_button.dart';
import '../components/common/app_tab_bar.dart';
import '../components/common/secondary_button.dart';
import '../components/monitors/check_row.dart';
import '../components/monitors/metric_detail_sheet.dart';
import '../components/monitors/monitor_ai_mode_card.dart';
import '../components/monitors/response_sparkline.dart';
import '../components/monitors/stat_card.dart';
import '../components/monitors/status_badge.dart';
import '../components/monitors/time_range_tabs.dart';
import '../components/monitors/uptime_bar.dart';
import 'monitor_checks_tab.dart';
import 'monitor_incidents_tab.dart';
import 'monitor_metrics_tab.dart';

/// Monitor detail screen.
///
/// Single column on mobile, 2-column (5/7 split) on `lg+` screens. Data is
/// hardcoded mock for design iteration until the API contract lands.
class MonitorShowView extends StatefulWidget {
  const MonitorShowView({super.key, this.monitorId});

  final String? monitorId;

  @override
  State<MonitorShowView> createState() => _MonitorShowViewState();
}

class _MonitorShowViewState extends State<MonitorShowView> {
  TimeRange _range = TimeRange.d7;
  int _tab = 0;
  bool _showWelcome = false;
  bool _welcomeChecked = false;
  bool _initialTabApplied = false;

  static const _tabs = [
    AppTabItem(labelKey: 'monitor.tab.overview', icon: Icons.space_dashboard_rounded),
    AppTabItem(labelKey: 'monitor.tab.metrics', icon: Icons.analytics_rounded),
    AppTabItem(labelKey: 'monitor.tab.checks', icon: Icons.history_rounded),
    AppTabItem(labelKey: 'monitor.tab.incidents', icon: Icons.report_problem_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_welcomeChecked) {
      _welcomeChecked = true;
      final state = GoRouterState.of(context);
      if (state.uri.queryParameters['welcome'] == '1') {
        _showWelcome = true;
      }
    }
    if (!_initialTabApplied) {
      _initialTabApplied = true;
      final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
      final mapped = switch (tabParam) {
        'metrics' => 1,
        'checks' => 2,
        'incidents' => 3,
        _ => null,
      };
      if (mapped != null) _tab = mapped;
    }
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        _buildHeader(),
        if (_showWelcome) _buildWelcomeBanner(),
        _buildHeroMeta(),
        AppTabBar(
          items: _tabs,
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
          scrollable: MediaQuery.of(context).size.width < 1024,
        ),
        _buildTabBody(),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return WDiv(
      className: '''
        rounded-xl p-4
        bg-primary-50 dark:bg-primary-900/30
        border border-primary-200 dark:border-primary-800
        flex flex-row items-start gap-3
      ''',
      children: [
        WDiv(
          className: '''
            w-10 h-10 rounded-lg
            bg-white dark:bg-primary-900/50
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.auto_graph_rounded,
            className: 'text-base text-primary-600 dark:text-primary-300',
          ),
        ),
        WDiv(
          className: 'flex-1 flex flex-col gap-2 min-w-0',
          children: [
            WText(
              trans('monitor.create.welcome.title'),
              className: '''
                text-sm font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('monitor.create.welcome.subtitle'),
              className: '''
                text-xs
                text-gray-600 dark:text-gray-300
              ''',
            ),
            WDiv(
              className: 'flex flex-row items-center gap-2 pt-1',
              children: [
                WButton(
                  onTap: () => setState(() {
                    _tab = 1;
                    _dismissWelcome();
                  }),
                  className: '''
                    px-3 py-1.5 rounded-lg
                    bg-primary-600 dark:bg-primary-500
                    hover:bg-primary-700 dark:hover:bg-primary-400
                    flex flex-row items-center gap-1.5
                  ''',
                  child: WDiv(
                    className: 'flex flex-row items-center gap-1.5',
                    children: [
                      WIcon(
                        Icons.arrow_forward_rounded,
                        className: 'text-xs text-white',
                      ),
                      WText(
                        trans('monitor.create.welcome.cta'),
                        className: 'text-xs font-semibold text-white',
                      ),
                    ],
                  ),
                ),
                WButton(
                  onTap: _dismissWelcome,
                  className: '''
                    px-3 py-1.5 rounded-lg
                    hover:bg-primary-100 dark:hover:bg-primary-900/50
                  ''',
                  child: WText(
                    trans('monitor.create.welcome.dismiss'),
                    className: '''
                      text-xs font-semibold
                      text-primary-700 dark:text-primary-300
                    ''',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _dismissWelcome() {
    setState(() => _showWelcome = false);
    GoRouter.of(context).go('/monitors/sample');
  }

  Widget _buildTabBody() {
    return switch (_tab) {
      1 => const MonitorMetricsTab(),
      2 => const MonitorChecksTab(),
      3 => const MonitorIncidentsTab(),
      _ => _buildOverview(),
    };
  }

  Widget _buildOverview() {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final leftChildren = <Widget>[
      _buildStatsGrid(),
      _buildPerformanceCard(),
      _buildUptimeCard(),
    ];
    final rightChildren = <Widget>[
      const MonitorAiModeCard(workspaceDefault: AiMode.suggest),
      _buildChecksCard(),
    ];
    if (isWide) {
      return WDiv(
        className: 'flex flex-row gap-6',
        children: [
          WDiv(
            className: 'flex-1 flex flex-col gap-6 min-w-0',
            children: leftChildren,
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-6 min-w-0',
            children: rightChildren,
          ),
        ],
      );
    }
    return WDiv(
      className: 'flex flex-col gap-6',
      children: [...leftChildren, ...rightChildren],
    );
  }

  Widget _buildHeader() {
    final id = widget.monitorId ?? 'sample';
    return MagicStarterPageHeader(
      leading: const AppBackButton(fallbackPath: '/monitors'),
      title: 'Production API',
      subtitle: 'https://api.example.com/health',
      inlineActions: true,
      actions: [
        const StatusBadge(status: MonitorStatus.up),
        SecondaryButton(
          labelKey: 'monitor.edit.action',
          icon: Icons.edit_rounded,
          onTap: () => MagicRoute.to('/monitors/$id/edit'),
        ),
      ],
    );
  }

  Widget _buildHeroMeta() {
    final isWide = MediaQuery.of(context).size.width >= 640;
    final cells = <Widget>[
      _metaCell(
        icon: Icons.bolt_rounded,
        labelKey: 'monitor.stats.meta.response',
        value: '245 ms',
      ),
      _metaCell(
        icon: Icons.repeat_rounded,
        labelKey: 'monitor.stats.meta.interval',
        value: '30 s',
      ),
      _metaCell(
        icon: Icons.schedule_rounded,
        labelKey: 'monitor.stats.meta.last_check',
        value: '2 m ago',
      ),
      _metaCell(
        icon: Icons.public_rounded,
        labelKey: 'monitor.stats.meta.regions',
        value: '4',
      ),
    ];
    return WDiv(
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        ${isWide ? 'flex flex-row gap-8' : 'flex flex-col gap-4'}
      ''',
      children: isWide
          ? [for (final c in cells) WDiv(className: 'flex-1', child: c)]
          : cells,
    );
  }

  Widget _metaCell({
    required IconData icon,
    required String labelKey,
    required String value,
  }) {
    return WDiv(
      className: 'flex flex-row items-center gap-3 w-full',
      children: [
        WDiv(
          className: '''
            w-9 h-9 rounded-lg
            bg-primary-50 dark:bg-primary-900/30
            flex items-center justify-center
          ''',
          child: WIcon(
            icon,
            className: 'text-base text-primary-600 dark:text-primary-400',
          ),
        ),
        WDiv(
          className: 'flex flex-col',
          children: [
            WText(
              trans(labelKey),
              className: '''
                text-xs font-semibold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
              ''',
            ),
            WText(
              value,
              className: '''
                text-base font-semibold
                text-gray-900 dark:text-white
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _mockBuiltInMetrics();
    return WDiv(
      className: 'grid grid-cols-2 gap-3',
      children: [
        for (final s in stats)
          StatCard(
            label: s.$1.label,
            value: s.$2,
            icon: s.$3,
            trend: s.$4,
            trendPositive: s.$5,
            onTap: () => MetricDetailSheet.show(context, s.$1),
          ),
      ],
    );
  }

  List<(MonitorMetric, String, IconData, String, bool)> _mockBuiltInMetrics() {
    return [
      (
        MonitorMetric(
          group: 'Built-in',
          label: trans('monitor.stats.uptime'),
          key: 'uptime',
          type: MetricType.numeric,
          unit: '%',
          numericValue: 99.95,
          trendLabel: '+0.02%',
          trendPositive: true,
          samples: const [
            99.8, 99.82, 99.85, 99.87, 99.9, 99.91, 99.92, 99.93,
            99.93, 99.94, 99.94, 99.94, 99.95, 99.95, 99.95, 99.95,
            99.95, 99.95, 99.95, 99.95,
          ],
        ),
        '99.95%',
        Icons.arrow_upward_rounded,
        '+0.02%',
        true,
      ),
      (
        MonitorMetric(
          group: 'Built-in',
          label: trans('monitor.stats.avg_response'),
          key: 'avg_response',
          type: MetricType.numeric,
          unit: 'ms',
          numericValue: 245,
          trendLabel: '-12 ms',
          trendPositive: true,
          samples: const [
            257, 260, 255, 258, 253, 250, 252, 248,
            249, 247, 246, 246, 245, 244, 245, 246,
            245, 245, 245, 245,
          ],
        ),
        '245 ms',
        Icons.speed_rounded,
        '-12 ms',
        true,
      ),
      (
        MonitorMetric(
          group: 'Built-in',
          label: trans('monitor.stats.incidents'),
          key: 'incidents',
          type: MetricType.numeric,
          numericValue: 2,
          trendLabel: '-1',
          trendPositive: true,
          samples: const [
            3, 3, 3, 3, 3, 3, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2,
          ],
        ),
        '2',
        Icons.report_problem_rounded,
        '-1',
        true,
      ),
      (
        MonitorMetric(
          group: 'Built-in',
          label: trans('monitor.stats.mttr'),
          key: 'mttr',
          type: MetricType.numeric,
          unit: 'm',
          numericValue: 4.2,
          trendLabel: '-1.1 m',
          trendPositive: true,
          samples: const [
            5.6, 5.4, 5.3, 5.2, 5.1, 5.0, 4.9, 4.8,
            4.7, 4.6, 4.5, 4.4, 4.3, 4.3, 4.2, 4.2,
            4.2, 4.2, 4.2, 4.2,
          ],
        ),
        '4.2 m',
        Icons.healing_rounded,
        '-1.1 m',
        true,
      ),
    ];
  }

  Widget _buildUptimeCard() {
    return _section(
      titleKey: 'monitor.section.uptime',
      icon: Icons.timeline_rounded,
      child: UptimeBar(
        days: _mockUptimeDays(),
        uptimePercent: 99.95,
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return _section(
      titleKey: 'monitor.section.performance',
      icon: Icons.show_chart_rounded,
      trailing: TimeRangeTabs(
        selected: _range,
        onChanged: (r) => setState(() => _range = r),
      ),
      child: ResponseSparkline(samples: _mockSamples()),
    );
  }

  Widget _buildChecksCard() {
    return _section(
      titleKey: 'monitor.section.recent_checks',
      icon: Icons.history_rounded,
      padded: false,
      child: WDiv(
        className: 'flex flex-col',
        children: _mockChecks(),
      ),
    );
  }

  Widget _section({
    required String titleKey,
    required IconData icon,
    required Widget child,
    Widget? trailing,
    bool padded = true,
  }) {
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            flex flex-row items-center gap-2
            px-4 py-3
            border-b border-gray-100 dark:border-gray-800
          ''',
          children: [
            WIcon(
              icon,
              className: 'text-sm text-gray-500 dark:text-gray-400',
            ),
            WText(
              trans(titleKey),
              className: '''
                flex-1 truncate
                text-xs font-bold uppercase tracking-wider
                text-gray-500 dark:text-gray-400
              ''',
            ),
            ?trailing,
          ],
        ),
        WDiv(
          className: padded ? 'p-4' : '',
          child: child,
        ),
      ],
    );
  }

  List<UptimeDay> _mockUptimeDays() {
    final now = DateTime.now();
    return List.generate(30, (i) {
      final MonitorStatus s;
      if (i == 14) {
        s = MonitorStatus.down;
      } else if (i == 15 || i == 20) {
        s = MonitorStatus.degraded;
      } else {
        s = MonitorStatus.up;
      }
      return UptimeDay(
        date: now.subtract(Duration(days: 29 - i)),
        status: s,
      );
    });
  }

  List<ResponseSample> _mockSamples() {
    final now = DateTime.now();
    const values = [
      245, 312, 198, 267, 1245, 356, 289, 234,
      278, 301, 245, 267, 223, 198, 312, 289,
      256, 234, 278, 245,
    ];
    return [
      for (var i = 0; i < values.length; i++)
        ResponseSample(
          timestamp: now.subtract(Duration(minutes: (values.length - i) * 3)),
          responseMs: values[i],
          status: values[i] > 1000
              ? MonitorStatus.degraded
              : MonitorStatus.up,
        ),
    ];
  }

  List<Widget> _mockChecks() {
    final now = DateTime.now();
    return [
      CheckRow(
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 245,
        region: 'eu-west-1',
        checkedAt: now.subtract(const Duration(minutes: 2)),
      ),
      CheckRow(
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 312,
        region: 'us-east-1',
        checkedAt: now.subtract(const Duration(minutes: 5)),
      ),
      CheckRow(
        status: MonitorStatus.degraded,
        statusCode: 200,
        responseMs: 1245,
        region: 'ap-southeast-1',
        checkedAt: now.subtract(const Duration(minutes: 8)),
      ),
      CheckRow(
        status: MonitorStatus.down,
        statusCode: 500,
        errorMessage: 'Connection timeout after 30s',
        region: 'eu-central-1',
        checkedAt: now.subtract(const Duration(minutes: 11)),
      ),
      CheckRow(
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 198,
        region: 'eu-central-1',
        checkedAt: now.subtract(const Duration(minutes: 14)),
      ),
    ];
  }
}
