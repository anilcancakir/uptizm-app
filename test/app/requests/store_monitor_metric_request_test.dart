import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/enums/metric_source.dart';
import 'package:app/app/enums/metric_type.dart';
import 'package:app/app/enums/metric_unit.dart';
import 'package:app/app/enums/threshold_direction.dart';
import 'package:app/app/requests/store_monitor_metric_request.dart';

void main() {
  group('StoreMonitorMetricRequest', () {
    test('collapses enums to wire strings and trims required fields', () {
      final payload = const StoreMonitorMetricRequest().validate({
        'label': '  P95 Latency  ',
        'key': '  p95_latency ',
        'type': MetricType.numeric,
        'source': MetricSource.jsonPath,
        'unit_kind': MetricUnit.millisecond,
        'threshold_direction': ThresholdDirection.highBad,
        'warn_bound': 250,
        'critical_bound': 500,
      });

      expect(payload['label'], 'P95 Latency');
      expect(payload['key'], 'p95_latency');
      expect(payload['type'], 'numeric');
      expect(payload['source'], 'json_path');
      expect(payload['unit_kind'], 'millisecond');
      expect(payload['threshold_direction'], 'high_bad');
      expect(payload['warn_bound'], 250);
      expect(payload['critical_bound'], 500);
    });

    test('drops blank optional fields (group, path, unit)', () {
      final payload = const StoreMonitorMetricRequest().validate({
        'label': 'Throughput',
        'key': 'tps',
        'type': MetricType.numeric,
        'group_name': '   ',
        'extraction_path': '',
        'unit': null,
      });

      expect(payload.containsKey('group_name'), isFalse);
      expect(payload.containsKey('extraction_path'), isFalse);
      expect(payload.containsKey('unit'), isFalse);
    });

    test('drops threshold fields when type is non-numeric', () {
      final payload = const StoreMonitorMetricRequest().validate({
        'label': 'Build Status',
        'key': 'build_status',
        'type': MetricType.status,
        'threshold_direction': ThresholdDirection.lowBad,
        'warn_bound': 1,
        'critical_bound': 0,
      });

      expect(payload['type'], 'status');
      expect(payload.containsKey('threshold_direction'), isFalse);
      expect(payload.containsKey('warn_bound'), isFalse);
      expect(payload.containsKey('critical_bound'), isFalse);
    });

    test('rejects missing required label/key/type', () {
      expect(
        () => const StoreMonitorMetricRequest().validate({}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown type', () {
      expect(
        () => const StoreMonitorMetricRequest().validate({
          'label': 'L',
          'key': 'k',
          'type': 'fictional',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts pre-collapsed enum wire strings (skip enum coercion)', () {
      final payload = const StoreMonitorMetricRequest().validate({
        'label': 'l',
        'key': 'k',
        'type': 'numeric',
        'source': 'regex',
      });

      expect(payload['type'], 'numeric');
      expect(payload['source'], 'regex');
    });
  });
}
