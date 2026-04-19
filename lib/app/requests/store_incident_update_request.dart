import 'package:magic/magic.dart';

import '../enums/incident_status.dart';

/// Form request for `POST /incidents/{id}/updates`.
///
/// Accepts an [IncidentStatus] or wire string, trims the markdown body,
/// and defaults `deliver_notifications` to true when omitted so the
/// subscriber fan-out stays the safe default.
class StoreIncidentUpdateRequest extends FormRequest {
  const StoreIncidentUpdateRequest();

  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // 1. Collapse status enum to its snake_case wire value.
    final status = next['status'];
    if (status is IncidentStatus) {
      next['status'] = status.wireValue;
    }

    // 2. Trim required body; rules() handles presence and length.
    next['body'] = (next['body'] as String?)?.trim() ?? '';

    // 3. Default notify flag when caller omits it.
    if (!next.containsKey('deliver_notifications')) {
      next['deliver_notifications'] = true;
    }

    return next;
  }

  @override
  Map<String, List<Rule>> rules() => {
    'status': [Required()],
    'body': [Required(), Max(10000)],
    'deliver_notifications': [],
    'affected_components': [],
  };
}
