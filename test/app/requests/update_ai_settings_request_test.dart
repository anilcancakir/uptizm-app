import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/enums/ai_mode.dart';
import 'package:app/app/requests/update_ai_settings_request.dart';

void main() {
  group('UpdateAiSettingsRequest', () {
    test('accepts enum instance and serializes to wire name', () {
      final payload = const UpdateAiSettingsRequest().validate({
        'ai_mode': AiMode.suggest,
        'ai_daily_digest_enabled': true,
      });

      expect(payload['ai_mode'], 'suggest');
      expect(payload['ai_daily_digest_enabled'], true);
    });

    test('accepts wire string for ai_mode', () {
      final payload = const UpdateAiSettingsRequest().validate({
        'ai_mode': 'auto',
        'ai_daily_digest_enabled': false,
      });

      expect(payload['ai_mode'], 'auto');
    });

    test('rejects unknown ai_mode', () {
      expect(
        () => const UpdateAiSettingsRequest().validate({
          'ai_mode': 'overlord',
          'ai_daily_digest_enabled': true,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects missing required fields', () {
      expect(
        () => const UpdateAiSettingsRequest().validate({}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
