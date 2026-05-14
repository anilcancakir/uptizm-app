import '../../../app/enums/incident_status.dart';

/// Lane filter for the Monitor → Incidents tab.
///
/// `triggered` lists fresh detections, `acknowledged` covers every in-progress
/// step (investigating → identified → monitoring, plus the legacy `mitigated`
/// state), `resolved` is terminal, and `all` is the unfiltered escape hatch.
enum IncidentTab { triggered, acknowledged, resolved, all }

/// Returns whether [status] belongs in [tab].
///
/// Pure: depends only on the incident status, so callers can also reuse it for
/// list counts without paying for object equality on the whole `Incident`.
bool incidentMatchesTab(IncidentStatus status, IncidentTab tab) {
  return switch (tab) {
    IncidentTab.triggered => status == IncidentStatus.detected,
    IncidentTab.acknowledged =>
      // Acknowledged covers the full in-progress lifecycle: an operator (or
      // AI) has picked the incident up and is moving it through investigating
      // → identified → monitoring. Legacy `mitigated` stays included so older
      // rows do not vanish from the working lane.
      status == IncidentStatus.investigating ||
          status == IncidentStatus.identified ||
          status == IncidentStatus.monitoring ||
          status == IncidentStatus.mitigated,
    IncidentTab.resolved => status == IncidentStatus.resolved,
    IncidentTab.all => true,
  };
}
