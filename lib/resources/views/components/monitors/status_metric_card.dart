import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/monitor_metric.dart';
import 'metric_band_strip.dart';

/// Definition card for a status-type custom metric.
///
/// Shows the metric label, current status tinted by band, extraction
/// path, and a mini band strip of recent samples.
class StatusMetricCard extends StatelessWidget {
  const StatusMetricCard({
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
    assert(metric.type == MetricType.status);
    final statusValue = metric.latestValue?.statusValue;
    final band = metric.latestValue?.band;
    final valueText = statusValue == null ? '--' : statusValue.toUpperCase();
    final bandStates = band == null ? <String>{} : {band.name};

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
        className: 'flex flex-col gap-2 w-full',
        children: [
          WText(
            metric.label ?? metric.key ?? '',
            className: '''
              text-xs font-semibold uppercase tracking-wide
              text-gray-500 dark:text-gray-400
              truncate
            ''',
          ),
          WText(
            valueText,
            states: bandStates,
            className: '''
              text-2xl font-bold
              text-gray-400 dark:text-gray-500
              ok:text-up-600 dark:ok:text-up-400
              warn:text-degraded-600 dark:warn:text-degraded-400
              critical:text-down-600 dark:critical:text-down-400
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
          if (metric.id.isNotEmpty)
            MetricBandStrip(monitorId: monitorId, metric: metric),
        ],
      ),
    );
  }
}
