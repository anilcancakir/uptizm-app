import 'package:magic/magic.dart';

/// Email subscriber for a public status page. Mirrors the
/// `StatusPageSubscriberResource` payload on the API side: the server
/// tracks double opt-in via [state] (`unconfirmed` → `active` after the
/// confirm link is visited), and an optional [monitorIds] filter lets the
/// viewer receive notifications only for specific components.
class StatusPageSubscriber extends Model
    with HasTimestamps, InteractsWithPersistence {
  @override
  String get table => 'status_page_subscribers';

  @override
  String get resource => 'status-page-subscribers';

  @override
  bool get incrementing => false;

  @override
  List<String> get fillable => [
    'id',
    'status_page_id',
    'email',
    'state',
    'monitor_ids',
    'confirmed_at',
    'created_at',
    'updated_at',
  ];

  @override
  String get id => getAttribute('id')?.toString() ?? '';

  String? get statusPageId => getAttribute('status_page_id')?.toString();

  String get email => getAttribute('email') as String? ?? '';

  /// One of `unconfirmed`, `active`, `unsubscribed`, `quarantined`.
  String get state => getAttribute('state') as String? ?? 'unconfirmed';

  bool get isActive => state == 'active';

  /// When null, the subscriber receives every update for the page. When
  /// non-empty, notifications are scoped to the listed monitors.
  List<String>? get monitorIds {
    final raw = getAttribute('monitor_ids');
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return null;
  }

  DateTime? get confirmedAt {
    final raw = getAttribute('confirmed_at');
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  static StatusPageSubscriber fromMap(Map<String, dynamic> map) {
    return StatusPageSubscriber()
      ..fill(map)
      ..syncOriginal()
      ..exists = map.containsKey('id');
  }
}
