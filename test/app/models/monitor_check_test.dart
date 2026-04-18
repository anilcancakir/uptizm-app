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
}
