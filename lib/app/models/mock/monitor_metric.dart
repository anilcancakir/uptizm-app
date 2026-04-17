import '../../enums/metric_source.dart';
import '../../enums/metric_type.dart';
import '../../enums/monitor_status.dart';

/// Design-time mock record for a custom response metric.
///
/// Not wired to persistence yet; populated inline in views for the
/// Metrics tab mockup.
class MonitorMetric {
  const MonitorMetric({
    required this.group,
    required this.label,
    required this.key,
    required this.type,
    this.source,
    this.path,
    this.unit,
    this.numericValue,
    this.stringValue,
    this.statusValue,
    this.band,
    this.trendLabel,
    this.trendPositive,
    this.samples = const [],
    this.statusHistory = const [],
  });

  final String group;
  final String label;
  final String key;
  final MetricType type;

  /// Where in the response the value is extracted from.
  final MetricSource? source;

  /// Path / expression inside the response (JSONPath, regex, xpath, header).
  final String? path;
  final String? unit;
  final double? numericValue;
  final String? stringValue;
  final MonitorStatus? statusValue;
  final MetricBand? band;
  final String? trendLabel;
  final bool? trendPositive;
  final List<double> samples;

  /// Recent status samples for status-type metrics, oldest first. Renders as
  /// a bar-graph strip similar to the uptime bar on the overview tab.
  final List<MonitorStatus> statusHistory;
}
