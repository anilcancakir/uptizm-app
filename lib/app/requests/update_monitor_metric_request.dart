import 'package:magic/magic.dart';

import '../enums/metric_source.dart';
import '../enums/metric_type.dart';
import '../enums/metric_unit.dart';
import '../enums/threshold_direction.dart';
import '../models/monitor_metric.dart';

/// Form request for `PUT /monitors/{monitor}/metrics/{metric}`.
///
/// Mirrors the server-side UpdateMonitorMetricRequest at
/// `uptizm-api/app/Http/Requests/UpdateMonitorMetricRequest.php`. Behaves
/// almost identically to [StoreMonitorMetricRequest] but every required
/// rule becomes optional so partial updates (PATCH-style payloads) pass
/// validation when a field is omitted.
class UpdateMonitorMetricRequest extends FormRequest {
  const UpdateMonitorMetricRequest();

  /// Same normalization as the store request: enum collapse + trim + drop
  /// optional blanks + drop threshold fields when type is non-numeric.
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

    // 2. Trim strings, dropping when blank (treat optional on update).
    final label = (next['label'] as String?)?.trim();
    if (label == null) {
      next.remove('label');
    } else if (label.isEmpty) {
      next['label'] = '';
    } else {
      next['label'] = label;
    }

    final key = (next['key'] as String?)?.trim();
    if (key == null) {
      next.remove('key');
    } else if (key.isEmpty) {
      next['key'] = '';
    } else {
      next['key'] = key;
    }

    // 3. Drop optional blanks.
    for (final field in ['group_name', 'extraction_path', 'unit']) {
      final value = (next[field] as String?)?.trim();
      if (value == null || value.isEmpty) {
        next.remove(field);
      } else {
        next[field] = value;
      }
    }

    // 4. Threshold fields only apply to numeric metrics.
    if (next.containsKey('type') && next['type'] != MetricType.numeric.name) {
      next.remove('threshold_direction');
      next.remove('warn_bound');
      next.remove('critical_bound');
    }

    return next;
  }

  /// All fields optional — partial updates pass when a field is omitted.
  @override
  Map<String, List<Rule>> rules() => {
    'label': [Max(120)],
    'key': [Max(40)],
    'type': [InList<MetricType>(MetricType.values)],
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
