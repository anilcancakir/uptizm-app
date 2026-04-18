import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/metric_type.dart';
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
  });
}
