import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/ai_gate_reason.dart';
import 'package:app/app/enums/ai_mode.dart';
import 'package:app/app/enums/ai_mode_source.dart';
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

  group('Monitor fill hydration', () {
    test('preserves id and timestamps through fill()', () {
      final monitor = Monitor.fromMap({
        'id': 'mon_42',
        'name': 'Home page',
        'url': 'https://example.com',
        'type': 'http',
        'created_at': '2026-04-18T10:00:00.000000Z',
        'updated_at': '2026-04-18T11:00:00.000000Z',
      });

      expect(monitor.id, 'mon_42');
      expect(monitor.name, 'Home page');
      expect(monitor.exists, isTrue);
      expect(monitor.getAttribute('created_at'), isNotNull);
      expect(monitor.getAttribute('updated_at'), isNotNull);
    });

    test('exists stays false when id is absent', () {
      final monitor = Monitor.fromMap({
        'name': 'Draft',
        'url': 'https://draft.local',
      });

      expect(monitor.exists, isFalse);
      expect(monitor.name, 'Draft');
    });
  });

  group('Monitor.aiStatus', () {
    test('parses the embedded ai sub-object into MonitorAiStatus', () {
      final monitor = Monitor.fromMap({
        'id': 'mon_1',
        'ai_mode': 'auto',
        'ai': {
          'effective_mode': 'auto',
          'mode_source': 'monitor_override',
          'cooldown_seconds': 180,
          'current_gate': {'run': false, 'reason': 'cooldown'},
          'last_run': null,
          'next_eligible_at': null,
        },
      });

      final status = monitor.aiStatus;
      expect(status, isNotNull);
      expect(status!.effectiveMode, AiMode.auto);
      expect(status.modeSource, AiModeSource.monitorOverride);
      expect(status.cooldownSeconds, 180);
      expect(status.currentGate.reason, AiGateReason.cooldown);
    });

    test('returns null when the payload omits the ai key', () {
      final monitor = Monitor.fromMap({'id': 'mon_2', 'ai_mode': 'off'});

      expect(monitor.aiStatus, isNull);
    });
  });
}
