import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/controllers/metrics/monitor_metric_controller.dart';
import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/monitor_metric.dart';
import '../../../../app/models/monitor_metric_value.dart';
import 'metric_form_sheet.dart';
import 'metric_overflow_menu.dart';
import 'metric_sparkline.dart';

/// Bottom sheet presenting a drill-down view for a single metric.
///
/// Shows the definition (label, key, unit, extraction path, thresholds)
/// plus a 24h history fetched from
/// `MonitorMetricController.series(...)`. Numeric metrics render a
/// sparkline; status / string metrics render a band strip with the
/// most recent samples listed below.
class MetricDetailSheet extends StatefulWidget {
  const MetricDetailSheet({
    super.key,
    required this.monitorId,
    required this.metric,
  });

  final String monitorId;
  final MonitorMetric metric;

  static Future<void> show(
    BuildContext context, {
    required String monitorId,
    required MonitorMetric metric,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MetricDetailSheet(monitorId: monitorId, metric: metric),
    );
  }

  @override
  State<MetricDetailSheet> createState() => _MetricDetailSheetState();
}

class _MetricDetailSheetState extends State<MetricDetailSheet> {
  bool _loading = true;
  List<MonitorMetricValue> _samples = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.metric.id;
    if (id.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final samples = await MonitorMetricController.instance.series(
      widget.monitorId,
      id,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _samples = samples;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return WDiv(
          className: '''
            rounded-t-2xl
            bg-white dark:bg-gray-900
            border-t border-gray-200 dark:border-gray-700
            flex flex-col h-full
          ''',
          children: [
            _grabber(),
            _header(context),
            WDiv(
              className:
                  'flex-1 overflow-y-auto p-4 lg:p-6 flex flex-col gap-3',
              scrollPrimary: true,
              children: [
                _row('Key', widget.metric.key ?? '—'),
                _row('Unit', widget.metric.unit ?? '—'),
                _row('Extraction', widget.metric.extractionPath ?? '—'),
                _row('Warn', widget.metric.warnBound?.toString() ?? '—'),
                _row(
                  'Critical',
                  widget.metric.criticalBound?.toString() ?? '—',
                ),
                WDiv(className: 'h-2'),
                _seriesSection(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _seriesSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_samples.isEmpty) {
      return WText(
        trans('monitor.metric_detail.series_placeholder'),
        className: 'text-xs text-gray-500 dark:text-gray-400',
      );
    }
    return switch (widget.metric.type) {
      MetricType.numeric => _numericSeries(),
      MetricType.status => _bandStrip(),
      MetricType.string => _stringList(),
      null => const SizedBox.shrink(),
    };
  }

  Widget _numericSeries() {
    // series returns newest-first; reverse so the sparkline reads
    // left-to-right chronologically.
    final values = [
      for (final s in _samples.reversed)
        if (s.numericValue != null) s.numericValue!,
    ];
    if (values.isEmpty) return _emptyPlaceholder();
    final latest = _samples.first;
    final tone = latest.band?.toneKey ?? 'up';
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        _latestLine(tone: tone),
        WDiv(
          className: 'h-32',
          child: MetricSparkline(samples: values, toneKey: tone),
        ),
      ],
    );
  }

  Widget _bandStrip() {
    final ordered = _samples.reversed.toList();
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        _latestLine(tone: _samples.first.band?.toneKey ?? 'up'),
        WDiv(
          className: 'flex flex-row gap-0.5 h-6 items-stretch',
          children: [
            for (final s in ordered)
              WDiv(
                states: {s.band?.name ?? 'ok'},
                className: '''
                  flex-1 rounded-sm
                  bg-gray-300 dark:bg-gray-700
                  ok:bg-up-500 dark:ok:bg-up-400
                  warn:bg-degraded-500 dark:warn:bg-degraded-400
                  critical:bg-down-500 dark:critical:bg-down-400
                ''',
              ),
          ],
        ),
      ],
    );
  }

  Widget _stringList() {
    final recent = _samples.take(8).toList();
    return WDiv(
      className: '''
        flex flex-col
        divide-y divide-gray-100 dark:divide-gray-800
      ''',
      children: [for (final s in recent) _stringRow(s)],
    );
  }

  Widget _stringRow(MonitorMetricValue sample) {
    return WDiv(
      className: 'flex flex-row items-center gap-3 py-2',
      children: [
        WText(
          sample.stringValue ?? '—',
          className: '''
            flex-1 min-w-0 truncate
            text-sm font-mono
            text-gray-800 dark:text-gray-200
          ''',
        ),
        WText(
          _relative(sample.recordedAt),
          className: 'text-[10px] text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _latestLine({required String tone}) {
    final latest = _samples.first;
    final valueText = switch (widget.metric.type) {
      MetricType.numeric =>
        latest.numericValue == null ? '—' : _fmtNumber(latest.numericValue!),
      MetricType.status => latest.statusValue?.toUpperCase() ?? '—',
      MetricType.string => latest.stringValue ?? '—',
      null => '—',
    };
    return WDiv(
      className: 'flex flex-row items-baseline gap-2',
      children: [
        WText(
          valueText,
          states: {tone},
          className: '''
            text-2xl font-bold font-mono
            text-gray-900 dark:text-white
            up:text-up-600 dark:up:text-up-400
            degraded:text-degraded-600 dark:degraded:text-degraded-400
            down:text-down-600 dark:down:text-down-400
          ''',
        ),
        if (widget.metric.unit != null)
          WText(
            widget.metric.unit!,
            className: 'text-xs text-gray-500 dark:text-gray-400',
          ),
        WDiv(className: 'flex-1'),
        WText(
          _relative(latest.recordedAt),
          className: 'text-[10px] text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _emptyPlaceholder() {
    return WText(
      trans('monitor.metric_detail.series_placeholder'),
      className: 'text-xs text-gray-500 dark:text-gray-400',
    );
  }

  String _fmtNumber(double v) {
    if (v % 1 == 0) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  String _relative(DateTime? at) {
    if (at == null) return '—';
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 10) return trans('time.just_now');
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _grabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: '''
          w-10 h-1 rounded-full
          bg-gray-300 dark:bg-gray-700
        ''',
      ),
    );
  }

  Widget _header(BuildContext context) {
    return WDiv(
      className: '''
        px-4 lg:px-6 pb-3
        flex flex-row items-start gap-3
        border-b border-gray-200 dark:border-gray-800
      ''',
      children: [
        WDiv(
          className: 'flex-1 flex flex-col gap-1 min-w-0',
          children: [
            WText(
              widget.metric.label ?? widget.metric.key ?? '—',
              className: '''
                text-lg font-bold
                text-gray-900 dark:text-white truncate
              ''',
            ),
            WText(
              widget.metric.groupName ?? '—',
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          ],
        ),
        MetricOverflowMenu(
          onEdit: () {
            MagicRoute.back();
            final id = widget.metric.id;
            if (id.isEmpty) return;
            MetricFormSheet.show(
              context,
              mode: 'edit',
              monitorId: widget.monitorId,
              metricId: id,
              existingGroups: const [],
              initial: MetricFormInitial(
                label: widget.metric.label ?? '',
                key: widget.metric.key ?? '',
                group: widget.metric.groupName ?? '',
                path: widget.metric.extractionPath ?? '',
                unit: widget.metric.unit ?? '',
                unitKind: widget.metric.unitKind,
              ),
            );
          },
          onDuplicate: () {},
          onDelete: () => _confirmDelete(context),
        ),
        WButton(
          onTap: () => MagicRoute.back(),
          className: '''
            w-9 h-9 rounded-lg
            bg-gray-100 dark:bg-gray-800
            hover:bg-gray-200 dark:hover:bg-gray-700
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.close_rounded,
            className: 'text-base text-gray-600 dark:text-gray-300',
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final id = widget.metric.id;
    if (id.isEmpty) return;
    final confirmed = await Magic.confirm(
      title: trans('monitor.metric_form.delete_confirm_title'),
      message: trans('monitor.metric_form.delete_confirm_message'),
      confirmText: trans('monitor.metric_form.delete_confirm_confirm'),
      cancelText: trans('monitor.metric_form.cancel'),
      isDangerous: true,
    );
    if (!confirmed) return;
    final ok = await MonitorMetricController.instance.destroy(
      widget.monitorId,
      id,
    );
    if (!ok) {
      Magic.error(
        trans('monitor.metric_form.toast_invalid'),
        trans('metric.errors.generic_delete'),
      );
      return;
    }
    MagicRoute.back();
    Magic.toast(trans('monitor.metric_form.toast_deleted'));
  }

  Widget _row(String label, String value) {
    return WDiv(
      className: '''
        flex flex-row items-center justify-between gap-3
        py-2 border-b border-gray-100 dark:border-gray-800
      ''',
      children: [
        WText(
          label,
          className: '''
            text-xs font-semibold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WText(
          value,
          className: '''
            text-sm font-mono
            text-gray-800 dark:text-gray-200 truncate
          ''',
        ),
      ],
    );
  }
}
