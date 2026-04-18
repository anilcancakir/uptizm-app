import 'package:magic/magic.dart';

import '../enums/metric_source.dart';
import '../enums/metric_type.dart';
import '../enums/threshold_direction.dart';
import 'monitor_metric_value.dart';

/// Monitor metric model.
///
/// Mirrors `MonitorMetricResource` on the API. Enum fields are exchanged
/// as the PHP backing string (snake_case), not the Dart case name — see
/// the wire-value mappers below.
class MonitorMetric extends Model with HasTimestamps, InteractsWithPersistence {
  @override
  String get table => 'monitor_metrics';

  /// Nested resource; the controller builds the final URL per action, so
  /// [save]/[delete] on this model are NOT used.
  @override
  String get resource => 'monitor-metrics';

  @override
  bool get incrementing => false;

  @override
  List<String> get fillable => [
    'group_name',
    'label',
    'key',
    'type',
    'source',
    'extraction_path',
    'unit',
    'threshold_direction',
    'warn_bound',
    'critical_bound',
    'display_order',
  ];

  @override
  Map<String, String> get casts => {};

  @override
  String get id => getAttribute('id')?.toString() ?? '';

  String? get monitorId => getAttribute('monitor_id')?.toString();

  String? get groupName => getAttribute('group_name') as String?;
  String? get label => getAttribute('label') as String?;
  String? get key => getAttribute('key') as String?;
  String? get extractionPath => getAttribute('extraction_path') as String?;
  String? get unit => getAttribute('unit') as String?;

  MetricType? get type {
    final raw = getAttribute('type') as String?;
    if (raw == null) return null;
    return MetricType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => MetricType.numeric,
    );
  }

  MetricSource? get source {
    final raw = getAttribute('source') as String?;
    if (raw == null) return null;
    return switch (raw) {
      'json_path' => MetricSource.jsonPath,
      'regex' => MetricSource.regex,
      'xpath' => MetricSource.xpath,
      'header' => MetricSource.header,
      _ => null,
    };
  }

  ThresholdDirection? get thresholdDirection {
    final raw = getAttribute('threshold_direction') as String?;
    if (raw == null) return null;
    return switch (raw) {
      'high_bad' => ThresholdDirection.highBad,
      'low_bad' => ThresholdDirection.lowBad,
      _ => null,
    };
  }

  double? get warnBound {
    final raw = getAttribute('warn_bound');
    if (raw is num) return raw.toDouble();
    return null;
  }

  double? get criticalBound {
    final raw = getAttribute('critical_bound');
    if (raw is num) return raw.toDouble();
    return null;
  }

  int get displayOrder {
    final raw = getAttribute('display_order');
    return raw is int ? raw : 0;
  }

  /// Most recent persisted sample for this metric. Null when the metric
  /// has never been extracted yet (e.g. brand new monitor) or when the
  /// index payload omits it.
  MonitorMetricValue? get latestValue {
    final raw = getAttribute('latest_value');
    if (raw is! Map) return null;
    return MonitorMetricValue.fromMap(Map<String, dynamic>.from(raw));
  }

  static MonitorMetric fromMap(Map<String, dynamic> map) {
    return MonitorMetric()
      ..setRawAttributes(map, sync: true)
      ..exists = map.containsKey('id');
  }

  /// Wire value for [MetricSource] (PHP snake_case backing).
  static String sourceToWire(MetricSource source) {
    return switch (source) {
      MetricSource.jsonPath => 'json_path',
      MetricSource.regex => 'regex',
      MetricSource.xpath => 'xpath',
      MetricSource.header => 'header',
      MetricSource.httpStatus => 'http_status',
    };
  }

  /// Wire value for [ThresholdDirection] (PHP snake_case backing).
  static String directionToWire(ThresholdDirection direction) {
    return switch (direction) {
      ThresholdDirection.highBad => 'high_bad',
      ThresholdDirection.lowBad => 'low_bad',
    };
  }
}
