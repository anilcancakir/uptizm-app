import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/enums/incident_severity.dart';
import 'package:app/app/requests/store_incident_request.dart';

void main() {
  group('StoreIncidentRequest', () {
    test('trims and drops blank description/metric_key', () {
      final payload = const StoreIncidentRequest().validate({
        'monitor_id': 'm_1',
        'title': '  Outage  ',
        'severity': IncidentSeverity.warn,
        'description': '   ',
        'metric_key': null,
        'notify_team': false,
      });

      expect(payload['monitor_id'], 'm_1');
      expect(payload['title'], 'Outage');
      expect(payload['severity'], 'warn');
      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('metric_key'), isFalse);
      expect(payload['notify_team'], false);
    });

    test('keeps description and metric_key when present', () {
      final payload = const StoreIncidentRequest().validate({
        'monitor_id': 'm_1',
        'title': 'Outage',
        'severity': 'critical',
        'description': ' DB is down ',
        'metric_key': ' p95_latency ',
        'notify_team': true,
      });

      expect(payload['description'], 'DB is down');
      expect(payload['metric_key'], 'p95_latency');
      expect(payload['severity'], 'critical');
    });

    test('rejects unknown severity', () {
      expect(
        () => const StoreIncidentRequest().validate({
          'monitor_id': 'm_1',
          'title': 'x',
          'severity': 'catastrophic',
          'notify_team': true,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects missing required fields', () {
      expect(
        () => const StoreIncidentRequest().validate({}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
