import 'package:flutter_test/flutter_test.dart';
import 'package:app/app/enums/metric_unit.dart';
import 'package:app/app/helpers/metric_unit_formatter.dart';

void main() {
  group('MetricUnitFormatter.format', () {
    test('bytes_auto scales by 1024 per step', () {
      final under = MetricUnitFormatter.format(900, MetricUnit.bytesAuto);
      expect(under.value, '900');
      expect(under.suffix, 'B');

      final gb = MetricUnitFormatter.format(8327688192, MetricUnit.bytesAuto);
      expect(gb.suffix, 'GB');
      expect(gb.value, '7.76');

      final mb = MetricUnitFormatter.format(
        1024 * 1024 * 3,
        MetricUnit.bytesAuto,
      );
      expect(mb.suffix, 'MB');
      expect(mb.value, '3');
    });

    test('fixed byte variants divide by the requested scale', () {
      final mb = MetricUnitFormatter.format(
        1024 * 1024 * 2.0,
        MetricUnit.megabyte,
      );
      expect(mb.value, '2');
      expect(mb.suffix, 'MB');
    });

    test('duration_auto crosses ms/s/min/hr thresholds', () {
      expect(
        MetricUnitFormatter.format(500, MetricUnit.durationAuto).combined,
        '500 ms',
      );
      expect(
        MetricUnitFormatter.format(1500, MetricUnit.durationAuto).combined,
        '1.50 s',
      );
      expect(
        MetricUnitFormatter.format(90_000, MetricUnit.durationAuto).combined,
        '1.50 min',
      );
      expect(
        MetricUnitFormatter.format(5_400_000, MetricUnit.durationAuto).combined,
        '1.50 hr',
      );
    });

    test('percent appends % without scaling', () {
      final f = MetricUnitFormatter.format(42.5, MetricUnit.percent);
      expect(f.value, '42.50');
      expect(f.suffix, '%');
    });

    test('ratio scales 0-1 by ×100 with % suffix', () {
      final f = MetricUnitFormatter.format(0.78, MetricUnit.ratio);
      expect(f.combined, '78 %');
    });

    test('count_short collapses to k/M/B', () {
      expect(
        MetricUnitFormatter.format(950, MetricUnit.countShort).combined,
        '950',
      );
      expect(
        MetricUnitFormatter.format(1234, MetricUnit.countShort).combined,
        '1.23 k',
      );
      expect(
        MetricUnitFormatter.format(1_500_000, MetricUnit.countShort).combined,
        '1.50 M',
      );
    });

    test('custom uses the caller-supplied label', () {
      final f = MetricUnitFormatter.format(
        3.14,
        MetricUnit.custom,
        customLabel: 'req/s',
      );
      expect(f.value, '3.14');
      expect(f.suffix, 'req/s');
    });
  });
}
