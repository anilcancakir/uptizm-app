import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Compact line sparkline for metric cards, backed by fl_chart.
///
/// Color is resolved from [toneKey] (`up` / `degraded` / `down` / fallback)
/// via the Wind theme so the chart tracks palette + dark mode automatically.
class MetricSparkline extends StatelessWidget {
  const MetricSparkline({
    super.key,
    required this.samples,
    required this.toneKey,
  });

  final List<double> samples;
  final String toneKey;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return WDiv(className: 'h-8');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        _toneColor(context) ??
        wColor(context, 'gray', shade: 400, darkShade: 500)!;
    final fillStart = color.withValues(alpha: isDark ? 0.22 : 0.14);
    final fillEnd = color.withValues(alpha: 0);

    final spots = <FlSpot>[
      for (var i = 0; i < samples.length; i++) FlSpot(i.toDouble(), samples[i]),
    ];
    final maxV = samples.reduce((a, b) => a > b ? a : b);
    final minV = samples.reduce((a, b) => a < b ? a : b);
    final pad = (maxV - minV).abs() * 0.15;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (samples.length - 1).toDouble(),
        minY: minV - pad,
        maxY: maxV + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 1.8,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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
      ),
    );
  }

  Color? _toneColor(BuildContext context) {
    return switch (toneKey) {
      'up' => wColor(context, 'up', shade: 500, darkShade: 400),
      'degraded' => wColor(context, 'degraded', shade: 500, darkShade: 400),
      'down' => wColor(context, 'down', shade: 500, darkShade: 400),
      _ => wColor(context, 'primary'),
    };
  }
}
