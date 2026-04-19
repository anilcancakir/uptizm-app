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

    test('parses preview_token and metrics list', () {
      final page = StatusPage.fromMap({
        'id': 'sp_1',
        'title': 'Cloud',
        'slug': 'cloud',
        'is_public': false,
        'preview_token': 'tok_abc',
        'metrics': [
          {
            'id': 'k1',
            'monitor_id': 'm1',
            'key': 'latency_ms',
            'label': 'Latency',
            'type': 'numeric',
            'unit': 'ms',
            'display_order': 0,
            'latest_numeric_value': 42.5,
          },
        ],
      });
      expect(page.previewToken, 'tok_abc');
      expect(page.previewUrl, 'https://cloud.uptizm.com?preview_token=tok_abc');
      expect(page.metrics, hasLength(1));
      expect(page.metrics.first.latestNumericValue, 42.5);
      expect(page.metrics.first.displayLabel, 'Latency');
      expect(page.metricIds, ['k1']);
    });

    test('previewUrl is null when token is absent', () {
      final page = StatusPage.fromMap({
        'id': 'x',
        'title': 't',
        'slug': 's',
        'is_public': false,
      });
      expect(page.previewUrl, isNull);
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
