import '../enums/ai_mode.dart';

/// Workspace-level AI preferences (default mode + digest toggle).
///
/// Mirrors `AiSettingsResource` on the API. Narrow by design: per-monitor
/// overrides live on the `Monitor` row, not here.
class AiSettings {
  const AiSettings({required this.aiMode, required this.weeklyDigestEnabled});

  final AiMode aiMode;
  final bool weeklyDigestEnabled;

  /// Returns a copy with the given fields swapped.
  AiSettings copyWith({AiMode? aiMode, bool? weeklyDigestEnabled}) {
    return AiSettings(
      aiMode: aiMode ?? this.aiMode,
      weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
    );
  }

  /// Parses an `AiSettingsResource` payload. Unknown `ai_mode` values fall
  /// back to [AiMode.off] so a stale client never renders undefined state.
  static AiSettings fromMap(Map<String, dynamic> map) {
    return AiSettings(
      aiMode: _mode(map['ai_mode']),
      weeklyDigestEnabled: map['ai_weekly_digest_enabled'] == true,
    );
  }

  static AiMode _mode(Object? raw) {
    if (raw is! String) return AiMode.off;
    return AiMode.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AiMode.off,
    );
  }
}
