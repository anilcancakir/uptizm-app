import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/ai_confidence.dart';
import 'package:app/app/enums/incident_severity.dart';
import 'package:app/app/enums/incident_status.dart';
import 'package:app/app/enums/monitor_status.dart';
import 'package:app/app/models/dashboard/ai_suggestion.dart';
import 'package:app/app/models/dashboard/dashboard_stats.dart';
import 'package:app/app/models/dashboard/incident_summary.dart';
import 'package:app/app/models/dashboard/monitor_snapshot.dart';

void main() {
  group('DashboardStats.fromMap', () {
    test('parses counter fields', () {
      final s = DashboardStats.fromMap({
        'monitors_total': 12,
        'monitors_down': 1,
        'active_incidents': 3,
        'pending_suggestions': 4,
      });
      expect(s.monitorsTotal, 12);
      expect(s.monitorsDown, 1);
      expect(s.activeIncidents, 3);
      expect(s.pendingSuggestions, 4);
    });

    test('defaults missing counters to zero', () {
      final s = DashboardStats.fromMap({});
      expect(s.monitorsTotal, 0);
      expect(s.pendingSuggestions, 0);
    });
  });

  group('IncidentSummary.fromMap', () {
    test('parses the summary shape', () {
      final s = IncidentSummary.fromMap({
        'id': 'i1',
        'monitor_id': 'm1',
        'title': 'Pool degraded',
        'severity': 'warn',
        'status': 'investigating',
        'started_at': '2026-04-18T10:00:00Z',
        'ai_owned': true,
      });
      expect(s.id, 'i1');
      expect(s.severity, IncidentSeverity.warn);
      expect(s.status, IncidentStatus.investigating);
      expect(s.aiOwned, isTrue);
      expect(s.startedAt.isUtc, isTrue);
    });
  });

  group('MonitorSnapshot.fromMap', () {
    test('parses snapshot + coerces unknown status to paused', () {
      final snap = MonitorSnapshot.fromMap({
        'id': 'm1',
        'name': 'Prod API',
        'url': 'https://example.com',
        'last_status': 'down',
        'last_response_ms': 812,
        'last_checked_at': '2026-04-18T09:59:30Z',
      });
      expect(snap.name, 'Prod API');
      expect(snap.lastStatus, MonitorStatus.down);
      expect(snap.lastResponseMs, 812);
      expect(snap.lastCheckedAt, isNotNull);

      final fallback = MonitorSnapshot.fromMap({
        'id': 'm2',
        'last_status': 'xx',
      });
      expect(fallback.lastStatus, MonitorStatus.paused);
    });
  });

  group('AiSuggestion.fromMap', () {
    test('parses suggestion shape', () {
      final s = AiSuggestion.fromMap({
        'id': 's1',
        'monitor_id': 'm1',
        'title': 'Cache drift',
        'severity': 'info',
        'confidence': 'medium',
        'tldr': 'Hit ratio slipping.',
        'metric_key': 'cache_hit_ratio',
        'status': 'pending',
        'created_at': '2026-04-18T10:00:00Z',
      });
      expect(s.title, 'Cache drift');
      expect(s.severity, IncidentSeverity.info);
      expect(s.confidence, AiConfidence.medium);
      expect(s.metricKey, 'cache_hit_ratio');
      expect(s.status, 'pending');
    });
  });
}
