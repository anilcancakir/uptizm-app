import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/monitor_metric.dart';
import 'numeric_metric_card.dart';
import 'status_metric_card.dart';
import 'string_metric_row.dart';

/// Renders one user-defined metric group (e.g. Database, Queue, Cache).
///
/// Layout per group:
///  1. Group header: icon + title + count badge
///  2. Status pill wrap row (if any status metrics)
///  3. Numeric cards grid (1 / 2 / 3 cols responsive)
///  4. String / duration row list (if any)
class MetricGroupSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cards = metrics
        .where(
          (m) => m.type == MetricType.numeric || m.type == MetricType.status,
        )
        .toList();
    final strings = metrics.where((m) => m.type == MetricType.string).toList();

    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WIcon(icon, className: 'text-sm text-gray-500 dark:text-gray-400'),
            WDiv(
              className: 'flex-1',
              child: WText(
                group,
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
                '${metrics.length}',
                className: '''
                  text-[10px] font-bold font-mono
                  text-gray-600 dark:text-gray-300
                ''',
              ),
            ),
            if (onAddMetric != null)
              WButton(
                onTap: onAddMetric,
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
                  className: '''
                    text-sm
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
              ),
          ],
        ),
        if (cards.isNotEmpty)
          WDiv(
            className: 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3',
            children: [
              for (final m in cards)
                if (m.type == MetricType.numeric)
                  NumericMetricCard(
                    monitorId: monitorId,
                    metric: m,
                    onTap: onMetricTap == null ? null : () => onMetricTap!(m),
                  )
                else
                  StatusMetricCard(
                    monitorId: monitorId,
                    metric: m,
                    onTap: onMetricTap == null ? null : () => onMetricTap!(m),
                  ),
            ],
          ),
        if (strings.isNotEmpty)
          WDiv(
            className: 'flex flex-col gap-2',
            children: [
              for (final m in strings)
                StringMetricRow(
                  monitorId: monitorId,
                  metric: m,
                  onTap: onMetricTap == null ? null : () => onMetricTap!(m),
                ),
            ],
          ),
      ],
    );
  }
}
