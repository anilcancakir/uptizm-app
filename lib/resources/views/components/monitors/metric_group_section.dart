import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/controllers/metrics/monitor_metric_controller.dart';
import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/monitor_metric.dart';
import 'numeric_metric_card.dart';
import 'status_metric_card.dart';
import 'string_metric_row.dart';

/// Renders one user-defined metric group (e.g. Database, Queue, Cache).
///
/// Layout per group:
///  1. Group header: icon + title + count badge + reorder toggle
///  2. Status pill wrap row (if any status metrics)
///  3. Numeric cards grid (1 / 2 / 3 cols responsive)
///  4. String / duration row list (if any)
///
/// When the operator taps the reorder icon, the group flips to a single
/// column [ReorderableListView] of drag-handle rows for all non-string
/// metrics; Save PATCHes the new order via [MonitorMetricController.reorder].
class MetricGroupSection extends StatefulWidget {
  const MetricGroupSection({
    super.key,
    required this.monitorId,
    required this.group,
    required this.metrics,
    required this.icon,
    this.onMetricTap,
    this.onAddMetric,
  });

  final String monitorId;
  final String group;
  final List<MonitorMetric> metrics;
  final IconData icon;
  final ValueChanged<MonitorMetric>? onMetricTap;
  final VoidCallback? onAddMetric;

  @override
  State<MetricGroupSection> createState() => _MetricGroupSectionState();
}

class _MetricGroupSectionState extends State<MetricGroupSection> {
  bool _isReordering = false;
  bool _isSaving = false;
  late List<MonitorMetric> _draft;

  @override
  void initState() {
    super.initState();
    _draft = List<MonitorMetric>.from(widget.metrics);
  }

  @override
  void didUpdateWidget(covariant MetricGroupSection old) {
    super.didUpdateWidget(old);
    if (!_isReordering) {
      _draft = List<MonitorMetric>.from(widget.metrics);
    }
  }

  List<MonitorMetric> get _cards => widget.metrics
      .where((m) => m.type == MetricType.numeric || m.type == MetricType.status)
      .toList();

  List<MonitorMetric> get _strings =>
      widget.metrics.where((m) => m.type == MetricType.string).toList();

  bool get _canReorder => widget.metrics.length >= 2;

  void _enterReorder() {
    setState(() {
      _draft = List<MonitorMetric>.from(widget.metrics);
      _isReordering = true;
    });
  }

  void _cancelReorder() {
    setState(() {
      _isReordering = false;
      _draft = List<MonitorMetric>.from(widget.metrics);
    });
  }

