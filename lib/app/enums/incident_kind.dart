/// Discriminator between a realtime incident and a scheduled maintenance
/// window. Both share the `incidents` table on the API side.
enum IncidentKind {
  incident,
  maintenance;

  String get labelKey => 'incident.kind.$name';

  static IncidentKind fromWire(Object? raw) {
    if (raw is! String) return IncidentKind.incident;
    return IncidentKind.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => IncidentKind.incident,
    );
  }
}
