/// Lifecycle state of an incident or scheduled maintenance.
///
/// Realtime incidents flow through:
///   detected -> investigating -> identified -> monitoring -> resolved.
/// `mitigated` is retained for back-compat with pre-redesign data.
///
/// Scheduled maintenance flows through a parallel lane:
///   scheduled -> inProgress -> verifying -> completed.
///
/// Wire values use snake_case (`in_progress`); round-trip through
/// [fromWire] / [wireValue] to cross the API boundary.
enum IncidentStatus {
  detected,
  investigating,
  identified,
  monitoring,
  mitigated,
  resolved,
  scheduled,
  inProgress,
  verifying,
  completed;

  String get toneKey => switch (this) {
    IncidentStatus.resolved || IncidentStatus.completed => 'success',
    IncidentStatus.monitoring || IncidentStatus.verifying => 'info',
    IncidentStatus.scheduled => 'info',
    IncidentStatus.inProgress => 'warn',
    _ => 'warn',
  };

  String get labelKey => 'incident.status.$wireValue';

  bool get isActive => !isTerminal;

  bool get isTerminal =>
      this == IncidentStatus.resolved || this == IncidentStatus.completed;

  bool get isScheduledLane => switch (this) {
    IncidentStatus.scheduled ||
    IncidentStatus.inProgress ||
    IncidentStatus.verifying ||
    IncidentStatus.completed => true,
    _ => false,
  };

  /// snake_case wire value used by the API.
  String get wireValue => switch (this) {
    IncidentStatus.inProgress => 'in_progress',
    _ => name,
  };

  /// Parses a snake_case wire value, falling back to [detected] on unknowns.
  static IncidentStatus fromWire(Object? raw) {
    if (raw is! String) return IncidentStatus.detected;
    return switch (raw) {
      'detected' => IncidentStatus.detected,
      'investigating' => IncidentStatus.investigating,
      'identified' => IncidentStatus.identified,
      'monitoring' => IncidentStatus.monitoring,
      'mitigated' => IncidentStatus.mitigated,
      'resolved' => IncidentStatus.resolved,
      'scheduled' => IncidentStatus.scheduled,
      'in_progress' => IncidentStatus.inProgress,
      'verifying' => IncidentStatus.verifying,
      'completed' => IncidentStatus.completed,
      _ => IncidentStatus.detected,
    };
  }
}
