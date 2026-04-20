/// Lifecycle state of an incident.
///
/// Flow: detected -> investigating -> identified -> monitoring -> resolved.
/// `mitigated` is retained for back-compat with pre-redesign data.
enum IncidentStatus {
  detected,
  investigating,
  identified,
  monitoring,
  mitigated,
  resolved;

  String get toneKey => switch (this) {
    IncidentStatus.resolved => 'success',
    IncidentStatus.monitoring => 'info',
    _ => 'warn',
  };

  String get labelKey => 'incident.status.$wireValue';

  bool get isActive => !isTerminal;

  bool get isTerminal => this == IncidentStatus.resolved;

  /// snake_case wire value used by the API.
  String get wireValue => name;

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
      _ => IncidentStatus.detected,
    };
  }
}
