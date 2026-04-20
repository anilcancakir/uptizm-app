/// Customer-facing impact level of an incident.
///
/// Derived from the worst affected component status unless the incident's
/// `impact_override` flag is set, in which case operators pin it manually.
enum IncidentImpact {
  none,
  minor,
  major,
  critical;

  String get labelKey => 'incident.impact.$name';

  /// Monotonic weight for worst-case rollup comparisons.
  int get weight => switch (this) {
    IncidentImpact.none => 0,
    IncidentImpact.minor => 1,
    IncidentImpact.major => 2,
    IncidentImpact.critical => 3,
  };

  /// Tone key consumed by the impact badge component.
  String get toneKey => switch (this) {
    IncidentImpact.none => 'neutral',
    IncidentImpact.minor => 'warn',
    IncidentImpact.major => 'warn',
    IncidentImpact.critical => 'danger',
  };

  static IncidentImpact fromWire(Object? raw) {
    if (raw is! String) return IncidentImpact.none;
    return IncidentImpact.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => IncidentImpact.none,
    );
  }
}
