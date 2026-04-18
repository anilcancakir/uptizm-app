import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/monitor_metric.dart';
import 'metric_band_strip.dart';

/// Definition card for a numeric custom metric.
///
/// Renders the metric label, unit, extraction path, threshold bounds, and
/// a mini band strip of recent samples. Full sparkline + history lives
/// in [MetricDetailSheet].
class NumericMetricCard extends StatelessWidget {
  const NumericMetricCard({
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
    assert(metric.type == MetricType.numeric);
    final warn = metric.warnBound;
    final critical = metric.criticalBound;
    final sample = metric.latestValue?.numericValue;
    final band = metric.latestValue?.band;
    final valueText = sample == null ? '--' : _fmt(sample);
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
          WDiv(
            className: 'flex flex-row items-baseline gap-1',
            children: [
              WText(
                valueText,
                states: bandStates,
                className: '''
                  text-2xl font-bold font-mono
                  text-gray-400 dark:text-gray-500
                  ok:text-up-600 dark:ok:text-up-400
                  warn:text-degraded-600 dark:warn:text-degraded-400
                  critical:text-down-600 dark:critical:text-down-400
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
          if (warn != null || critical != null)
            WText(
              _thresholdLabel(warn, critical, metric.unit),
              className: '''
                text-[10px] font-mono
                text-gray-500 dark:text-gray-400
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

  String _thresholdLabel(double? warn, double? critical, String? unit) {
    final parts = <String>[];
    final suffix = unit == null ? '' : ' $unit';
    if (warn != null) parts.add('warn ${_fmt(warn)}$suffix');
    if (critical != null) parts.add('crit ${_fmt(critical)}$suffix');
    return parts.join(' · ');
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
