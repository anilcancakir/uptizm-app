import 'package:app/app/enums/ai_gate_reason.dart';
import 'package:app/app/enums/ai_mode.dart';
import 'package:app/app/enums/ai_mode_source.dart';
import 'package:app/app/models/ai_agent_run.dart';

/// Snapshot of the AI pipeline state for a single monitor, mirroring the
/// `ai` sub-object emitted by `MonitorResource` on the API. Gives the
/// monitor detail screen everything it needs to explain why the AI is or
/// is not about to run without fanning out to multiple endpoints.
///
/// Plain Dart class (not a `Model` subclass) because it is always nested
/// inside `Monitor`; follows the same `AiAnalysis` / `IncidentEvent`
/// pattern used elsewhere in the app.
class MonitorAiStatus {
  const MonitorAiStatus({
    required this.effectiveMode,
    required this.modeSource,
    required this.cooldownSeconds,
    required this.currentGate,
    this.lastRun,
    this.nextEligibleAt,
  });

  /// Mode the backend will actually apply, resolved through the monitor
  /// override + workspace default fallback. Null only when neither is set.
  final AiMode? effectiveMode;

  /// Whether [effectiveMode] came from the monitor itself, the workspace
  /// default, or nowhere at all.
  final AiModeSource modeSource;

  /// Minimum seconds that must elapse between two completed AI runs for
  /// this monitor. Already clamped to [120, 900] by the backend.
  final int cooldownSeconds;

  /// Live {@see AnomalyGate} verdict at the moment the payload was built.
  final AiGateDecision currentGate;

  /// Latest recorded run for this monitor, or null when AI has never
  /// evaluated it.
  final AiAgentRun? lastRun;

  /// ISO8601 instant when the cooldown window closes, or null when the
  /// window has already elapsed or there is no last run.
  final DateTime? nextEligibleAt;

  /// Parse the `ai` sub-object from a monitor resource payload.
  static MonitorAiStatus fromMap(Map<String, dynamic> map) {
    final rawMode = map['effective_mode'] as String?;
    final effective = rawMode == null
        ? null
        : AiMode.values.firstWhere(
            (mode) => mode.name == rawMode,
            orElse: () => AiMode.off,
          );

    return MonitorAiStatus(
      effectiveMode: effective,
      modeSource: AiModeSource.fromWire(map['mode_source'] as String?),
      cooldownSeconds: _int(map['cooldown_seconds']) ?? 120,
      currentGate: AiGateDecision.fromMap(
        _map(map['current_gate']) ?? const <String, dynamic>{},
      ),
      lastRun: _lastRun(map['last_run']),
      nextEligibleAt: _date(map['next_eligible_at']),
    );
  }

  static AiAgentRun? _lastRun(Object? raw) {
    final lastMap = _map(raw);
    if (lastMap == null) {
      return null;
    }

    // 1. Backend inlines a nested `summary` block under the last run; flatten
    //    it into structured_output so the existing AiAgentRun getters still work.
    final summary = _map(lastMap['summary']);
    final merged = <String, dynamic>{...lastMap, 'structured_output': ?summary};

    return AiAgentRun.fromMap(merged);
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static DateTime? _date(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static Map<String, dynamic>? _map(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }
}

/// Backend verdict object describing whether AI would run right now and,
/// if not, which gate short-circuited. Always paired with [MonitorAiStatus].
class AiGateDecision {
  const AiGateDecision({required this.run, required this.reason});

  final bool run;
  final AiGateReason reason;

  static AiGateDecision fromMap(Map<String, dynamic> map) {
    return AiGateDecision(
      run: map['run'] == true,
      reason: AiGateReason.fromWire(map['reason'] as String?),
    );
  }
}
