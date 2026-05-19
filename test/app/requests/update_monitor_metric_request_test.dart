import 'package:flutter_test/flutter_test.dart';

import 'package:app/app/enums/metric_type.dart';
import 'package:app/app/enums/threshold_direction.dart';
import 'package:app/app/requests/update_monitor_metric_request.dart';

void main() {
  group('UpdateMonitorMetricRequest', () {
    test('accepts partial payload with only label set', () {
      final payload = const UpdateMonitorMetricRequest().validate({
        'label': '  Renamed  ',
      });

      expect(payload['label'], 'Renamed');
      expect(payload.containsKey('key'), isFalse);
      expect(payload.containsKey('type'), isFalse);
    });

    test(
      'drops threshold fields when type explicitly switched to non-numeric',
      () {
        final payload = const UpdateMonitorMetricRequest().validate({
          'type': MetricType.string,
          'threshold_direction': ThresholdDirection.highBad,
          'warn_bound': 100,
        });

        expect(payload['type'], 'string');
        expect(payload.containsKey('threshold_direction'), isFalse);
        expect(payload.containsKey('warn_bound'), isFalse);
      },
    );

    test('keeps threshold fields when type stays numeric', () {
      final payload = const UpdateMonitorMetricRequest().validate({
        'type': MetricType.numeric,
        'warn_bound': 250,
        'critical_bound': 500,
      });

      expect(payload['warn_bound'], 250);
      expect(payload['critical_bound'], 500);
    });

    test('keeps threshold fields when type is omitted (partial update)', () {
      final payload = const UpdateMonitorMetricRequest().validate({
        'warn_bound': 999,
      });

      expect(payload['warn_bound'], 999);
    });

    test('drops blank optional strings', () {
      final payload = const UpdateMonitorMetricRequest().validate({
        'group_name': '   ',
        'extraction_path': '',
        'unit': null,
      });

      expect(payload.containsKey('group_name'), isFalse);
      expect(payload.containsKey('extraction_path'), isFalse);
      expect(payload.containsKey('unit'), isFalse);
    });
  });
}
