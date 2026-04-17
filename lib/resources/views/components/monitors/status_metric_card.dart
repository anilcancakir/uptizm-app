import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_type.dart';
import '../../../../app/enums/monitor_status.dart';
import '../../../../app/models/mock/monitor_metric.dart';

/// Card used in the Metrics tab for status-type custom metrics.
///
/// Matches [NumericMetricCard] dimensions so the metrics grid reads as one
/// uniform surface. Body shows a horizontal bar strip of recent status
/// samples, visually analogous to the uptime bar on the overview tab.
class StatusMetricCard extends StatelessWidget {
  const StatusMetricCard({
    super.key,
    required this.metric,
    this.onTap,
  });

  final MonitorMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    assert(metric.type == MetricType.status);
    final status = metric.statusValue ?? MonitorStatus.paused;
    final history = metric.statusHistory.isEmpty
        ? List<MonitorStatus>.filled(20, status)
        : metric.statusHistory;

    return WButton(
      onTap: onTap ?? () {},
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        flex flex-col gap-3
        items-stretch
      ''',
      child: WDiv(
        className: 'flex flex-col gap-3 w-full',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-2',
            children: [
              WDiv(
                states: {status.toneKey},
                className: '''
                  w-2 h-2 rounded-full
                  bg-gray-300 dark:bg-gray-600
                  up:bg-up-500 dark:up:bg-up-400
                  degraded:bg-degraded-500 dark:degraded:bg-degraded-400
                  down:bg-down-500 dark:down:bg-down-400
                  paused:bg-paused-400 dark:paused:bg-paused-500
                ''',
              ),
              WDiv(
                className: 'flex-1',
                child: WText(
                  metric.label,
                  className: '''
                    text-xs font-semibold uppercase tracking-wide
                    text-gray-500 dark:text-gray-400
                    truncate
                  ''',
                ),
              ),
            ],
          ),
          WText(
            trans(status.labelKey),
            states: {status.toneKey},
            className: '''
              text-2xl font-bold
              text-gray-900 dark:text-white
              up:text-up-600 dark:up:text-up-400
              down:text-down-600 dark:down:text-down-400
              degraded:text-degraded-600 dark:degraded:text-degraded-400
              paused:text-paused-600 dark:paused:text-paused-300
            ''',
          ),
          WDiv(
            className: '''
              flex flex-row gap-0.5 h-8 rounded-md overflow-hidden
            ''',
            children: history.map(_segment).toList(),
          ),
          if (metric.path != null)
            WText(
              metric.path!,
              className: '''
                text-[10px] font-mono truncate
                text-gray-400 dark:text-gray-500
              ''',
            ),
        ],
      ),
    );
  }

  Widget _segment(MonitorStatus status) {
    return WDiv(
      states: {status.toneKey},
      className: '''
        flex-1 h-full
        bg-gray-200 dark:bg-gray-700
        up:bg-up-500 dark:up:bg-up-400
        down:bg-down-500 dark:down:bg-down-400
        degraded:bg-degraded-500 dark:degraded:bg-degraded-400
        paused:bg-paused-400 dark:paused:bg-paused-500
      ''',
    );
  }
}
