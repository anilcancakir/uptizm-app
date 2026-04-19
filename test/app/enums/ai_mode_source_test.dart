import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/ai_mode_source.dart';

void main() {
  group('AiModeSource wire mapping', () {
    test('fromWire round-trips every known code', () {
      for (final source in AiModeSource.values) {
        expect(AiModeSource.fromWire(source.wire), source);
      }
    });

    test('fromWire falls back to none on unknown input', () {
      expect(AiModeSource.fromWire(null), AiModeSource.none);
      expect(AiModeSource.fromWire('garbage'), AiModeSource.none);
    });

    test('labelKey follows monitor.ai.status.source.* prefix', () {
      expect(
        AiModeSource.monitorOverride.labelKey,
        'monitor.ai.status.source.monitor_override',
      );
      expect(
        AiModeSource.workspaceDefault.labelKey,
        'monitor.ai.status.source.workspace_default',
      );
      expect(AiModeSource.none.labelKey, 'monitor.ai.status.source.none');
    });
  });
}
