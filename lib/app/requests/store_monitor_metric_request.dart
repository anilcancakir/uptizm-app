import 'package:magic/magic.dart';

import '../enums/metric_source.dart';
import '../enums/metric_type.dart';
import '../enums/metric_unit.dart';
import '../enums/threshold_direction.dart';
import '../models/monitor_metric.dart';

/// Form request for `POST /monitors/{monitor}/metrics`.
///
/// Mirrors the server-side StoreMonitorMetricRequest in
/// `uptizm-api/app/Http/Requests/StoreMonitorMetricRequest.php`. Collapses
/// every enum instance to the wire string, trims required strings, and
/// drops optional fields when blank so absent and empty never both reach
/// the server.
///
/// Threshold fields (`warn_bound`, `critical_bound`, `threshold_direction`)
/// only validate when [MetricType] is `numeric`; status / string metrics
/// drop them in [prepared].
class StoreMonitorMetricRequest extends FormRequest {
  const StoreMonitorMetricRequest();

  /// Normalizes [data] before rule validation:
  /// 1. Collapse enum instances to wire strings.
  /// 2. Trim required strings.
  /// 3. Drop optional blanks so absent and empty never both reach the API.
  /// 4. Drop threshold fields when type is not `numeric`.
  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // 1. Collapse enum instances to wire values.
    final type = next['type'];
    if (type is MetricType) {
      next['type'] = type.name;
    }
    final source = next['source'];
    if (source is MetricSource) {
      next['source'] = MonitorMetric.sourceToWire(source);
    }
    final unitKind = next['unit_kind'];
    if (unitKind is MetricUnit) {
      next['unit_kind'] = unitKind.wire;
    }
    final direction = next['threshold_direction'];
    if (direction is ThresholdDirection) {
      next['threshold_direction'] = MonitorMetric.directionToWire(direction);
    }

    // 2. Trim required strings.
    next['label'] = (next['label'] as String?)?.trim() ?? '';
    next['key'] = (next['key'] as String?)?.trim() ?? '';

    // 3. Drop optional blanks.
    final group = (next['group_name'] as String?)?.trim();
    if (group == null || group.isEmpty) {
      next.remove('group_name');
    } else {
      next['group_name'] = group;
    }

    final path = (next['extraction_path'] as String?)?.trim();
    if (path == null || path.isEmpty) {
      next.remove('extraction_path');
    } else {
      next['extraction_path'] = path;
    }

    final unit = (next['unit'] as String?)?.trim();
    if (unit == null || unit.isEmpty) {
      next.remove('unit');
    } else {
      next['unit'] = unit;
    }

    // 4. Threshold fields only apply to numeric metrics.
    if (next['type'] != MetricType.numeric.name) {
      next.remove('threshold_direction');
      next.remove('warn_bound');
      next.remove('critical_bound');
    }

    return next;
  }

  /// Validation rules mirroring the server-side StoreMonitorMetricRequest.
  /// `key` regex enforces snake_case identifier shape; unique-per-monitor
  /// is enforced server-side (no client-side index).
  @override
  Map<String, List<Rule>> rules() => {
    'label': [Required(), Max(120)],
    'key': [Required(), Max(40)],
    'type': [Required(), InList<MetricType>(MetricType.values)],
    'source': [],
    'extraction_path': [],
    'unit': [],
    'unit_kind': [],
    'group_name': [],
    'threshold_direction': [],
    'warn_bound': [],
    'critical_bound': [],
    'display_order': [],
  };
}
