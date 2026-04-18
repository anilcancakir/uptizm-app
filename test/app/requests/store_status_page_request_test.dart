import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/requests/store_status_page_request.dart';

void main() {
  group('StoreStatusPageRequest', () {
    test('trims strings and drops blank logo_path', () {
      final payload = const StoreStatusPageRequest().validate({
        'title': '  Trust Page  ',
        'slug': '  trust  ',
        'primary_color': '#111827',
        'is_public': true,
        'monitor_ids': ['m_1'],
        'logo_path': '  ',
      });

      expect(payload['title'], 'Trust Page');
      expect(payload['slug'], 'trust');
      expect(payload['primary_color'], '#111827');
      expect(payload['is_public'], true);
      expect(payload['monitor_ids'], ['m_1']);
      expect(payload.containsKey('logo_path'), isFalse);
    });

    test('keeps trimmed logo_path when present', () {
      final payload = const StoreStatusPageRequest().validate({
        'title': 'Trust',
        'slug': 'trust',
        'primary_color': '#111827',
        'is_public': false,
        'monitor_ids': const [],
        'logo_path': ' /uploads/logo.png ',
      });

      expect(payload['logo_path'], '/uploads/logo.png');
    });

    test('rejects missing required fields', () {
      expect(
        () => const StoreStatusPageRequest().validate({
          'title': '',
          'slug': '',
          'primary_color': '',
          'is_public': false,
          'monitor_ids': const [],
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
