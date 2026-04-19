import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/ai_gate_reason.dart';

void main() {
  group('AiGateReason wire mapping', () {
    test('fromWire round-trips every known code', () {
      for (final reason in AiGateReason.values) {
        expect(AiGateReason.fromWire(reason.wire), reason);
      }
    });

    test('fromWire falls back to ok on unknown input', () {
      expect(AiGateReason.fromWire(null), AiGateReason.ok);
      expect(AiGateReason.fromWire('exploded'), AiGateReason.ok);
    });

    test('allowsRun is true only for ok', () {
      expect(AiGateReason.ok.allowsRun, isTrue);
      expect(AiGateReason.cooldown.allowsRun, isFalse);
      expect(AiGateReason.modeOff.allowsRun, isFalse);
    });

    test('wire codes match backend AnomalyGate::decide contract', () {
      expect(AiGateReason.modeOff.wire, 'mode_off');
      expect(AiGateReason.belowFailThreshold.wire, 'below_fail_threshold');
      expect(AiGateReason.activeAiIncident.wire, 'active_ai_incident');
      expect(AiGateReason.stateUnchanged.wire, 'state_unchanged');
      expect(AiGateReason.cooldown.wire, 'cooldown');
      expect(AiGateReason.ok.wire, 'ok');
    });

    test(
      'i18n keys follow monitor.ai.gate.* and settings.ai.gating.* prefixes',
      () {
        expect(
          AiGateReason.cooldown.labelKey,
          'monitor.ai.gate.cooldown.title',
        );
        expect(AiGateReason.cooldown.hintKey, 'monitor.ai.gate.cooldown.hint');
        expect(
          AiGateReason.cooldown.settingsTitleKey,
          'settings.ai.gating.cooldown.title',
        );
        expect(
          AiGateReason.cooldown.settingsHintKey,
          'settings.ai.gating.cooldown.hint',
        );
      },
    );
  });
}
