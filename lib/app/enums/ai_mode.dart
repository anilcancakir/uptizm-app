/// How much authority the AI has for a given monitor.
///
/// * `off`: model does nothing.
/// * `suggest`: model writes suggestions, humans act.
/// * `auto`: model opens / updates / resolves incidents on its own.
enum AiMode {
  off,
  suggest,
  auto;

  String get toneKey => name;
  String get labelKey => 'ai.mode.$name';
  String get descriptionKey => 'ai.mode_description.$name';
}
