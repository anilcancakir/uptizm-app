import 'package:magic/magic.dart';

/// Form request for `POST /incidents/{id}/postmortem`.
///
/// Trims the markdown body, defaults `notify` to false so postmortem
/// publishes never fan out to subscribers by accident, and lets rules()
/// enforce the 50k markdown cap.
class PublishPostmortemRequest extends FormRequest {
  const PublishPostmortemRequest();

  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    next['body'] = (next['body'] as String?)?.trim() ?? '';

    if (!next.containsKey('notify')) {
      next['notify'] = false;
    }

    return next;
  }

  @override
  Map<String, List<Rule>> rules() => {
    'body': [Required(), Max(50000)],
    'notify': [],
  };
}
