import 'package:flutter_test/flutter_test.dart';

import 'package:app/app/enums/incident_status.dart';
import 'package:app/resources/views/monitors/monitor_incidents_tab_filter.dart';

void main() {
  group('incidentMatchesTab', () {
    test('triggered tab matches only detected status', () {
      expect(
        incidentMatchesTab(IncidentStatus.detected, IncidentTab.triggered),
        isTrue,
      );
      expect(
        incidentMatchesTab(IncidentStatus.investigating, IncidentTab.triggered),
        isFalse,
      );
      expect(
        incidentMatchesTab(IncidentStatus.resolved, IncidentTab.triggered),
        isFalse,
      );
    });

    test('acknowledged tab covers every in-progress status', () {
      // investigating, identified, monitoring, and the legacy mitigated state
      // all represent an incident an operator has picked up. They must all
      // surface under the same lane so AI-driven status transitions never
      // dead-end the row out of the working view.
      expect(
        incidentMatchesTab(
          IncidentStatus.investigating,
          IncidentTab.acknowledged,
        ),
        isTrue,
        reason: 'investigating must be in-progress',
      );
      expect(
        incidentMatchesTab(IncidentStatus.identified, IncidentTab.acknowledged),
        isTrue,
        reason: 'identified must be in-progress',
      );
      expect(
        incidentMatchesTab(IncidentStatus.monitoring, IncidentTab.acknowledged),
        isTrue,
        reason: 'monitoring must be in-progress',
      );
      expect(
        incidentMatchesTab(IncidentStatus.mitigated, IncidentTab.acknowledged),
        isTrue,
        reason: 'legacy mitigated must stay in-progress for older data',
      );
    });

    test('acknowledged tab excludes terminal and pre-pickup states', () {
      expect(
        incidentMatchesTab(IncidentStatus.detected, IncidentTab.acknowledged),
        isFalse,
        reason: 'detected belongs in the triggered lane',
      );
      expect(
        incidentMatchesTab(IncidentStatus.resolved, IncidentTab.acknowledged),
        isFalse,
        reason: 'resolved belongs in the resolved lane',
      );
    });

    test('resolved tab matches only resolved status', () {
      expect(
        incidentMatchesTab(IncidentStatus.resolved, IncidentTab.resolved),
        isTrue,
      );
      expect(
        incidentMatchesTab(IncidentStatus.detected, IncidentTab.resolved),
        isFalse,
      );
      expect(
        incidentMatchesTab(IncidentStatus.investigating, IncidentTab.resolved),
        isFalse,
      );
    });

    test('all tab matches every status', () {
      for (final status in IncidentStatus.values) {
        expect(
          incidentMatchesTab(status, IncidentTab.all),
          isTrue,
          reason: '$status must surface under all',
        );
      }
    });
  });
}
