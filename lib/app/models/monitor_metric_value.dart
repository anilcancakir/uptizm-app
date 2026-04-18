import '../enums/metric_type.dart';

/// One sample on a metric time series.
///
/// Mirrors `MonitorMetricValueResource` — read-only, no persistence.
class MonitorMetricValue {
  MonitorMetricValue({
    this.recordedAt,
    this.numericValue,
    this.stringValue,
    this.statusValue,
    this.band,
  });

  final DateTime? recordedAt;
  final double? numericValue;
  final String? stringValue;
  final String? statusValue;
  final MetricBand? band;

  /// Parses one `MonitorMetricValueResource` row. Unknown `band` values
  /// collapse to null so a stale client never fails on new server bands.
  static MonitorMetricValue fromMap(Map<String, dynamic> map) {
    final rawRecorded = map['recorded_at'] as String?;
    final rawNumeric = map['numeric_value'];
    final rawBand = map['band'] as String?;
    return MonitorMetricValue(
      recordedAt: rawRecorded != null ? DateTime.tryParse(rawRecorded) : null,
      numericValue: rawNumeric is num ? rawNumeric.toDouble() : null,
      stringValue: map['string_value'] as String?,
      statusValue: map['status_value'] as String?,
      band: rawBand == null
          ? null
          : switch (rawBand) {
              'ok' => MetricBand.ok,
              'warn' => MetricBand.warn,
              'critical' => MetricBand.critical,
              _ => null,
            },
    );
  }
}
