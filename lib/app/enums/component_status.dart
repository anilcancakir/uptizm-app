/// Public-facing status of a single monitor (component) on a status
/// page. Derived from active incidents + probe health; persisted so the
/// status page reads a single column instead of recomputing on render.
enum ComponentStatus {
  operational,
  degradedPerformance,
  partialOutage,
  majorOutage,
  underMaintenance;

  String get labelKey => 'component.status.$wireValue';

  /// Monotonic weight for worst-case rollups when a parent group needs
  /// to reflect its worst child.
  int get weight => switch (this) {
    ComponentStatus.operational => 0,
    ComponentStatus.underMaintenance => 1,
    ComponentStatus.degradedPerformance => 2,
    ComponentStatus.partialOutage => 3,
    ComponentStatus.majorOutage => 4,
  };

  String get toneKey => switch (this) {
    ComponentStatus.operational => 'success',
    ComponentStatus.underMaintenance => 'info',
    ComponentStatus.degradedPerformance => 'warn',
    ComponentStatus.partialOutage => 'warn',
    ComponentStatus.majorOutage => 'danger',
  };

  String get wireValue => switch (this) {
    ComponentStatus.operational => 'operational',
    ComponentStatus.degradedPerformance => 'degraded_performance',
    ComponentStatus.partialOutage => 'partial_outage',
    ComponentStatus.majorOutage => 'major_outage',
    ComponentStatus.underMaintenance => 'under_maintenance',
  };

  static ComponentStatus fromWire(Object? raw) {
    if (raw is! String) return ComponentStatus.operational;
    return switch (raw) {
      'operational' => ComponentStatus.operational,
      'degraded_performance' => ComponentStatus.degradedPerformance,
      'partial_outage' => ComponentStatus.partialOutage,
      'major_outage' => ComponentStatus.majorOutage,
      'under_maintenance' => ComponentStatus.underMaintenance,
      _ => ComponentStatus.operational,
    };
  }
}
