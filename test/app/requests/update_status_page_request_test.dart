import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/requests/update_status_page_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateStatusPageRequest', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
    });

    test('trims present strings and drops blank logo_path', () {
      final result = const UpdateStatusPageRequest().validate({
        'title': '  Cloud  ',
        'slug': '  cloud  ',
        'primary_color': '  #111111  ',
        'logo_path': '   ',
      });
      expect(result['title'], 'Cloud');
      expect(result['slug'], 'cloud');
      expect(result['primary_color'], '#111111');
      expect(result.containsKey('logo_path'), isFalse);
    });

    test('absent keys stay absent (partial patch)', () {
      final result = const UpdateStatusPageRequest().validate({
        'title': 'Only title',
      });
      expect(result.keys.toSet(), {'title'});
    });

    test('keeps logo_path when non-blank', () {
      final result = const UpdateStatusPageRequest().validate({
        'logo_path': '  logos/brand.png  ',
      });
      expect(result['logo_path'], 'logos/brand.png');
    });
  });
}
