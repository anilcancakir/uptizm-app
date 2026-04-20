/// Discriminator flag on an incident row. Kept as an enum for future
/// incident flavors without reshaping the column.
enum IncidentKind {
  incident;

  String get labelKey => 'incident.kind.$name';

  static IncidentKind fromWire(Object? raw) => IncidentKind.incident;
}
