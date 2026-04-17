/// Lifecycle state of an incident.
///
/// `detected` → `investigating` → `mitigated` → `resolved`. Intermediate
/// states mirror the Statuspage flow and let teams communicate progress
/// without forcing a full resolution before work is done.
enum IncidentStatus {
  detected,
  investigating,
  mitigated,
  resolved;

  String get toneKey => name;
  String get labelKey => 'incident.status.$name';

  bool get isActive => this != IncidentStatus.resolved;
}
