import 'package:app/app/requests/publish_postmortem_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

void main() {
  group('PublishPostmortemRequest', () {
    test('trims body and defaults notify off', () {
      final payload = const PublishPostmortemRequest().validate({
        'body': '  # Root cause  ',
      });

      expect(payload['body'], '# Root cause');
      expect(payload['notify'], isFalse);
    });

    test('honors explicit notify=true', () {
      final payload = const PublishPostmortemRequest().validate({
        'body': 'x',
        'notify': true,
      });

      expect(payload['notify'], isTrue);
    });

    test('rejects blank body', () {
      expect(
        () => const PublishPostmortemRequest().validate({'body': '   '}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
