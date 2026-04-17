import '../../enums/ai_confidence.dart';
import '../../enums/ai_trigger.dart';
import '../../enums/incident_severity.dart';
import '../../enums/incident_status.dart';
import '../../enums/signal_source.dart';

/// Incident record for a monitor.
///
/// Mock shape used by the Incidents list and detail panel.
///
/// Every incident declares a [signalSource] so the UI can show *why* it was
/// opened (threshold, AI anomaly, or manual report) and the three paths stay
/// consistent through one pipe. [aiOwned] is independent: an incident opened
/// from any source may be driven by AI (mode=auto) until a human takes over.
class Incident {
  const Incident({
    required this.id,
    required this.monitorId,
    required this.title,
    required this.severity,
    required this.status,
    required this.startedAt,
    required this.signalSource,
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
  final String title;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final DateTime startedAt;
  final DateTime? resolvedAt;

  /// Where the signal came from (threshold / AI / manual).
  final SignalSource signalSource;

  /// Reference to what triggered it: metric key, anomaly id, or null for
  /// manual reports with no specific target.
  final String? triggerRef;

  final String? metricKey;
  final String? metricLabel;

  /// True while AI is actively driving (only possible with AiMode=auto or
  /// when a suggest-mode suggestion was accepted without human hand-off).
  final bool aiOwned;

  final AiAnalysis? aiAnalysis;
  final List<IncidentEvent> events;
  final List<SimilarIncident> similarIncidents;

  Duration get duration {
    final end = resolvedAt ?? DateTime.now();
    return end.difference(startedAt);
  }
}

/// AI-generated analysis attached to an incident.
///
/// Filled whenever the monitor's effective AI mode is `suggest` or `auto`.
/// In `off` mode this is never attached.
class AiAnalysis {
  const AiAnalysis({
    required this.tldr,
    required this.confidence,
    required this.trigger,
    this.evidence = const [],
    this.suggestedActions = const [],
  });

  /// One or two sentence plain-language summary.
  final String tldr;
  final AiConfidence confidence;

  /// What made the AI act on this signal.
  final AiTrigger trigger;

  final List<AiEvidence> evidence;
  final List<AiSuggestedAction> suggestedActions;
}

class AiEvidence {
  const AiEvidence({
    required this.label,
    required this.detail,
    this.metricKey,
  });

  final String label;
  final String detail;
  final String? metricKey;
}

class AiSuggestedAction {
  const AiSuggestedAction({
    required this.title,
    required this.rationale,
  });

  final String title;
  final String rationale;
}

class SimilarIncident {
  const SimilarIncident({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.resolutionNote,
  });

  final String id;
  final String title;
  final DateTime occurredAt;
  final String resolutionNote;
}

/// AI-authored suggestion that has not (yet) been promoted to an incident.
///
/// Produced only in AiMode=suggest. The user can accept (→ incident) or
/// dismiss. Never persisted in `off` mode; auto-promoted in `auto` mode.
class AiSuggestion {
  const AiSuggestion({
    required this.id,
    required this.monitorId,
    required this.suggestedTitle,
    required this.suggestedSeverity,
    required this.confidence,
    required this.tldr,
    required this.createdAt,
    this.metricKey,
  });

  final String id;
  final String monitorId;
  final String suggestedTitle;
  final IncidentSeverity suggestedSeverity;
  final AiConfidence confidence;
  final String tldr;
  final DateTime createdAt;
  final String? metricKey;
}

/// Entry in the incident timeline.
///
/// `actor == 'ai'` renders with the Uptizm AI avatar and indigo accent.
class IncidentEvent {
  const IncidentEvent({
    required this.at,
    required this.actor,
    required this.type,
    required this.message,
    this.actorLabel,
  });

  final DateTime at;

  /// `'ai'` | `'system'` | user id
  final String actor;
  final String? actorLabel;

  /// `'opened'` | `'status_changed'` | `'note'` | `'ai_suggestion'` |
  /// `'ai_auto_resolved'` | `'acknowledged'` | `'resolved'`
  final String type;
  final String message;
}
