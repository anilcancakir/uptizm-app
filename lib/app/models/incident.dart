import '../enums/ai_confidence.dart';
import '../enums/ai_trigger.dart';
import '../enums/component_status.dart';
import '../enums/incident_impact.dart';
import '../enums/incident_kind.dart';
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
    this.description,
    this.triggerRef,
    this.resolvedAt,
    this.metricKey,
    this.metricLabel,
    this.aiOwned = false,
    this.aiAnalysis,
    this.events = const [],
    this.similarIncidents = const [],
    this.kind = IncidentKind.incident,
    this.impact = IncidentImpact.none,
    this.impactOverride = false,
    this.isPublished = false,
    this.shortlink,
    this.postmortemBody,
    this.postmortemPublishedAt,
    this.affectedMonitors = const [],
    this.updates = const [],
  });

  final String id;
  final String monitorId;

  /// Owning team id. Sourced from `IncidentResource.team_id` so the client
  /// can run tenant-scoped authorization checks via `Gate`.
  final String? teamId;
  final String title;

  /// Free-form operator note. Rendered inside the drawer above the
  /// timeline; hidden when null or blank.
  final String? description;
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

  final IncidentKind kind;
  final IncidentImpact impact;
  final bool impactOverride;
  final bool isPublished;
  final String? shortlink;
  final String? postmortemBody;
  final DateTime? postmortemPublishedAt;
  final List<IncidentAffectedMonitor> affectedMonitors;
  final List<IncidentUpdate> updates;

  /// Wall-clock elapsed time since [startedAt]. Uses [resolvedAt] when set,
  /// otherwise the current time so live incidents report an ongoing duration.
  Duration get duration {
    final end = resolvedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Returns a copy with the mutable incident surface swapped. Immutable
  /// identity fields (id, monitorId, startedAt, signalSource) are preserved.
  Incident copyWith({
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? title,
    DateTime? resolvedAt,
    List<IncidentEvent>? events,
    List<SimilarIncident>? similarIncidents,
    AiAnalysis? aiAnalysis,
    IncidentKind? kind,
    IncidentImpact? impact,
    bool? impactOverride,
    bool? isPublished,
    String? postmortemBody,
    DateTime? postmortemPublishedAt,
    List<IncidentAffectedMonitor>? affectedMonitors,
    List<IncidentUpdate>? updates,
  }) {
    return Incident(
      id: id,
      monitorId: monitorId,
      teamId: teamId,
      description: description,
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
      kind: kind ?? this.kind,
      impact: impact ?? this.impact,
      impactOverride: impactOverride ?? this.impactOverride,
      isPublished: isPublished ?? this.isPublished,
      shortlink: shortlink,
      postmortemBody: postmortemBody ?? this.postmortemBody,
      postmortemPublishedAt:
          postmortemPublishedAt ?? this.postmortemPublishedAt,
      affectedMonitors: affectedMonitors ?? this.affectedMonitors,
      updates: updates ?? this.updates,
    );
  }

  /// Parses an `IncidentResource` payload. Unknown enum values fall back to
  /// safe defaults (severity: info, status: detected, source: manual) so a
  /// stale client never crashes on new backend values.
  static Incident fromMap(Map<String, dynamic> map) {
    final rawEvents = map['events'];
    final rawAffected = map['affected_monitors'];
    final rawUpdates = map['updates'];
    return Incident(
      id: map['id']?.toString() ?? '',
      monitorId: map['monitor_id']?.toString() ?? '',
      teamId: map['team_id']?.toString(),
      description: map['description'] as String?,
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
      kind: IncidentKind.fromWire(map['kind']),
      impact: IncidentImpact.fromWire(map['impact']),
      impactOverride: map['impact_override'] == true,
      isPublished: map['is_published'] == true,
      shortlink: map['shortlink'] as String?,
      postmortemBody: map['postmortem_body'] as String?,
      postmortemPublishedAt: _date(map['postmortem_published_at']),
      affectedMonitors: rawAffected is List
          ? rawAffected
                .whereType<Map<String, dynamic>>()
                .map(IncidentAffectedMonitor.fromMap)
                .toList()
          : const [],
      updates: rawUpdates is List
          ? rawUpdates
                .whereType<Map<String, dynamic>>()
                .map(IncidentUpdate.fromMap)
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

  static IncidentStatus _status(Object? raw) => IncidentStatus.fromWire(raw);

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

  /// Parses one timeline event. Missing `event_type` defaults to `note` so
  /// the timeline still renders the message when the backend omits the tag.
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

  /// Parses one row from `/incidents/{id}/similar`. Accepts either a nested
  /// `similar_to` payload (current shape) or a flat row for forward
  /// compatibility.
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

/// N:M affected component on an incident. Carries the pivot snapshot so
/// operators see both the starting state and the live state.
class IncidentAffectedMonitor {
  const IncidentAffectedMonitor({
    required this.monitorId,
    required this.name,
    required this.statusAtStart,
    required this.statusCurrent,
  });

  final String monitorId;
  final String name;
  final ComponentStatus statusAtStart;
  final ComponentStatus statusCurrent;

  static IncidentAffectedMonitor fromMap(Map<String, dynamic> map) {
    return IncidentAffectedMonitor(
      monitorId: map['monitor_id']?.toString() ?? map['id']?.toString() ?? '',
      name: (map['name'] as String?) ?? '',
      statusAtStart: ComponentStatus.fromWire(map['component_status_at_start']),
      statusCurrent: ComponentStatus.fromWire(map['component_status_current']),
    );
  }
}

/// One entry on the public incident update stream. Append-only; every
/// post is an [IncidentUpdate] row.
class IncidentUpdate {
  const IncidentUpdate({
    required this.id,
    required this.incidentId,
    required this.status,
    required this.body,
    required this.displayAt,
    this.deliverNotifications = true,
    this.authorLabel,
    this.affectedComponentsSnapshot = const [],
  });

  final String id;
  final String incidentId;
  final IncidentStatus status;
  final String body;
  final DateTime displayAt;
  final bool deliverNotifications;
  final String? authorLabel;
  final List<Map<String, dynamic>> affectedComponentsSnapshot;

  static IncidentUpdate fromMap(Map<String, dynamic> map) {
    final rawSnapshot = map['affected_components_snapshot'];
    return IncidentUpdate(
      id: map['id']?.toString() ?? '',
      incidentId: map['incident_id']?.toString() ?? '',
      status: IncidentStatus.fromWire(map['status']),
      body: (map['body'] as String?) ?? '',
      displayAt: _parseDate(map['display_at']) ?? DateTime.now(),
      deliverNotifications: map['deliver_notifications'] == true,
      authorLabel: map['author_label'] as String?,
      affectedComponentsSnapshot: rawSnapshot is List
          ? rawSnapshot.whereType<Map<String, dynamic>>().toList()
          : const [],
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
