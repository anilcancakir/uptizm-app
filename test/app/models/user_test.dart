import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/models/user.dart';

void main() {
  group('User fill hydration', () {
    test('preserves id and timestamps through fill()', () {
      final user = User.fromMap({
        'id': 'usr_1',
        'name': 'Jane',
        'email': 'jane@example.com',
        'created_at': '2026-04-18T10:00:00.000000Z',
        'updated_at': '2026-04-18T11:00:00.000000Z',
      });

      expect(user.id, 'usr_1');
      expect(user.name, 'Jane');
      expect(user.email, 'jane@example.com');
      expect(user.exists, isTrue);
      expect(user.getAttribute('created_at'), isNotNull);
      expect(user.getAttribute('updated_at'), isNotNull);
    });

    test('exists stays false when id is absent', () {
      final user = User.fromMap({'name': 'Anon'});

      expect(user.exists, isFalse);
      expect(user.name, 'Anon');
    });
  });
}
