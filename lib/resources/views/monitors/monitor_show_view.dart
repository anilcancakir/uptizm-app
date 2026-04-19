import 'dart:async';

import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/ai/ai_settings_controller.dart';
import '../../../app/controllers/metrics/monitor_metric_controller.dart';
import '../../../app/controllers/monitors/monitor_check_controller.dart';
import '../../../app/controllers/monitors/monitor_controller.dart';
import '../../../app/controllers/monitors/monitor_series_controller.dart';
import '../../../app/controllers/monitors/monitor_summary_controller.dart';
import '../../../app/models/monitor_check.dart';
import '../../../app/models/response_time_sample.dart';
import '../../../app/enums/ai_mode.dart';
import '../../../app/enums/monitor_status.dart';
import '../components/common/app_back_button.dart';
import '../components/common/app_tab_bar.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/secondary_button.dart';
import '../components/monitors/monitor_ai_mode_card.dart';
import '../components/monitors/overview_stat_sheet.dart';
import '../components/monitors/response_sparkline.dart';
import '../components/monitors/stat_card.dart';
import '../components/monitors/status_badge.dart';
import '../components/monitors/time_range_tabs.dart';
import 'monitor_checks_tab.dart';
import 'monitor_incidents_tab.dart';
import 'monitor_metrics_tab.dart';

/// Monitor detail screen.
///
/// Single column on mobile, 2-column (5/7 split) on `lg+` screens.
class MonitorShowView extends MagicStatefulView<MonitorController> {
  const MonitorShowView({super.key, this.monitorId});

  final String? monitorId;

  @override
  State<MonitorShowView> createState() => _MonitorShowViewState();
}

