import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/models/ai_agent_run.dart';

void main() {
  group('AiAgentRun.fromMap', () {
    test('parses the full resource payload including structured output', () {
      final run = AiAgentRun.fromMap({
        'id': 'run_1',
        'agent_name': 'AnomalyDetectorAgent',
        'status': 'completed',
        'monitor_id': 'mon_1',
        'incident_id': 'inc_9',
        'provider': 'anthropic',
        'model': 'claude-sonnet-4-6',
        'tokens_input': 1765,
        'tokens_output': 159,
        'cost_usd': 0.0076,
        'duration_ms': 4321,
        'input_prompt': 'last_status: down\nconsecutive_fails: 5',
        'output_text': '{"anomaly_detected": true}',
        'structured_output': {
          'anomaly_detected': true,
          'metric_key': 'status_code',
          'severity': 'critical',
          'confidence': 'high',
          'tldr': 'Down for >5 minutes',
        },
        'started_at': '2026-04-19T12:00:00.000Z',
        'completed_at': '2026-04-19T12:00:04.321Z',
      });

      expect(run.id, 'run_1');
      expect(run.agentName, 'AnomalyDetectorAgent');
      expect(run.tokensInput, 1765);
      expect(run.inputPrompt, contains('consecutive_fails: 5'));
      expect(run.outputText, contains('anomaly_detected'));
      expect(run.anomalyDetected, isTrue);
      expect(run.structuredMetricKey, 'status_code');
      expect(run.structuredSeverity, 'critical');
      expect(run.structuredConfidence, 'high');
      expect(run.structuredTldr, 'Down for >5 minutes');
    });

    test('leaves structured getters null when structured_output is absent', () {
      final run = AiAgentRun.fromMap({
        'id': 'run_empty',
        'agent_name': 'AnomalyDetectorAgent',
        'status': 'failed',
      });

      expect(run.structuredOutput, isNull);
      expect(run.anomalyDetected, isNull);
      expect(run.structuredMetricKey, isNull);
      expect(run.inputPrompt, isNull);
      expect(run.outputText, isNull);
    });

    test(
      'coerces a loosely-typed Map<dynamic, dynamic> structured payload',
      () {
        final run = AiAgentRun.fromMap({
          'id': 'run_loose',
          'agent_name': 'AnomalyDetectorAgent',
          'status': 'completed',
          // Simulate json decode produced a Map<dynamic, dynamic>.
          'structured_output': <dynamic, dynamic>{'anomaly_detected': false},
        });

        expect(run.structuredOutput, isNotNull);
        expect(run.anomalyDetected, isFalse);
      },
    );
  });
}
