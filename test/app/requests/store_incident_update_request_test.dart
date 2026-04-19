import 'package:app/app/enums/incident_status.dart';
import 'package:app/app/requests/store_incident_update_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

void main() {
  group('StoreIncidentUpdateRequest', () {
    test('collapses status enum to snake_case wire value', () {
      final payload = const StoreIncidentUpdateRequest().validate({
        'status': IncidentStatus.inProgress,
        'body': '  working on it  ',
      });

      expect(payload['status'], 'in_progress');
      expect(payload['body'], 'working on it');
      expect(payload['deliver_notifications'], isTrue);
    });

    test('respects explicit deliver_notifications=false', () {
      final payload = const StoreIncidentUpdateRequest().validate({
        'status': 'identified',
        'body': 'root cause found',
        'deliver_notifications': false,
      });

      expect(payload['deliver_notifications'], isFalse);
    });

    test('rejects blank body', () {
      expect(
        () => const StoreIncidentUpdateRequest().validate({
          'status': 'investigating',
          'body': '   ',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects missing status', () {
      expect(
        () => const StoreIncidentUpdateRequest().validate({'body': 'x'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