class _MonitorShowViewState
    extends MagicStatefulViewState<MonitorController, MonitorShowView>
    with WidgetsBindingObserver {
  TimeRange _range = TimeRange.d7;
  int _tab = 0;
  bool _showWelcome = false;
  bool _welcomeChecked = false;
  bool _initialTabApplied = false;

  bool _liveMode = true;
  Timer? _pollTimer;
  int? _pollingIntervalSeconds;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final id = widget.monitorId;
    if (id == null) return;
    controller.addListener(_syncPolling);
    // Stagger loads so the scaffold paints before the dependent
    // controllers cascade their setSuccess() updates.
    Future.microtask(() async {
      await controller.load(id);
      if (!mounted) return;
      _syncPolling();
      final rangeParam = _rangeParam(_range);
      MonitorCheckController.instance.load(id);
      MonitorSummaryController.instance.load(id, range: rangeParam);
      MonitorSeriesController.instance.load(id, range: rangeParam);
      if (AiSettingsController.instance.settings == null) {
        AiSettingsController.instance.load();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_liveMode) return;
        unawaited(_pollTick());
        _syncPolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        _pollTimer = null;
        _pollingIntervalSeconds = null;
    }
  }

  static String _rangeParam(TimeRange range) => switch (range) {
    TimeRange.h24 => '24h',
    TimeRange.d7 => '7d',
    TimeRange.d30 => '30d',
    TimeRange.d90 => '90d',
  };

  void _onRangeChanged(TimeRange next) {
    if (next == _range) return;
    setState(() => _range = next);
    final id = widget.monitorId;
    if (id == null) return;
    final rangeParam = _rangeParam(next);
    MonitorSummaryController.instance.load(id, range: rangeParam);
    MonitorSeriesController.instance.load(id, range: rangeParam);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_syncPolling);
    _pollTimer?.cancel();
    _pollTimer = null;
    super.onClose();
  }

  /// Align the poll timer with the monitor's current `check_interval`.
  /// Called after every controller notification so an interval change made
  /// via the edit sheet retargets the next tick without a manual restart.
  void _syncPolling() {
    final id = widget.monitorId;
    if (id == null) return;
    final interval = controller.monitor?.checkInterval;
    if (!_liveMode || interval == null) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _pollingIntervalSeconds = null;
      return;
    }
    if (_pollTimer != null && _pollingIntervalSeconds == interval) return;
    _pollTimer?.cancel();
    _pollingIntervalSeconds = interval;
    _pollTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => _pollTick(),
    );
  }

  Future<void> _pollTick() async {
    final id = widget.monitorId;
    if (id == null || !_liveMode) return;
    await controller.reload(id);
    // Metrics tab lives behind the same monitor; keep its rxState fresh so
    // the Metrics tab picks up new samples without the user having to
    // re-enter the screen.
    final metrics = MonitorMetricController.instance;
    if (metrics.currentMonitorId == id) {
      await metrics.reload(id);
      // Refresh the batch-loaded sparkline samples too, so band strips in
      // the Metrics tab stay in sync with incoming probe data during live
      // mode without firing one XHR per metric card.
      await metrics.loadSeries(id);
    }
    final checks = MonitorCheckController.instance;
    if (checks.currentMonitorId == id) {
      await checks.reload(id);
    }
    final summary = MonitorSummaryController.instance;
    if (summary.currentMonitorId == id) {
      await summary.reload();
    }
    final series = MonitorSeriesController.instance;
    if (series.currentMonitorId == id) {
      await series.reload();
    }
  }

  void _toggleLive() {
    setState(() => _liveMode = !_liveMode);
    if (_liveMode) {
      _syncPolling();
      unawaited(_pollTick());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
      _pollingIntervalSeconds = null;
    }
  }

  static const _tabs = [
    AppTabItem(
      labelKey: 'monitor.tab.overview',
      icon: Icons.space_dashboard_rounded,
    ),
    AppTabItem(labelKey: 'monitor.tab.metrics', icon: Icons.analytics_rounded),
    AppTabItem(labelKey: 'monitor.tab.checks', icon: Icons.history_rounded),
    AppTabItem(
      labelKey: 'monitor.tab.incidents',
      icon: Icons.report_problem_rounded,
    ),
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
        if (controller.rxStatus.isError && controller.monitor == null)
          ErrorBanner(
            message: controller.rxStatus.message,
            onRetry: () {
              final id = widget.monitorId;
              if (id != null) controller.load(id);
            },
          ),
        _buildHeroMeta(),
        WBreakpoint(
          base: (_) => AppTabBar(
            items: _tabs,
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
            scrollable: true,
          ),
          lg: (_) => AppTabBar(
            items: _tabs,
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
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
      1 => MonitorMetricsTab(monitorId: widget.monitorId ?? ''),
      2 => MonitorChecksTab(monitorId: widget.monitorId ?? ''),
      3 => MonitorIncidentsTab(monitorId: widget.monitorId ?? ''),
      _ => _buildOverview(),
    };
  }

  Widget _buildOverview() {
    return WBreakpoint(
      base: (_) => WDiv(
        className: 'flex flex-col gap-6',
        children: [
          _buildStatsGrid(),
          _buildPerformanceCard(),
          _buildUptimeCard(),
          _buildAiModeCard(),
          _buildChecksCard(),
        ],
      ),
      lg: (_) => WDiv(
        className: 'flex flex-row gap-6',
        children: [
          WDiv(
            className: 'flex-1 flex flex-col gap-6 min-w-0',
            children: [
              _buildStatsGrid(),
              _buildPerformanceCard(),
              _buildUptimeCard(),
            ],
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-6 min-w-0',
            children: [_buildAiModeCard(), _buildChecksCard()],
          ),
        ],
      ),
    );
  }

  Widget _buildAiModeCard() {
    final id = widget.monitorId;
    if (id == null || id.isEmpty) {
      return const SizedBox.shrink();
    }
    final settings = AiSettingsController.instance.settings;
    final workspaceDefault = settings?.aiMode ?? AiMode.suggest;
    final rawOverride = controller.monitor?.getAttribute('ai_mode') as String?;
    final initial = rawOverride == null
        ? null
        : AiMode.values.firstWhere(
            (m) => m.name == rawOverride,
            orElse: () => workspaceDefault,
          );
    final monitor = controller.monitor;
    return MonitorAiModeCard(
      workspaceDefault: workspaceDefault,
      initialOverride: initial,
      aiStatus: monitor?.aiStatus,
      incidentThreshold: monitor?.getAttribute('incident_threshold') as int?,
      onChanged: (mode) => _onAiModeChanged(id, mode),
    );
  }

  Future<void> _onAiModeChanged(String id, AiMode? mode) async {
    final target = mode ?? AiSettingsController.instance.settings?.aiMode;
    if (target == null) return;
    await controller.updateAiMode(id, target);
  }

  Widget _buildHeader() {
    final id = widget.monitorId ?? 'sample';
    final monitor = controller.monitor;
    final title = monitor?.name ?? trans('monitor.show.loading');
    final subtitle = monitor?.url ?? '';
    final status =
        monitor?.lastStatus ?? monitor?.status ?? MonitorStatus.paused;
    return MagicStarterPageHeader(
      leading: const AppBackButton(fallbackPath: '/monitors'),
      title: title,
      subtitle: subtitle,
      actions: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(status: status),
            _buildLiveToggle(),
            SecondaryButton(
              labelKey: 'monitor.edit.action',
              icon: Icons.edit_rounded,
              onTap: () => MagicRoute.to('/monitors/$id/edit'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveToggle() {
    final interval = controller.monitor?.checkInterval;
    final tooltip = _liveMode && interval != null
        ? trans('monitor.live.on_hint', {'seconds': interval.toString()})
        : trans('monitor.live.off_hint');
    return Tooltip(
      message: tooltip,
      child: WButton(
        onTap: _toggleLive,
        states: _liveMode ? {'live'} : {},
        className: '''
          h-9 px-3 rounded-lg
          flex flex-row items-center gap-2
          border border-gray-200 dark:border-gray-700
          bg-white dark:bg-gray-800
          hover:bg-gray-50 dark:hover:bg-gray-700
          live:border-up-300 dark:live:border-up-700
          live:bg-up-50 dark:live:bg-up-900/30
        ''',
        child: WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WDiv(
              states: _liveMode ? {'live'} : {},
              className: '''
                w-2 h-2 rounded-full
                bg-gray-400 dark:bg-gray-500
                live:bg-up-500 dark:live:bg-up-400
              ''',
            ),
            WText(
              trans(_liveMode ? 'monitor.live.on' : 'monitor.live.off'),
              states: _liveMode ? {'live'} : {},
              className: '''
                text-xs font-semibold
                text-gray-600 dark:text-gray-300
                live:text-up-700 dark:live:text-up-300
              ''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMeta() {
    final cells = <Widget>[
      _metaCell(
        icon: Icons.bolt_rounded,
        labelKey: 'monitor.stats.meta.response',
        value: _formatResponseMs(controller.monitor?.lastResponseMs),
      ),
      _metaCell(
        icon: Icons.repeat_rounded,
        labelKey: 'monitor.stats.meta.interval',
        value: _formatInterval(controller.monitor?.checkInterval),
      ),
      _metaCell(
        icon: Icons.schedule_rounded,
        labelKey: 'monitor.stats.meta.last_check',
        value: _formatRelative(controller.monitor?.lastCheckedAt),
      ),
      _metaCell(
        icon: Icons.public_rounded,
        labelKey: 'monitor.stats.meta.regions',
        value: '${controller.monitor?.regions.length ?? 0}',
      ),
    ];
    return WDiv(
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-4
        sm:flex-row sm:gap-8
      ''',
      children: [for (final c in cells) WDiv(className: 'sm:flex-1', child: c)],
    );
  }

  String _formatInterval(int? seconds) {
    if (seconds == null) return '—';
    if (seconds < 60) return '${seconds}s';
    if (seconds % 60 == 0) return '${seconds ~/ 60}m';
    return '${seconds}s';
  }

  String _formatResponseMs(int? ms) {
    if (ms == null) return '—';
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  String _formatRelative(DateTime? at) {
    if (at == null) return '—';
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 10) return trans('time.just_now');
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
    final summaryController = MonitorSummaryController.instance;
    return AnimatedBuilder(
      animation: summaryController,
      builder: (_, _) {
        final summary = summaryController.summary;
        final uptime = summary == null
            ? '—'
            : '${(summary.uptimeRatio * 100).toStringAsFixed(1)}%';
        final avg = _formatResponseMs(summary?.avgResponseMs);
        final incidents = summary == null
            ? '—'
            : summary.incidentCount.toString();
        final mttr = _formatMttr(summary?.mttrSeconds);

        final uptimeTrend = _deltaPercentPoints(
          summary?.uptimeRatio,
          summary?.previousUptimeRatio,
        );
        final avgTrend = _deltaPercent(
          summary?.avgResponseMs?.toDouble(),
          summary?.previousAvgResponseMs?.toDouble(),
        );
        final incidentsTrend = _deltaPercent(
          summary?.incidentCount.toDouble(),
          summary?.previousIncidentCount.toDouble(),
        );
        final mttrTrend = _deltaPercent(
          summary?.mttrSeconds?.toDouble(),
          summary?.previousMttrSeconds?.toDouble(),
        );

        return WDiv(
          className: 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3',
          children: [
            StatCard(
              label: trans('monitor.stats.uptime'),
              value: uptime,
              icon: Icons.arrow_upward_rounded,
              trend: uptimeTrend?.label,
              trendPositive: uptimeTrend?.good ?? true,
              onTap: () => OverviewStatSheet.show(
                context,
                variant: OverviewStatVariant.uptime,
              ),
            ),
            StatCard(
              label: trans('monitor.stats.avg_response'),
              value: avg,
              icon: Icons.speed_rounded,
              trend: avgTrend?.label,
              trendPositive: avgTrend?.good ?? true,
              onTap: () => OverviewStatSheet.show(
                context,
                variant: OverviewStatVariant.response,
              ),
            ),
            StatCard(
              label: trans('monitor.stats.incidents'),
              value: incidents,
              icon: Icons.report_problem_rounded,
              trend: incidentsTrend?.label,
              trendPositive: incidentsTrend?.good ?? true,
            ),
            StatCard(
              label: trans('monitor.stats.mttr'),
              value: mttr,
              icon: Icons.healing_rounded,
              trend: mttrTrend?.label,
              trendPositive: mttrTrend?.good ?? true,
            ),
          ],
        );
      },
    );
  }

  /// Percent-point delta for ratio fields (uptime). Higher is better.
  _StatDelta? _deltaPercentPoints(double? current, double? previous) {
    if (current == null || previous == null) return null;
    final diff = (current - previous) * 100;
    if (diff.abs() < 0.01) return const _StatDelta(label: '0.0pp', good: true);
    final sign = diff >= 0 ? '+' : '';
    return _StatDelta(
      label: '$sign${diff.toStringAsFixed(2)}pp',
      good: diff > 0,
    );
  }

  /// Percent delta for count / duration fields. Lower is better.
  _StatDelta? _deltaPercent(double? current, double? previous) {
    if (current == null || previous == null) return null;
    if (previous == 0) {
      if (current == 0) return const _StatDelta(label: '0%', good: true);
      // No meaningful percentage vs. zero baseline; hide the chip.
      return null;
    }
    final pct = ((current - previous) / previous.abs()) * 100;
    if (pct.abs() < 0.1) return const _StatDelta(label: '0%', good: true);
    final sign = pct >= 0 ? '+' : '';
    return _StatDelta(label: '$sign${pct.toStringAsFixed(1)}%', good: pct < 0);
  }

  String _formatMttr(int? seconds) {
    if (seconds == null) return '—';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }

  Widget _buildUptimeCard() {
    final seriesController = MonitorSeriesController.instance;
    return _section(
      titleKey: 'monitor.section.uptime',
      icon: Icons.timeline_rounded,
      padded: true,
      child: AnimatedBuilder(
        animation: seriesController,
        builder: (_, _) {
          final samples = seriesController.samples;
          if (samples.isEmpty) {
            return EmptyState(
              icon: Icons.timeline_rounded,
              titleKey: 'monitor.show.empty.uptime_title',
              subtitleKey: 'monitor.show.empty.uptime_subtitle',
              variant: 'plain',
            );
          }
          return _uptimeStrip(samples);
        },
      ),
    );
  }

  Widget _uptimeStrip(List<ResponseTimeSample> samples) {
    // Downsample into ~60 equal segments so each bar gets enough pixel
    // width to render; rendering N=2000 flex-1 children collapses every
    // segment to sub-pixel width and the strip disappears.
    const segmentCount = 60;
    final buckets = <MonitorStatus>[];
    if (samples.isEmpty) return const SizedBox.shrink();
    if (samples.length <= segmentCount) {
      for (final s in samples) {
        buckets.add(s.status);
      }
    } else {
      final step = samples.length / segmentCount;
      for (var i = 0; i < segmentCount; i++) {
        final start = (i * step).floor();
        final end = ((i + 1) * step).floor().clamp(start + 1, samples.length);
        var worst = MonitorStatus.up;
        for (var j = start; j < end; j++) {
          final s = samples[j].status;
          if (s == MonitorStatus.down) {
            worst = MonitorStatus.down;
            break;
          }
          if (s == MonitorStatus.degraded) worst = MonitorStatus.degraded;
        }
        buckets.add(worst);
      }
    }
    return WDiv(
      className: 'flex flex-row gap-0.5 h-8 items-stretch',
      children: [
        for (final status in buckets)
          WDiv(
            states: {status.name},
            className: '''
              flex-1 rounded-sm
              bg-gray-300 dark:bg-gray-700
              up:bg-up-500 dark:up:bg-up-400
              down:bg-down-500 dark:down:bg-down-400
              degraded:bg-degraded-500 dark:degraded:bg-degraded-400
              paused:bg-paused-400 dark:paused:bg-paused-500
            ''',
          ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    final seriesController = MonitorSeriesController.instance;
    return _section(
      titleKey: 'monitor.section.performance',
      icon: Icons.show_chart_rounded,
      padded: true,
      trailing: TimeRangeTabs(selected: _range, onChanged: _onRangeChanged),
      child: AnimatedBuilder(
        animation: seriesController,
        builder: (_, _) {
          final samples = seriesController.samples;
          if (samples.isEmpty) {
            return EmptyState(
              icon: Icons.show_chart_rounded,
              titleKey: 'monitor.show.empty.performance_title',
              subtitleKey: 'monitor.show.empty.performance_subtitle',
              variant: 'plain',
            );
          }
          return RepaintBoundary(
            child: ResponseSparkline(
              samples: [
                for (final s in samples)
                  ResponseSample(
                    timestamp: s.checkedAt,
                    responseMs: s.responseMs,
                    status: s.status,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChecksCard() {
    final checksController = MonitorCheckController.instance;
    return _section(
      titleKey: 'monitor.section.recent_checks',
      icon: Icons.history_rounded,
      padded: false,
      child: AnimatedBuilder(
        animation: checksController,
        builder: (_, _) {
          final checks = checksController.checks.take(6).toList();
          if (checks.isEmpty) {
            return EmptyState(
              icon: Icons.history_rounded,
              titleKey: 'monitor.show.empty.checks_title',
              subtitleKey: 'monitor.show.empty.checks_subtitle',
              variant: 'plain',
            );
          }
          return WDiv(
            className:
                'flex flex-col divide-y divide-gray-100 dark:divide-gray-800',
            children: [for (final check in checks) _checkRow(check)],
          );
        },
      ),
    );
  }

  Widget _checkRow(MonitorCheck check) {
    final status = check.status ?? MonitorStatus.paused;
    final code = check.statusCode?.toString() ?? '—';
    final ms = _formatResponseMs(check.responseMs);
    final when = _formatRelative(check.checkedAt);
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
        px-4 py-3
      ''',
      children: [
        StatusBadge(status: status),
        WDiv(
          className: 'flex-1 min-w-0 flex flex-col gap-0.5',
          children: [
            WText(
              '$code · $ms',
              className:
                  'text-sm font-semibold text-gray-900 dark:text-gray-100 truncate',
            ),
            WText(
              check.region ?? '—',
              className: 'text-xs text-gray-500 dark:text-gray-400 truncate',
            ),
          ],
        ),
        WText(when, className: 'text-xs text-gray-500 dark:text-gray-400'),
      ],
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
            WIcon(icon, className: 'text-sm text-gray-500 dark:text-gray-400'),
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
        WDiv(className: padded ? 'p-4' : '', child: child),
      ],
    );
  }
}

class _StatDelta {
  const _StatDelta({required this.label, required this.good});

  final String label;
  final bool good;
}
