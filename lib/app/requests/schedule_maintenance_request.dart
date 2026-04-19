import 'package:magic/magic.dart';

/// Form request for `POST /maintenance`.
///
/// Normalizes ISO timestamps, trims the title/body, and drops optional
/// auto-transition scalars when blank so the API falls back to its
/// documented defaults instead of receiving empty strings.
class ScheduleMaintenanceRequest extends FormRequest {
  const ScheduleMaintenanceRequest();

  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // 1. Coerce DateTime scheduled_* into ISO strings the API expects.
    for (final key in ['scheduled_for', 'scheduled_until']) {
      final raw = next[key];
      if (raw is DateTime) next[key] = raw.toUtc().toIso8601String();
    }

    // 2. Trim required strings; rules() enforces presence.
    next['title'] = (next['title'] as String?)?.trim() ?? '';

    final body = (next['body'] as String?)?.trim();
    if (body == null || body.isEmpty) {
      next.remove('body');
    } else {
      next['body'] = body;
    }

    // 3. Drop blank optional transition scalars.
    for (final key in [
      'auto_transition_to_maintenance_state',
      'auto_transition_to_operational_state',
    ]) {
      final raw = (next[key] as String?)?.trim();
      if (raw == null || raw.isEmpty) {
        next.remove(key);
      } else {
        next[key] = raw;
      }
    }

    return next;
  }

  @override
  Map<String, List<Rule>> rules() => {
    'title': [Required(), Max(200)],
    'scheduled_for': [Required()],
    'scheduled_until': [Required()],
    'monitor_ids': [Required()],
    'body': [],
    'auto_transition_deliver_notifications_at_start': [],
    'auto_transition_deliver_notifications_at_end': [],
    'auto_transition_to_maintenance_state': [],
    'auto_transition_to_operational_state': [],
  };
}
