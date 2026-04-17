/// Severity level of an incident.
///
/// Maps to Wind tone tokens (`critical` → red, `warn` → amber, `info` → blue)
/// so the same `toneKey` drives the list item, detail header, and timeline
/// dot styling via state prefixes.
enum IncidentSeverity {
  critical,
  warn,
  info;

  String get toneKey => name;
  String get labelKey => 'incident.severity.$name';
}
