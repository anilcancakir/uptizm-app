import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/ai_gate_reason.dart';
import 'package:app/app/enums/ai_mode.dart';
import 'package:app/app/enums/ai_mode_source.dart';
import 'package:app/app/models/monitor_ai_status.dart';

void main() {
  group('MonitorAiStatus.fromMap', () {
    test('parses a fully populated backend payload', () {
      final status = MonitorAiStatus.fromMap({
        'effective_mode': 'auto',
        'mode_source': 'monitor_override',
        'cooldown_seconds': 180,
        'current_gate': {'run': false, 'reason': 'cooldown'},
        'last_run': {
          'id': 'run_1',
          'agent_name': 'AnomalyDetectorAgent',
          'status': 'completed',
          'duration_ms': 4321,
          'tokens_input': 1765,
          'tokens_output': 159,
          'cost_usd': 0.0076,
          'completed_at': '2026-04-19T12:00:00.000Z',
          'summary': {
            'anomaly_detected': true,
            'metric_key': 'status_code',
            'severity': 'critical',
            'confidence': 'high',
            'tldr': 'Down for >5 minutes',
          },
        },
        'next_eligible_at': '2026-04-19T12:03:00.000Z',
      });

      expect(status.effectiveMode, AiMode.auto);
      expect(status.modeSource, AiModeSource.monitorOverride);
      expect(status.cooldownSeconds, 180);
      expect(status.currentGate.run, isFalse);
      expect(status.currentGate.reason, AiGateReason.cooldown);
      expect(status.nextEligibleAt, isNotNull);
      expect(status.lastRun, isNotNull);
      expect(status.lastRun!.anomalyDetected, isTrue);
      expect(status.lastRun!.structuredMetricKey, 'status_code');
    });

    test('survives missing optional fields with safe fallbacks', () {
      final status = MonitorAiStatus.fromMap(const {});

      expect(status.effectiveMode, isNull);
      expect(status.modeSource, AiModeSource.none);
      expect(status.cooldownSeconds, 120);
      expect(status.currentGate.run, isFalse);
      expect(status.currentGate.reason, AiGateReason.ok);
      expect(status.lastRun, isNull);
      expect(status.nextEligibleAt, isNull);
    });

    test('unknown effective mode string falls back to off', () {
      final status = MonitorAiStatus.fromMap({'effective_mode': 'exploded'});

      expect(status.effectiveMode, AiMode.off);
    });
  });
}
