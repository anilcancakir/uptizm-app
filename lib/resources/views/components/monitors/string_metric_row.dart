import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/mock/monitor_metric.dart';

/// Compact list row for string / enum response metrics.
///
/// Kept visually lighter than numeric cards: one line per metric with the
/// label on the left and the monospaced value on the right.
class StringMetricRow extends StatelessWidget {
  const StringMetricRow({
    super.key,
    required this.metric,
    this.onTap,
  });

  final MonitorMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: onTap ?? () {},
      className: '''
        px-4 py-3
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        rounded-lg
        flex flex-row items-center gap-3
        hover:border-gray-300 dark:hover:border-gray-600
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5',
            children: [
              WText(
                metric.label,
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                  truncate
                ''',
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
          WText(
            metric.stringValue ?? '--',
            className: '''
              text-sm font-mono font-semibold
              text-gray-700 dark:text-gray-200
            ''',
          ),
        ],
      ),
    );
  }
}
