/// What made the AI act on a signal.
///
/// Used inside [AiAnalysis.trigger]. Replaces the previous free-form string.
enum AiTrigger {
  /// The metric's user-set warn/critical band was crossed.
  threshold,

  /// AI baseline/anomaly detector fired.
  anomaly,

  /// A user-defined rule (rule editor) matched. Placeholder for now.
  rule,

  /// Human reported the incident; AI is assisting only.
  manualAssist;

  String get labelKey => 'ai.trigger.$_snake';

  String get _snake => switch (this) {
        AiTrigger.threshold => 'threshold',
        AiTrigger.anomaly => 'anomaly',
        AiTrigger.rule => 'rule',
        AiTrigger.manualAssist => 'manual_assist',
      };
}
