import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/monitor_status.dart';
import 'package:app/app/enums/monitor_type.dart';
import 'package:app/app/models/monitor.dart';

void main() {
  group('Monitor enum casts', () {
    test('hydrates known enum strings into typed values', () {
      final monitor = Monitor.fromMap({
        'id': 'mon_1',
        'type': 'http',
        'status': 'up',
        'last_status': 'down',
      });

      expect(monitor.type, MonitorType.http);
      expect(monitor.status, MonitorStatus.up);
      expect(monitor.lastStatus, MonitorStatus.down);
    });

    test('returns null for unknown enum values instead of silent fallback', () {
      final monitor = Monitor.fromMap({
        'id': 'mon_1',
        'type': 'quantum-entanglement',
        'status': 'meltdown',
        'last_status': null,
      });

      expect(monitor.type, isNull);
      expect(monitor.status, isNull);
      expect(monitor.lastStatus, isNull);
    });

    test('returns null for absent enum keys', () {
      final monitor = Monitor.fromMap({'id': 'mon_1'});

      expect(monitor.type, isNull);
      expect(monitor.status, isNull);
      expect(monitor.lastStatus, isNull);
    });
  });
}
