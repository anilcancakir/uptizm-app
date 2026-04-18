import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/monitor_metric.dart';
import 'metric_band_strip.dart';

/// Compact list row for string / enum response metrics.
///
/// Shows the metric label, extraction path, latest value, and a mini
/// band strip of recent samples. Full history lives in [MetricDetailSheet].
class StringMetricRow extends StatelessWidget {
  const StringMetricRow({
    super.key,
    required this.monitorId,
    required this.metric,
    this.onTap,
  });

  final String monitorId;
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
        className: 'flex flex-col gap-2 w-full',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-3 w-full',
            children: [
              WDiv(
                className: 'flex-1 flex flex-col gap-0.5',
                children: [
                  WText(
                    metric.label ?? metric.key ?? '',
                    className: '''
                      text-sm font-semibold
                      text-gray-900 dark:text-white
                      truncate
                    ''',
                  ),
                  if (metric.extractionPath != null)
                    WText(
                      metric.extractionPath!,
                      className: '''
                        text-[10px] font-mono truncate
                        text-gray-400 dark:text-gray-500
                      ''',
                    ),
                ],
              ),
              WText(
                metric.latestValue?.stringValue ?? '--',
                className: '''
                  text-sm font-mono font-semibold
                  text-gray-700 dark:text-gray-200
                  truncate
                ''',
              ),
            ],
          ),
          if (metric.id.isNotEmpty)
            MetricBandStrip(monitorId: monitorId, metric: metric),
        ],
      ),
    );
  }
}
