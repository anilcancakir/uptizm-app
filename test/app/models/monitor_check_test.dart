import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/monitor_status.dart';
import 'package:app/app/models/monitor_check.dart';

void main() {
  group('MonitorCheck enum cast', () {
    test('hydrates a known status string', () {
      final check = MonitorCheck.fromMap({'id': 'chk_1', 'status': 'down'});
      expect(check.status, MonitorStatus.down);
    });

    test('returns null for unknown status values', () {
      final check = MonitorCheck.fromMap({'id': 'chk_1', 'status': 'meltdown'});
      expect(check.status, isNull);
    });
  });

  group('MonitorCheck fill hydration', () {
    test('preserves id and timestamps through fill()', () {
      final check = MonitorCheck.fromMap({
        'id': 'chk_1',
        'monitor_id': 'mon_1',
        'status': 'up',
        'status_code': 200,
        'response_ms': 123,
        'checked_at': '2026-04-18T10:00:00.000000Z',
      });

      expect(check.id, 'chk_1');
      expect(check.monitorId, 'mon_1');
      expect(check.statusCode, 200);
      expect(check.responseMs, 123);
      expect(check.exists, isTrue);
    });
  });
}
