import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/controllers/metrics/monitor_metric_controller.dart';
import '../../../../app/enums/metric_type.dart';
import '../../../../app/enums/threshold_direction.dart';
import '../../../../app/models/monitor_metric.dart';
import '../../../../app/models/monitor_metric_value.dart';

/// Thin horizontal strip of the last ~20 samples for a metric, plus an
/// optional % delta chip. Colors each tick by its band (ok / warn /
/// critical / unknown). The delta compares latest vs first sample in
/// the fetched window; good/bad polarity follows [MonitorMetric.thresholdDirection].
///
/// Samples come from the shared [MonitorMetricController.seriesByKey] map
/// populated by [MonitorMetricController.loadSeries] — one batch request
/// per tab open, not one XHR per card.
class MetricBandStrip extends StatelessWidget {
  const MetricBandStrip({
    super.key,
    required this.monitorId,
    required this.metric,
    this.limit = 20,
  });

  final String monitorId;
  final MonitorMetric metric;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final controller = MonitorMetricController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => _render(controller.seriesByKey[metric.key]),
    );
  }

  Widget _render(List<MonitorMetricValue>? samples) {
    if (samples == null) {
      return WDiv(
        className: '''
          h-2 rounded-sm
          bg-gray-100 dark:bg-gray-800
        ''',
      );
    }
    if (samples.isEmpty) {
      return WDiv(
        className: '''
          h-2 rounded-sm
          bg-gray-100 dark:bg-gray-800
        ''',
      );
    }
    // batchSeries returns oldest-first already; keep chronological order.
    final ordered = samples;
    final trimmed = ordered.length > limit
        ? ordered.sublist(ordered.length - limit)
        : ordered;
    final delta = _computeDelta(trimmed);

    return WDiv(
      className: 'flex flex-row items-center gap-2',
      children: [
        WDiv(
          className: 'flex-1',
          child: WDiv(
            className: 'flex flex-row gap-0.5 h-2 items-stretch',
            children: [
              for (final s in trimmed)
                WDiv(
                  states: {s.band?.name ?? 'unknown'},
                  className: '''
                    flex-1 rounded-sm
                    bg-gray-200 dark:bg-gray-700
                    ok:bg-up-500 dark:ok:bg-up-400
                    warn:bg-degraded-500 dark:warn:bg-degraded-400
                    critical:bg-down-500 dark:critical:bg-down-400
                  ''',
                ),
            ],
          ),
        ),
        if (delta != null) _deltaChip(delta),
      ],
    );
  }

  _Delta? _computeDelta(List<MonitorMetricValue> ordered) {
    if (metric.type != MetricType.numeric) return null;
    if (ordered.length < 2) return null;
    final firstNumeric = ordered
        .firstWhere(
          (s) => s.numericValue != null,
          orElse: MonitorMetricValue.new,
        )
        .numericValue;
    final lastNumeric = ordered
        .lastWhere(
          (s) => s.numericValue != null,
          orElse: MonitorMetricValue.new,
        )
        .numericValue;
    if (firstNumeric == null || lastNumeric == null) return null;
    if (firstNumeric == 0) return null;
    final pct = ((lastNumeric - firstNumeric) / firstNumeric.abs()) * 100;
    if (pct.abs() < 0.1) return const _Delta(percent: 0, isGood: true);
    final direction = metric.thresholdDirection;
    final increased = pct > 0;
    final isGood = switch (direction) {
      ThresholdDirection.highBad => !increased,
      ThresholdDirection.lowBad => increased,
      null => !increased,
    };
    return _Delta(percent: pct, isGood: isGood);
  }

  Widget _deltaChip(_Delta delta) {
    final sign = delta.percent > 0 ? '+' : '';
    final label = '$sign${delta.percent.toStringAsFixed(1)}%';
    final tone = delta.percent == 0 ? 'flat' : (delta.isGood ? 'good' : 'bad');
    final icon = delta.percent == 0
        ? Icons.trending_flat_rounded
        : (delta.percent > 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded);
    return WDiv(
      states: {tone},
      className: '''
        px-1.5 py-0.5 rounded-full
        flex flex-row items-center gap-1
        bg-gray-100 dark:bg-gray-800
        good:bg-up-50 dark:good:bg-up-900/30
        bad:bg-down-50 dark:bad:bg-down-900/30
      ''',
      children: [
        WIcon(
          icon,
          states: {tone},
          className: '''
            text-[10px]
            text-gray-500 dark:text-gray-400
            good:text-up-600 dark:good:text-up-400
            bad:text-down-600 dark:bad:text-down-400
          ''',
        ),
        WText(
          label,
          states: {tone},
          className: '''
            text-[10px] font-mono font-semibold
            text-gray-600 dark:text-gray-300
            good:text-up-700 dark:good:text-up-300
            bad:text-down-700 dark:bad:text-down-300
          ''',
        ),
      ],
    );
  }
}

class _Delta {
  const _Delta({required this.percent, required this.isGood});

  final double percent;
  final bool isGood;
}
