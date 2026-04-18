import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/incident_severity.dart';
import 'package:app/app/enums/incident_status.dart';
import 'package:app/app/enums/signal_source.dart';
import 'package:app/app/models/incident.dart';

void main() {
  group('Incident.fromMap', () {
    test('parses the base IncidentResource shape', () {
      final incident = Incident.fromMap({
        'id': 'inc_1',
        'monitor_id': 'mon_1',
        'title': 'Pool exhausted',
        'severity': 'warn',
        'status': 'investigating',
        'signal_source': 'user_threshold',
        'trigger_ref': 'db_conn_ms',
        'metric_key': 'db_conn_ms',
        'ai_owned': true,
        'started_at': '2026-04-18T10:00:00Z',
        'resolved_at': null,
      });

      expect(incident.id, 'inc_1');
      expect(incident.monitorId, 'mon_1');
      expect(incident.title, 'Pool exhausted');
      expect(incident.severity, IncidentSeverity.warn);
      expect(incident.status, IncidentStatus.investigating);
      expect(incident.signalSource, SignalSource.userThreshold);
      expect(incident.triggerRef, 'db_conn_ms');
      expect(incident.metricKey, 'db_conn_ms');
      expect(incident.aiOwned, isTrue);
      expect(incident.startedAt.isUtc, isTrue);
      expect(incident.resolvedAt, isNull);
      expect(incident.events, isEmpty);
    });

    test('hydrates nested events when present', () {
      final incident = Incident.fromMap({
        'id': 'inc_1',
        'monitor_id': 'mon_1',
        'title': 't',
        'severity': 'info',
        'status': 'detected',
        'signal_source': 'manual',
        'started_at': '2026-04-18T10:00:00Z',
        'events': [
          {
            'at': '2026-04-18T10:01:00Z',
            'actor': 'ai',
            'event_type': 'opened',
            'message': 'Opened incident',
          },
          {
            'at': '2026-04-18T10:02:00Z',
            'actor': 'u-1',
            'actor_label': 'Anıl',
            'event_type': 'note',
            'message': 'Looking at it',
          },
        ],
      });

      expect(incident.events, hasLength(2));
      expect(incident.events.first.actor, 'ai');
      expect(incident.events.first.type, 'opened');
      expect(incident.events.last.actorLabel, 'Anıl');
    });

    test('falls back to defaults for unknown enum strings', () {
      final incident = Incident.fromMap({
        'id': 'x',
        'monitor_id': 'm',
        'title': '',
        'severity': 'not_a_severity',
        'status': 'not_a_status',
        'signal_source': 'unknown',
        'started_at': '2026-04-18T10:00:00Z',
      });

      expect(incident.severity, IncidentSeverity.info);
      expect(incident.status, IncidentStatus.detected);
      expect(incident.signalSource, SignalSource.manual);
    });
  });

  group('SimilarIncident.fromMap', () {
    test('unwraps similar_to nested shape', () {
      final similar = SimilarIncident.fromMap({
        'id': 'sim_1',
        'similarity_score': 0.82,
        'resolution_note': 'Bumped pool',
        'discovered_at': '2026-04-18T09:00:00Z',
        'similar_to': {
          'id': 'inc_old',
          'title': 'Pool exhausted last month',
          'started_at': '2026-03-10T08:00:00Z',
        },
      });

      expect(similar.id, 'inc_old');
      expect(similar.title, 'Pool exhausted last month');
      expect(similar.resolutionNote, 'Bumped pool');
      expect(similar.similarityScore, closeTo(0.82, 1e-6));
      expect(similar.occurredAt.year, 2026);
      expect(similar.occurredAt.month, 3);
    });
  });
}
