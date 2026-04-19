import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/metric_type.dart';
import 'package:app/app/enums/metric_unit.dart';
import 'package:app/app/models/monitor_metric.dart';

void main() {
  group('MonitorMetric enum cast', () {
    test('hydrates a known MetricType string', () {
      final metric = MonitorMetric.fromMap({'id': 'met_1', 'type': 'numeric'});
      expect(metric.type, MetricType.numeric);
    });

    test('returns null for unknown MetricType values', () {
      final metric = MonitorMetric.fromMap({'id': 'met_1', 'type': 'mystery'});
      expect(metric.type, isNull);
    });

    test('hydrates unit_kind wire values', () {
      final metric = MonitorMetric.fromMap({
        'id': 'met_1',
        'unit_kind': 'bytes_auto',
      });
      expect(metric.unitKind, MetricUnit.bytesAuto);
    });

    test('falls back to custom when unit_kind is absent', () {
      final metric = MonitorMetric.fromMap({'id': 'met_1'});
      expect(metric.unitKind, MetricUnit.custom);
    });
  });

  group('MonitorMetric fill hydration', () {
    test('preserves id, monitor_id, and timestamps through fill()', () {
      final metric = MonitorMetric.fromMap({
        'id': 'met_1',
        'monitor_id': 'mon_1',
        'label': 'Latency',
        'key': 'latency',
        'type': 'numeric',
        'created_at': '2026-04-18T10:00:00.000000Z',
        'updated_at': '2026-04-18T11:00:00.000000Z',
      });

      expect(metric.id, 'met_1');
      expect(metric.monitorId, 'mon_1');
      expect(metric.label, 'Latency');
      expect(metric.key, 'latency');
      expect(metric.exists, isTrue);
    });
  });
}
