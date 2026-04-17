import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';

/// One sample on the response-time chart.
class ResponseSample {
  const ResponseSample({
    required this.timestamp,
    required this.responseMs,
    required this.status,
  });

  final DateTime timestamp;
  final int responseMs;
  final MonitorStatus status;
}

/// Response-time line chart backed by fl_chart.
///
/// Renders a smooth primary-tinted line with gradient fill and per-sample
/// dots colored by status (up/degraded/down/paused).
class ResponseSparkline extends StatelessWidget {
  const ResponseSparkline({
    super.key,
    required this.samples,
    this.heightPx = 180,
  });

  final List<ResponseSample> samples;
  final double heightPx;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return WDiv(
        className: '''
          flex items-center justify-center rounded-lg
          h-[${heightPx.toInt()}px]
          bg-gray-50 dark:bg-gray-900
        ''',
        child: WText(
          trans('monitor.chart.no_data'),
          className: 'text-sm text-gray-400 dark:text-gray-500',
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = wColor(context, 'primary')!;
    final grid = wColor(
      context,
      'gray',
      shade: 100,
      darkColorName: 'gray',
      darkShade: 700,
    )!;
    final textColor = wColor(
      context,
      'gray',
      shade: 500,
      darkColorName: 'gray',
      darkShade: 400,
    )!;
    final dotStroke = wColor(
      context,
      'white',
      darkColorName: 'gray',
      darkShade: 800,
    )!;
    final fillStart = primary.withValues(alpha: isDark ? 0.18 : 0.12);
    final fillEnd = primary.withValues(alpha: 0);

    final spots = <FlSpot>[
      for (var i = 0; i < samples.length; i++)
        FlSpot(i.toDouble(), samples[i].responseMs.toDouble()),
    ];
    final maxMs = samples
        .map((s) => s.responseMs.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxMs * 1.2;
    final yInterval = _yInterval(maxY);
    final xInterval = _xInterval(samples.length);

    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        WDiv(
          className: 'h-[${heightPx.toInt()}px]',
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (samples.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: grid, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: yInterval,
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${value.toInt()}ms',
                        style: TextStyle(color: textColor, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: xInterval,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= samples.length) {
                        return const SizedBox.shrink();
                      }
                      final t = samples[i].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${t.hour.toString().padLeft(2, '0')}:'
                          '${t.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: textColor, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: primary,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, _, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: _dotColor(context, samples[index].status) ??
                            primary,
                        strokeWidth: 1.5,
                        strokeColor: dotStroke,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [fillStart, fillEnd],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => wColor(
                    context,
                    'white',
                    darkColorName: 'gray',
                    darkShade: 700,
                  )!,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  getTooltipItems: (touched) {
                    return touched.map((spot) {
                      final s = samples[spot.spotIndex];
                      final t = s.timestamp;
                      final time =
                          '${t.hour.toString().padLeft(2, '0')}:'
                          '${t.minute.toString().padLeft(2, '0')}';
                      return LineTooltipItem(
                        '${s.responseMs}ms\n',
                        TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: time,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color? _dotColor(BuildContext context, MonitorStatus status) {
    return switch (status) {
      MonitorStatus.up => wColor(context, 'up', shade: 500),
      MonitorStatus.down => wColor(context, 'down', shade: 500),
      MonitorStatus.degraded => wColor(context, 'degraded', shade: 500),
      MonitorStatus.paused => wColor(context, 'paused', shade: 400),
    };
  }

  double _yInterval(double maxY) {
    if (maxY <= 100) return 25;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    return (maxY / 5).roundToDouble();
  }

  double _xInterval(int count) {
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    if (count <= 24) return 4;
    return (count / 6).roundToDouble();
  }
}
