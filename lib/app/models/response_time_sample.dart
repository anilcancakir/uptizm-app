import '../enums/monitor_status.dart';

/// One point on the response-time series chart. Shape mirrors the JSON
/// returned by GET /monitors/{id}/response-times.
class ResponseTimeSample {
  const ResponseTimeSample({
    required this.checkedAt,
    required this.responseMs,
    required this.status,
    required this.region,
  });

  final DateTime checkedAt;
  final int responseMs;
  final MonitorStatus status;
  final String? region;

  static ResponseTimeSample? fromMap(Map<String, dynamic> map) {
    final rawCheckedAt = map['checked_at'];
    final checkedAt = rawCheckedAt is String
        ? DateTime.tryParse(rawCheckedAt)
        : (rawCheckedAt is DateTime ? rawCheckedAt : null);
    final responseMs = (map['response_ms'] as num?)?.toInt();
    if (checkedAt == null || responseMs == null) return null;
    final statusRaw = map['status'] as String?;
    final status = MonitorStatus.values.firstWhere(
      (v) => v.name == statusRaw,
      orElse: () => MonitorStatus.up,
    );
    return ResponseTimeSample(
      checkedAt: checkedAt,
      responseMs: responseMs,
      status: status,
      region: map['region'] as String?,
    );
  }
}
