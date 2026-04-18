import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/requests/update_appearance_request.dart';

void main() {
  group('UpdateAppearanceRequest', () {
    test('trims color and emits null logo when blank', () {
      final payload = const UpdateAppearanceRequest().validate({
        'appearance_primary_color': '  #2563EB  ',
        'appearance_logo_path': '   ',
      });

      expect(payload['appearance_primary_color'], '#2563EB');
      expect(payload.containsKey('appearance_logo_path'), isTrue);
      expect(payload['appearance_logo_path'], isNull);
    });

    test('keeps trimmed logo path when present', () {
      final payload = const UpdateAppearanceRequest().validate({
        'appearance_primary_color': '#000000',
        'appearance_logo_path': ' /u/logo.png ',
      });

      expect(payload['appearance_logo_path'], '/u/logo.png');
    });

    test('rejects missing primary color', () {
      expect(
        () => const UpdateAppearanceRequest().validate({
          'appearance_primary_color': '',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
