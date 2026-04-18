import '../../enums/ai_confidence.dart';
import '../../enums/incident_severity.dart';

/// AI-authored suggestion awaiting review in the workspace inbox.
///
/// Mirrors `AiSuggestionResource` on the API. Produced only for monitors
/// whose effective AI mode is `suggest`; auto-promoted to incidents under
/// `auto` mode, never emitted under `off`.
class AiSuggestion {
  const AiSuggestion({
    required this.id,
    required this.monitorId,
    required this.title,
    required this.severity,
    required this.confidence,
    required this.tldr,
    required this.status,
    required this.createdAt,
    this.metricKey,
  });

  final String id;
  final String monitorId;
  final String title;
  final IncidentSeverity severity;
  final AiConfidence confidence;
  final String tldr;
  final String? metricKey;
  final String status;
  final DateTime createdAt;

  /// Parses an `AiSuggestionResource` payload.
  static AiSuggestion fromMap(Map<String, dynamic> map) {
    return AiSuggestion(
      id: map['id']?.toString() ?? '',
      monitorId: map['monitor_id']?.toString() ?? '',
      title: (map['title'] as String?) ?? '',
      severity: _severity(map['severity']),
      confidence: _confidence(map['confidence']),
      tldr: (map['tldr'] as String?) ?? '',
      metricKey: map['metric_key'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      createdAt: _date(map['created_at']) ?? DateTime.now(),
    );
  }

  static IncidentSeverity _severity(Object? raw) {
    if (raw is! String) return IncidentSeverity.info;
    return IncidentSeverity.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => IncidentSeverity.info,
    );
  }

  static AiConfidence _confidence(Object? raw) {
    if (raw is! String) return AiConfidence.medium;
    return AiConfidence.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AiConfidence.medium,
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
