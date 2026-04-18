import '../../enums/incident_severity.dart';
import '../../enums/incident_status.dart';

/// Compact incident projection used by the dashboard active-incidents strip.
///
/// Mirrors `IncidentSummaryResource` on the API. Narrower than the full
/// `Incident` model, so the view can render cards without hydrating events
/// or AI analysis.
class IncidentSummary {
  const IncidentSummary({
    required this.id,
    required this.monitorId,
    required this.title,
    required this.severity,
    required this.status,
    required this.startedAt,
    this.aiOwned = false,
  });

  final String id;
  final String monitorId;
  final String title;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final DateTime startedAt;
  final bool aiOwned;

  static IncidentSummary fromMap(Map<String, dynamic> map) {
    return IncidentSummary(
      id: map['id']?.toString() ?? '',
      monitorId: map['monitor_id']?.toString() ?? '',
      title: (map['title'] as String?) ?? '',
      severity: _severity(map['severity']),
      status: _status(map['status']),
      startedAt: _date(map['started_at']) ?? DateTime.now(),
      aiOwned: map['ai_owned'] == true,
    );
  }

  static IncidentSeverity _severity(Object? raw) {
    if (raw is! String) return IncidentSeverity.info;
    return IncidentSeverity.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => IncidentSeverity.info,
    );
  }

  static IncidentStatus _status(Object? raw) {
    if (raw is! String) return IncidentStatus.detected;
    return IncidentStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => IncidentStatus.detected,
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
