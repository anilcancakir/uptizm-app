/// Categorical confidence of an AI suggestion or autonomous action.
///
/// Kept coarse on purpose (3 buckets) so the UI can surface it as a colored
/// badge without the cognitive load of raw probabilities.
enum AiConfidence {
  high,
  medium,
  low;

  String get toneKey => name;
  String get labelKey => 'ai.confidence.$name';
}
