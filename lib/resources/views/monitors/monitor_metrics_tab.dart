import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/metrics/monitor_metric_controller.dart';
import '../../../app/models/monitor_metric.dart';
import '../components/common/error_banner.dart';
import '../components/common/skeleton_block.dart';
import '../components/monitors/metric_detail_sheet.dart';
import '../components/monitors/metric_form_sheet.dart';
import '../components/monitors/metric_group_section.dart';
import '../components/monitors/metrics_empty_state.dart';

/// Metrics tab body for the monitor detail screen.
///
/// Loads the monitor's custom metric definitions via
/// [MonitorMetricController] and renders them grouped by `group_name`.
/// The empty state surfaces an add-metric affordance wired to the form
/// sheet; successful mutations trigger a controller reload which this
/// view picks up automatically via [MagicStatefulView].
class MonitorMetricsTab extends MagicStatefulView<MonitorMetricController> {
  const MonitorMetricsTab({super.key, required this.monitorId});

  final String monitorId;

  @override
  State<MonitorMetricsTab> createState() => _MonitorMetricsTabState();
}

class _MonitorMetricsTabState
    extends MagicStatefulViewState<MonitorMetricController, MonitorMetricsTab> {
  @override
  void onInit() {
    super.onInit();
    if (controller.currentMonitorId != widget.monitorId) {
      controller.load(widget.monitorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return controller.renderState(
      (_) => _body(controller.groups),
      onLoading: WDiv(
        className: 'flex flex-col gap-4',
        children: const [
          SkeletonBlock(className: 'w-1/3 h-5'),
          SkeletonBlock(className: 'w-full h-24 rounded-xl'),
          SkeletonBlock(className: 'w-full h-24 rounded-xl'),
        ],
      ),
      onEmpty: MetricsEmptyState(monitorId: widget.monitorId),
      onError: (msg) => ErrorBanner(
        message: msg,
        onRetry: () => controller.load(widget.monitorId),
      ),
    );
  }

  Widget _body(Map<String, List<MonitorMetric>> groups) {
    return WDiv(
      className: 'flex flex-col gap-6',
      children: [
        for (final entry in groups.entries)
          MetricGroupSection(
            monitorId: widget.monitorId,
            group: entry.key.isEmpty ? '—' : entry.key,
            icon: _groupIcon(entry.key),
            metrics: entry.value,
            onMetricTap: (m) => MetricDetailSheet.show(
              context,
              monitorId: widget.monitorId,
              metric: m,
            ),
            onAddMetric: () => _openCreateSheet(prefillGroup: entry.key),
          ),
      ],
    );
  }

  void _openCreateSheet({String? prefillGroup}) {
    final groupNames = controller.groups.keys.toList();
    MetricFormSheet.show(
      context,
      mode: 'create',
      monitorId: widget.monitorId,
      existingGroups: groupNames,
      initial: MetricFormInitial(group: prefillGroup ?? ''),
    );
  }

  IconData _groupIcon(String group) {
    return switch (group.toLowerCase()) {
      'database' => Icons.storage_rounded,
      'queue' => Icons.layers_rounded,
      'cache' => Icons.bolt_rounded,
      'runtime' => Icons.memory_rounded,
      _ => Icons.analytics_rounded,
    };
  }
}
