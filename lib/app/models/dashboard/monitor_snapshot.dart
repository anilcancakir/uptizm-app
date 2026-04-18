import '../../enums/monitor_status.dart';

/// Flattened monitor row used by the dashboard overview section.
///
/// Mirrors `MonitorSnapshotResource` on the API. Snapshots do not include
/// recent-sample history, since the API exposes only the last check; the
/// UI stubs the sparkline with the `lastStatus` value until a dedicated
/// recent-checks endpoint lands.
class MonitorSnapshot {
  const MonitorSnapshot({
    required this.id,
    required this.name,
    required this.url,
    required this.lastStatus,
    this.lastResponseMs,
    this.lastCheckedAt,
  });

  final String id;
  final String name;
  final String url;
  final MonitorStatus lastStatus;
  final int? lastResponseMs;
  final DateTime? lastCheckedAt;

  static MonitorSnapshot fromMap(Map<String, dynamic> map) {
    return MonitorSnapshot(
      id: map['id']?.toString() ?? '',
      name: (map['name'] as String?) ?? '',
      url: (map['url'] as String?) ?? '',
      lastStatus: _status(map['last_status']),
      lastResponseMs: _int(map['last_response_ms']),
      lastCheckedAt: _date(map['last_checked_at']),
    );
  }

  static MonitorStatus _status(Object? raw) {
    if (raw is! String) return MonitorStatus.paused;
    return MonitorStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MonitorStatus.paused,
    );
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