  Future<void> _saveReorder() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final ids = _draft.map((m) => m.id).toList();
    final ok = await MonitorMetricController.instance.reorder(
      widget.monitorId,
      ids,
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (ok) {
        _isReordering = false;
      }
    });
    if (ok) {
      Magic.toast(trans('monitor.metric_group.reorder_success'));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final index = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final moved = _draft.removeAt(oldIndex);
      _draft.insert(index, moved);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        _header(),
        if (_isReordering) _reorderList() else ..._readOnlyBody(),
      ],
    );
  }

  Widget _header() {
    return WDiv(
      className: 'flex flex-row items-center gap-2',
      children: [
        WIcon(
          widget.icon,
          className: 'text-sm text-gray-500 dark:text-gray-400',
        ),
        WDiv(
          className: 'flex-1',
          child: WText(
            widget.group,
            className: '''
              text-xs font-bold uppercase tracking-wider
              text-gray-500 dark:text-gray-400
            ''',
          ),
        ),
        WDiv(
          className: '''
            px-2 py-0.5 rounded-full
            bg-gray-100 dark:bg-gray-800
          ''',
          child: WText(
            '${widget.metrics.length}',
            className: '''
              text-[10px] font-bold font-mono
              text-gray-600 dark:text-gray-300
            ''',
          ),
        ),
        if (_isReordering) ...[
          WButton(
            onTap: _isSaving ? null : _cancelReorder,
            className: '''
              px-2 py-1 rounded-md
              bg-gray-100 dark:bg-gray-800
              hover:bg-gray-200 dark:hover:bg-gray-700
            ''',
            child: WText(
              trans('monitor.metric_group.reorder_cancel'),
              className: '''
                text-xs font-semibold
                text-gray-600 dark:text-gray-300
              ''',
            ),
          ),
          WButton(
            onTap: _isSaving ? null : _saveReorder,
            className: '''
              px-2 py-1 rounded-md
              bg-primary text-white
              hover:bg-primary-600
            ''',
            child: WText(
              trans('monitor.metric_group.reorder_save'),
              className: 'text-xs font-semibold text-white',
            ),
          ),
        ] else ...[
          if (_canReorder)
            WButton(
              onTap: _enterReorder,
              className: '''
                w-7 h-7 rounded-md
                bg-white dark:bg-gray-800
                border border-gray-200 dark:border-gray-700
                hover:border-gray-300 dark:hover:border-gray-600
                flex items-center justify-center
              ''',
              child: WIcon(
                Icons.reorder_rounded,
                className: 'text-sm text-gray-500 dark:text-gray-400',
              ),
            ),
          if (widget.onAddMetric != null)
            WButton(
              onTap: widget.onAddMetric,
              className: '''
                w-7 h-7 rounded-md
                bg-white dark:bg-gray-800
                border border-gray-200 dark:border-gray-700
                hover:border-primary-300 dark:hover:border-primary-700
                hover:bg-primary-50 dark:hover:bg-primary-900/20
                flex items-center justify-center
              ''',
              child: WIcon(
                Icons.add_rounded,
                className: 'text-sm text-gray-500 dark:text-gray-400',
              ),
            ),
        ],
      ],
    );
  }

  List<Widget> _readOnlyBody() {
    final cards = _cards;
    final strings = _strings;
    return [
      if (cards.isNotEmpty)
        WDiv(
          className: 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3',
          children: [
            for (final m in cards)
              if (m.type == MetricType.numeric)
                NumericMetricCard(
                  monitorId: widget.monitorId,
                  metric: m,
                  onTap: widget.onMetricTap == null
                      ? null
                      : () => widget.onMetricTap!(m),
                )
              else
                StatusMetricCard(
                  monitorId: widget.monitorId,
                  metric: m,
                  onTap: widget.onMetricTap == null
                      ? null
                      : () => widget.onMetricTap!(m),
                ),
          ],
        ),
      if (strings.isNotEmpty)
        WDiv(
          className: 'flex flex-col gap-2',
          children: [
            for (final m in strings)
              StringMetricRow(
                monitorId: widget.monitorId,
                metric: m,
                onTap: widget.onMetricTap == null
                    ? null
                    : () => widget.onMetricTap!(m),
              ),
          ],
        ),
    ];
  }

  Widget _reorderList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _draft.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final metric = _draft[index];
        return ReorderableDragStartListener(
          key: ValueKey(metric.id),
          index: index,
          child: WDiv(
            className: '''
              flex flex-row items-center gap-3 px-3 py-2 my-1
              rounded-lg border
              bg-white dark:bg-gray-800
              border-gray-200 dark:border-gray-700
            ''',
            children: [
              WIcon(
                Icons.drag_indicator_rounded,
                className: 'text-base text-gray-400 dark:text-gray-500',
              ),
              WDiv(
                className: 'flex-1',
                child: WText(
                  metric.label ?? metric.key ?? '',
                  className: '''
                    text-sm font-semibold
                    text-gray-800 dark:text-gray-100 truncate
                  ''',
                ),
              ),
              if (metric.key != null)
                WText(
                  metric.key!,
                  className: '''
                    text-xs font-mono
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
            ],
          ),
        );
      },
    );
  }
}
