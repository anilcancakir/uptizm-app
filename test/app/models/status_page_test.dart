import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/monitor_status.dart';
import 'package:app/app/models/status_page.dart';

void main() {
  group('StatusPage.fromMap', () {
    test('parses base + nested monitors', () {
      final page = StatusPage.fromMap({
        'id': 'sp_1',
        'team_id': 't1',
        'title': 'Uptizm Cloud',
        'slug': 'cloud',
        'primary_color': '#2563EB',
        'logo_path': null,
        'is_public': true,
        'monitors': [
          {
            'id': 'm1',
            'name': 'Production API',
            'url': 'https://example.com',
            'last_status': 'up',
            'display_order': 0,
          },
          {
            'id': 'm2',
            'name': 'Checkout',
            'url': 'https://example.com/checkout',
            'last_status': 'degraded',
            'display_order': 1,
            'custom_label': 'Checkout (EU)',
          },
        ],
      });

      expect(page.title, 'Uptizm Cloud');
      expect(page.slug, 'cloud');
      expect(page.subdomain, 'cloud.uptizm.com');
      expect(page.isPublic, isTrue);
      expect(page.monitors, hasLength(2));
      expect(page.monitors.last.lastStatus, MonitorStatus.degraded);
      expect(page.monitors.last.label, 'Checkout (EU)');
      expect(page.monitorIds, ['m1', 'm2']);
    });

    test('defaults primary color and treats missing monitors as empty', () {
      final page = StatusPage.fromMap({
        'id': 'sp_2',
        'title': 't',
        'slug': 's',
        'is_public': false,
      });
      expect(page.primaryColor, '#2563EB');
      expect(page.monitors, isEmpty);
    });

    test('initials fallback renders two-letter label', () {
      final one = StatusPage.fromMap({
        'id': '1',
        'title': 'Uptizm Cloud',
        'slug': 'u',
      });
      final single = StatusPage.fromMap({
        'id': '2',
        'title': 'Production',
        'slug': 'p',
      });
      expect(one.initials, 'UC');
      expect(single.initials, 'PR');
    });
  });
}
