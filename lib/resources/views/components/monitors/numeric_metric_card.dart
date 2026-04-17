import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/mock/monitor_metric.dart';
import 'metric_sparkline.dart';

/// Card used in the Metrics tab for numeric custom metrics.
///
/// Shows label + big value + unit, a status dot tied to the threshold band,
/// an optional trend badge, and a compact sparkline across recent samples.
class NumericMetricCard extends StatelessWidget {
  const NumericMetricCard({
    super.key,
    required this.metric,
    this.onTap,
  });

  final MonitorMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    assert(metric.type == MetricType.numeric);
    final band = metric.band;
    final toneKey = band?.toneKey ?? '';

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
                states: {toneKey},
                className: '''
                  w-2 h-2 rounded-full
                  bg-gray-300 dark:bg-gray-600
                  up:bg-up-500 dark:up:bg-up-400
                  degraded:bg-degraded-500 dark:degraded:bg-degraded-400
                  down:bg-down-500 dark:down:bg-down-400
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
              if (metric.trendLabel != null)
                WDiv(
                  states: {metric.trendPositive == true ? 'up' : 'down'},
                  className: '''
                    px-1.5 py-0.5 rounded-md
                    text-[10px] font-bold
                    bg-gray-100 dark:bg-gray-700
                    text-gray-600 dark:text-gray-300
                    up:bg-up-50 dark:up:bg-up-900/30
                    up:text-up-700 dark:up:text-up-300
                    down:bg-down-50 dark:down:bg-down-900/30
                    down:text-down-700 dark:down:text-down-300
                  ''',
                  child: WText(metric.trendLabel!),
                ),
            ],
          ),
          WDiv(
            className: 'flex flex-row items-baseline gap-1',
            children: [
              WText(
                _formatValue(metric.numericValue),
                className: '''
                  text-2xl font-bold font-mono
                  text-gray-900 dark:text-white
                ''',
              ),
              if (metric.unit != null)
                WText(
                  metric.unit!,
                  className: '''
                    text-xs font-semibold
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
            ],
          ),
          WDiv(
            className: 'h-8',
            child: MetricSparkline(
              samples: metric.samples,
              toneKey: toneKey,
            ),
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

  String _formatValue(double? v) {
    if (v == null) return '--';
    if (v >= 1000) return v.toStringAsFixed(0);
    if (v % 1 == 0) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}
