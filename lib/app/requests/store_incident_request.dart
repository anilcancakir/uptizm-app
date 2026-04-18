import 'package:magic/magic.dart';

import '../enums/incident_severity.dart';

/// Form request for `POST /incidents`.
///
/// Accepts [IncidentSeverity] or wire string, trims title/description/metric_key,
/// and drops blank description/metric_key so optional fields stay unset rather
/// than serializing as empty strings.
class StoreIncidentRequest extends FormRequest {
  const StoreIncidentRequest();

  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // 1. Collapse enum instance to wire name (matches server-side cast).
    final severity = next['severity'];
    if (severity is IncidentSeverity) {
      next['severity'] = severity.name;
    }

    // 2. Trim required title; rules() handles presence.
    next['title'] = (next['title'] as String?)?.trim() ?? '';

    // 3. Optional text fields: drop when blank so the API never sees "".
    final description = (next['description'] as String?)?.trim();
    if (description == null || description.isEmpty) {
      next.remove('description');
    } else {
      next['description'] = description;
    }

    final metricKey = (next['metric_key'] as String?)?.trim();
    if (metricKey == null || metricKey.isEmpty) {
      next.remove('metric_key');
    } else {
      next['metric_key'] = metricKey;
    }

    return next;
  }

  @override
  Map<String, List<Rule>> rules() => {
    'monitor_id': [Required()],
    'title': [Required(), Max(200)],
    'severity': [Required(), InList<IncidentSeverity>(IncidentSeverity.values)],
    'notify_team': [],
    'description': [],
    'metric_key': [],
  };
}
