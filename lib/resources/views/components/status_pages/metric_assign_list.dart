import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/controllers/metrics/monitor_metric_controller.dart';
import '../../../../app/models/monitor.dart';
import '../../../../app/models/monitor_metric.dart';

/// Lists the custom metrics of each attached monitor so the operator can
/// pin them to a status page. Triggers a lazy per-monitor metric fetch
/// when [monitorIds] changes; already-loaded sets are cached in memory.
class MetricAssignList extends StatefulWidget {
  const MetricAssignList({
    super.key,
    required this.monitors,
    required this.monitorIds,
    required this.selected,
    required this.onToggle,
  });

  final List<Monitor> monitors;
  final Set<String> monitorIds;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  State<MetricAssignList> createState() => _MetricAssignListState();
}

class _MetricAssignListState extends State<MetricAssignList> {
  final Map<String, List<MonitorMetric>> _byMonitor = {};
  final Set<String> _loading = {};

  MonitorMetricController get _metrics => MonitorMetricController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLoads());
  }

  @override
  void didUpdateWidget(covariant MetricAssignList old) {
    super.didUpdateWidget(old);
    _syncLoads();
  }

  Future<void> _syncLoads() async {
    for (final id in widget.monitorIds) {
      if (_byMonitor.containsKey(id) || _loading.contains(id)) continue;
      _loading.add(id);
      final response = await Http.get('/monitors/$id/metrics');
      if (!mounted) return;
      _loading.remove(id);
      if (!response.successful) {
        setState(() => _byMonitor[id] = const []);
        continue;
      }
      final raw = response.data?['data'];
      final list = raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(MonitorMetric.fromMap)
                .toList()
          : <MonitorMetric>[];
      setState(() => _byMonitor[id] = list);
    }
    // Purge caches for monitors no longer selected so the next selection
    // forces a fresh fetch (metric list may have changed meanwhile).
    _byMonitor.removeWhere((k, _) => !widget.monitorIds.contains(k));
    // Ignore the controller itself - we talk to HTTP directly to avoid
    // stomping the monitor-metrics tab's rxState.
    _metrics.currentMonitorId;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monitorIds.isEmpty) {
      return WDiv(
        className: '''
          rounded-lg p-4
          bg-white dark:bg-gray-800
          border border-gray-200 dark:border-gray-700
        ''',
        child: WText(
          trans('status_page.create.metrics_section.empty_monitors'),
          className: '''
            text-sm
            text-gray-500 dark:text-gray-400
          ''',
        ),
      );
    }
    final byMonitor = {for (final m in widget.monitors) m.id: m};
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        for (final id in widget.monitorIds)
          _monitorBlock(byMonitor[id], id, _byMonitor[id]),
      ],
    );
  }

  Widget _monitorBlock(
    Monitor? monitor,
    String monitorId,
    List<MonitorMetric>? metrics,
  ) {
    return WDiv(
      className: '''
        rounded-lg
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            px-4 py-2.5
            border-b border-gray-100 dark:border-gray-900/60
          ''',
          child: WText(
            monitor?.name ?? monitorId,
            className: '''
              text-xs font-bold uppercase tracking-wide
              text-gray-600 dark:text-gray-300
            ''',
          ),
        ),
        if (metrics == null)
          WDiv(
            className: 'px-4 py-3',
            child: WText(
              trans('status_page.create.metrics_section.loading'),
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          )
        else if (metrics.isEmpty)
          WDiv(
            className: 'px-4 py-3',
            child: WText(
              trans('status_page.create.metrics_section.empty_monitor'),
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          )
        else
          for (var i = 0; i < metrics.length; i++)
            _row(metrics[i], isLast: i == metrics.length - 1),
      ],
    );
  }

  Widget _row(MonitorMetric metric, {required bool isLast}) {
    final isChecked = widget.selected.contains(metric.id);
    return WButton(
      onTap: () => widget.onToggle(metric.id),
      states: {if (isChecked) 'checked', if (isLast) 'last'},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        checked:bg-primary-50/40 dark:checked:bg-primary-900/20
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: isChecked ? {'checked'} : {},
            className: '''
              w-5 h-5 rounded
              border-2
              border-gray-300 dark:border-gray-600
              checked:border-primary-500 dark:checked:border-primary-400
              checked:bg-primary-500 dark:checked:bg-primary-400
              flex items-center justify-center
            ''',
            child: isChecked
                ? WIcon(Icons.check_rounded, className: 'text-xs text-white')
                : const WDiv(className: 'w-0 h-0'),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                metric.label ?? metric.key ?? '',
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                  truncate
                ''',
              ),
              WText(
                metric.key ?? '',
                className: '''
                  text-xs font-mono
                  text-gray-500 dark:text-gray-400
                  truncate
                ''',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
