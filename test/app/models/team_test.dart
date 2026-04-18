import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/models/team.dart';

void main() {
  group('Team fill hydration', () {
    test('preserves id, owner_id, and timestamps through fill()', () {
      final team = Team.fromMap({
        'id': 'tm_1',
        'name': 'Acme',
        'owner_id': 'usr_1',
        'created_at': '2026-04-18T10:00:00.000000Z',
        'updated_at': '2026-04-18T11:00:00.000000Z',
      });

      expect(team.id, 'tm_1');
      expect(team.name, 'Acme');
      expect(team.ownerId, 'usr_1');
      expect(team.exists, isTrue);
    });
  });
}
