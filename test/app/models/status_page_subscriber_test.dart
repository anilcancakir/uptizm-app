import 'package:app/app/models/status_page_subscriber.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatusPageSubscriber.fromMap', () {
    test('parses the StatusPageSubscriberResource payload', () {
      final subscriber = StatusPageSubscriber.fromMap({
        'id': 'sub_1',
        'status_page_id': 'sp_1',
        'email': 'ops@example.com',
        'state': 'active',
        'monitor_ids': ['mon_1', 'mon_2'],
        'confirmed_at': '2026-04-18T09:00:00Z',
      });

      expect(subscriber.id, 'sub_1');
      expect(subscriber.statusPageId, 'sp_1');
      expect(subscriber.email, 'ops@example.com');
      expect(subscriber.state, 'active');
      expect(subscriber.isActive, isTrue);
      expect(subscriber.monitorIds, ['mon_1', 'mon_2']);
      expect(subscriber.confirmedAt?.year, 2026);
    });

    test('monitorIds is null when the server omits the filter', () {
      final subscriber = StatusPageSubscriber.fromMap({
        'id': 'sub_1',
        'status_page_id': 'sp_1',
        'email': 'ops@example.com',
        'state': 'unconfirmed',
      });

      expect(subscriber.monitorIds, isNull);
      expect(subscriber.isActive, isFalse);
    });
  });
}
