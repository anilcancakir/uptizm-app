/// Where the effective AI mode on a monitor came from. Lets the UI tag the
/// mode badge with "Per-monitor override" vs "From workspace default" so
/// the operator knows which knob to turn to change it.
///
/// * [monitorOverride]: monitor has its own `ai_mode`, wins.
/// * [workspaceDefault]: monitor inherits from the team's `ai_mode`.
/// * [none]: neither monitor nor workspace has configured AI.
enum AiModeSource {
  monitorOverride,
  workspaceDefault,
  none;

  String get labelKey => 'monitor.ai.status.source.$_snake';

  String get wire => _snake;

  static AiModeSource fromWire(String? wire) => switch (wire) {
    'monitor_override' => AiModeSource.monitorOverride,
    'workspace_default' => AiModeSource.workspaceDefault,
    'none' => AiModeSource.none,
    _ => AiModeSource.none,
  };

  String get _snake => switch (this) {
    AiModeSource.monitorOverride => 'monitor_override',
    AiModeSource.workspaceDefault => 'workspace_default',
    AiModeSource.none => 'none',
  };
}
