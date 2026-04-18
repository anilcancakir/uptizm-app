import '../enums/ai_confidence.dart';
import '../enums/ai_trigger.dart';
import '../enums/incident_severity.dart';
import '../enums/incident_status.dart';
import '../enums/signal_source.dart';

/// Incident record bound to a monitor.
///
/// Wire shape matches `IncidentResource` on the API. The nested [events]
/// list is populated when the API eager-loads the relation (on the show
/// endpoint). [aiAnalysis] and [similarIncidents] are not part of the
/// base resource, they are filled by the AI phase and the
/// `/incidents/{id}/similar` endpoint respectively.
class Incident {
  const Incident({
    required this.id,
    required this.monitorId,
    required this.title,
    required this.severity,
    required this.status,
    required this.startedAt,
    required this.signalSource,
    this.teamId,
    this.triggerRef,
    this.resolvedAt,
    this.metricKey,
    this.metricLabel,
    this.aiOwned = false,
    this.aiAnalysis,
    this.events = const [],
    this.similarIncidents = const [],
  });

  final String id;
  final String monitorId;

  /// Owning team id. Sourced from `IncidentResource.team_id` so the client
  /// can run tenant-scoped authorization checks via `Gate`.
  final String? teamId;
  final String title;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final DateTime startedAt;
  final DateTime? resolvedAt;

  final SignalSource signalSource;
  final String? triggerRef;
  final String? metricKey;
  final String? metricLabel;
  final bool aiOwned;

  final AiAnalysis? aiAnalysis;
  final List<IncidentEvent> events;
  final List<SimilarIncident> similarIncidents;

  Duration get duration {
    final end = resolvedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  Incident copyWith({
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? title,
    DateTime? resolvedAt,
    List<IncidentEvent>? events,
    List<SimilarIncident>? similarIncidents,
    AiAnalysis? aiAnalysis,
  }) {
    return Incident(
      id: id,
      monitorId: monitorId,
      teamId: teamId,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      startedAt: startedAt,
      signalSource: signalSource,
      triggerRef: triggerRef,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      metricKey: metricKey,
      metricLabel: metricLabel,
      aiOwned: aiOwned,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      events: events ?? this.events,
      similarIncidents: similarIncidents ?? this.similarIncidents,
    );
  }

  static Incident fromMap(Map<String, dynamic> map) {
    final rawEvents = map['events'];
    return Incident(
      id: map['id']?.toString() ?? '',
      monitorId: map['monitor_id']?.toString() ?? '',
      teamId: map['team_id']?.toString(),
      title: (map['title'] as String?) ?? '',
      severity: _severity(map['severity']),
      status: _status(map['status']),
      startedAt: _date(map['started_at']) ?? DateTime.now(),
      resolvedAt: _date(map['resolved_at']),
      signalSource: _source(map['signal_source']),
      triggerRef: map['trigger_ref'] as String?,
      metricKey: map['metric_key'] as String?,
      metricLabel: map['metric_label'] as String?,
      aiOwned: map['ai_owned'] == true,
      events: rawEvents is List
          ? rawEvents
                .whereType<Map<String, dynamic>>()
                .map(IncidentEvent.fromMap)
                .toList()
          : const [],
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

  static SignalSource _source(Object? raw) {
    if (raw is! String) return SignalSource.manual;
    return switch (raw) {
      'user_threshold' => SignalSource.userThreshold,
      'ai_anomaly' => SignalSource.aiAnomaly,
      'manual' => SignalSource.manual,
      _ => SignalSource.manual,
    };
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

/// Entry on the incident timeline. `actor == 'ai'` renders with the
/// Uptizm AI avatar; `system` and user ids fall back to the generic chip.
class IncidentEvent {
  const IncidentEvent({
    required this.at,
    required this.actor,
    required this.type,
    required this.message,
    this.actorLabel,
  });

  final DateTime at;
  final String actor;
  final String? actorLabel;

  /// `opened` | `status_changed` | `note` | `ai_suggestion` |
  /// `ai_auto_resolved` | `acknowledged` | `resolved`
  final String type;
  final String message;

  static IncidentEvent fromMap(Map<String, dynamic> map) {
    return IncidentEvent(
      at: _date(map['at']) ?? DateTime.now(),
      actor: (map['actor'] as String?) ?? 'system',
      actorLabel: map['actor_label'] as String?,
      type: (map['event_type'] as String?) ?? 'note',
      message: (map['message'] as String?) ?? '',
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

/// AI-generated analysis attached to an incident. Only present when the
/// monitor's effective AI mode is `suggest` or `auto`. Not part of the
/// base `IncidentResource`, wired separately in the AI phase.
class AiAnalysis {
  const AiAnalysis({
    required this.tldr,
    required this.confidence,
    required this.trigger,
    this.evidence = const [],
    this.suggestedActions = const [],
  });

  final String tldr;
  final AiConfidence confidence;
  final AiTrigger trigger;
  final List<AiEvidence> evidence;
  final List<AiSuggestedAction> suggestedActions;
}

/// Single piece of evidence backing an [AiAnalysis] narrative.
///
/// `metricKey` points at a metric on the owning monitor when the evidence
/// is quantitative; free-form observations leave it `null`.
class AiEvidence {
  const AiEvidence({required this.label, required this.detail, this.metricKey});

  final String label;
  final String detail;
  final String? metricKey;
}

/// Remediation step proposed by the AI for an incident.
///
/// Rendered in the incident detail panel as actionable copy; does not
/// execute anything on its own.
class AiSuggestedAction {
  const AiSuggestedAction({required this.title, required this.rationale});

  final String title;
  final String rationale;
}

/// Cosine-ranked sibling of an incident. Fetched on demand via
/// `GET /incidents/{id}/similar`; see `SimilarIncidentResource`.
class SimilarIncident {
  const SimilarIncident({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.resolutionNote,
    this.similarityScore,
  });

  final String id;
  final String title;
  final DateTime occurredAt;
  final String resolutionNote;
  final double? similarityScore;

  static SimilarIncident fromMap(Map<String, dynamic> map) {
    final similarTo = map['similar_to'];
    final nested = similarTo is Map<String, dynamic> ? similarTo : null;
    return SimilarIncident(
      id: (nested?['id'] ?? map['id'])?.toString() ?? '',
      title: (nested?['title'] as String?) ?? '',
      occurredAt:
          _date(nested?['started_at'] ?? map['discovered_at']) ??
          DateTime.now(),
      resolutionNote: (map['resolution_note'] as String?) ?? '',
      similarityScore: (map['similarity_score'] as num?)?.toDouble(),
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
