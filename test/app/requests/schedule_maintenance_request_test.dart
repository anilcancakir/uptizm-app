import 'package:app/app/requests/schedule_maintenance_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

void main() {
  group('ScheduleMaintenanceRequest', () {
    test('coerces DateTime scheduled_* into ISO UTC strings', () {
      final start = DateTime.utc(2026, 5, 1, 10);
      final end = DateTime.utc(2026, 5, 1, 11);

      final payload = const ScheduleMaintenanceRequest().validate({
        'title': '  Database upgrade  ',
        'scheduled_for': start,
        'scheduled_until': end,
        'monitor_ids': ['m_1'],
      });

      expect(payload['title'], 'Database upgrade');
      expect(payload['scheduled_for'], start.toIso8601String());
      expect(payload['scheduled_until'], end.toIso8601String());
      expect(payload['monitor_ids'], ['m_1']);
    });

    test('drops blank optional auto-transition scalars', () {
      final payload = const ScheduleMaintenanceRequest().validate({
        'title': 'x',
        'scheduled_for': DateTime.utc(2026, 5, 1),
        'scheduled_until': DateTime.utc(2026, 5, 2),
        'monitor_ids': ['m_1'],
        'auto_transition_to_maintenance_state': '   ',
        'auto_transition_to_operational_state': '',
        'body': '   ',
      });

      expect(
        payload.containsKey('auto_transition_to_maintenance_state'),
        isFalse,
      );
      expect(
        payload.containsKey('auto_transition_to_operational_state'),
        isFalse,
      );
      expect(payload.containsKey('body'), isFalse);
    });

    test('rejects missing scheduled_for / scheduled_until / monitor_ids', () {
      expect(
        () => const ScheduleMaintenanceRequest().validate({'title': 'x'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
