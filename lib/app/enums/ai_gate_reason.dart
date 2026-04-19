/// Wire-level verdict codes emitted by the backend `AnomalyGate`. The gate
/// ladder short-circuits in this order, so every AI cycle ends with exactly
/// one of these values. The UI renders [labelKey] for a short badge and
/// [hintKey] for the explanatory line under it.
///
/// * [ok]: all gates passed, AI will evaluate the next change.
/// * [modeOff]: monitor's effective mode is off.
/// * [belowFailThreshold]: down monitor has not hit the min consecutive fails.
/// * [activeAiIncident]: an AI-owned incident is already open.
/// * [stateUnchanged]: nothing moved since the last run's prompt.
/// * [cooldown]: within the per-monitor cooldown window.
enum AiGateReason {
  ok,
  modeOff,
  belowFailThreshold,
  activeAiIncident,
  stateUnchanged,
  cooldown;

  String get labelKey => 'monitor.ai.gate.$_snake.title';
  String get hintKey => 'monitor.ai.gate.$_snake.hint';
  String get settingsTitleKey => 'settings.ai.gating.$_snake.title';
  String get settingsHintKey => 'settings.ai.gating.$_snake.hint';

  /// Wire string emitted by backend {@see AnomalyGate::decide()}.
  String get wire => _snake;

  /// Map an inbound wire value (snake_case) back to the enum. Unknown
  /// values collapse to [ok] so a backend change cannot crash the UI.
  static AiGateReason fromWire(String? wire) => switch (wire) {
    'ok' => AiGateReason.ok,
    'mode_off' => AiGateReason.modeOff,
    'below_fail_threshold' => AiGateReason.belowFailThreshold,
    'active_ai_incident' => AiGateReason.activeAiIncident,
    'state_unchanged' => AiGateReason.stateUnchanged,
    'cooldown' => AiGateReason.cooldown,
    _ => AiGateReason.ok,
  };

  /// True when this verdict means the AI is about to run on the next
  /// check change. Every other value is a skip reason.
  bool get allowsRun => this == AiGateReason.ok;

  String get _snake => switch (this) {
    AiGateReason.ok => 'ok',
    AiGateReason.modeOff => 'mode_off',
    AiGateReason.belowFailThreshold => 'below_fail_threshold',
    AiGateReason.activeAiIncident => 'active_ai_incident',
    AiGateReason.stateUnchanged => 'state_unchanged',
    AiGateReason.cooldown => 'cooldown',
  };
}
