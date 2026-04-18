/// Where an incident-opening signal came from.
///
/// Uptizm unifies three paths into a single incident pipe:
/// * [userThreshold]: a metric's `MetricBand` was crossed.
/// * [aiAnomaly]: AI baseline/pattern detector fired (gated by AiMode).
/// * [manual]: a human reported it via IncidentCreateSheet.
enum SignalSource {
  userThreshold,
  aiAnomaly,
  manual;

  String get labelKey => 'signal.source.$_snake.label';
  String get descriptionKey => 'signal.source.$_snake.description';
  String get tooltipKey => 'incident.list.source_tooltip.$_snake';

  /// className tone key used with `states:` + prefixed classes.
  String get toneKey => switch (this) {
    SignalSource.userThreshold => 'threshold',
    SignalSource.aiAnomaly => 'ai',
    SignalSource.manual => 'manual',
  };

  String get _snake => switch (this) {
    SignalSource.userThreshold => 'user_threshold',
    SignalSource.aiAnomaly => 'ai_anomaly',
    SignalSource.manual => 'manual',
  };
}
