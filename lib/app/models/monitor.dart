import 'dart:convert';

import 'package:magic/magic.dart';

import '../enums/monitor_status.dart';
import '../enums/monitor_type.dart';
import 'monitor_ai_status.dart';

/// Monitor model.
///
/// Represents a website/endpoint probe owned by the current team. The
/// wire format is defined by `MonitorResource` on the API; enum fields
/// are exchanged as their string/int `value`, not the PHP case name.
class Monitor extends Model with HasTimestamps, InteractsWithPersistence {
  @override
  String get table => 'monitors';

  @override
  String get resource => 'monitors';

  @override
  bool get incrementing => false;

  @override
  List<String> get fillable => [
    'id',
    'name',
    'type',
    'url',
    'method',
    'request_headers',
    'request_body',
    'expected_status_code',
    'check_interval',
    'timeout_seconds',
    'regions',
    'auth_config',
    'assertion_rules',
    'ai_mode',
    'ai',
    'incident_threshold',
    'ssl_tracking',
    'alert_on_down',
    'alert_on_warn',
    'team_id',
    'status',
    'last_status',
    'last_checked_at',
    'last_response_ms',
    'created_at',
    'updated_at',
  ];

  @override
  Map<String, dynamic> get casts => {
    'type': EnumCast(MonitorType.values),
    'status': EnumCast(MonitorStatus.values),
    'last_status': EnumCast(MonitorStatus.values),
  };

  @override
  String get id => getAttribute('id')?.toString() ?? '';

  String? get teamId => getAttribute('team_id')?.toString();

  String? get name => getAttribute('name') as String?;
  set name(String? value) => setAttribute('name', value);

  String? get url => getAttribute('url') as String?;
  set url(String? value) => setAttribute('url', value);

  MonitorType? get type => getAttribute('type') as MonitorType?;
  MonitorStatus? get status => getAttribute('status') as MonitorStatus?;
  MonitorStatus? get lastStatus =>
      getAttribute('last_status') as MonitorStatus?;

  DateTime? get lastCheckedAt {
    final raw = getAttribute('last_checked_at');
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  int? get lastResponseMs => getAttribute('last_response_ms') as int?;

  /// Parsed AI status block embedded by `MonitorResource` under the `ai`
  /// key. Null only when the backend omits the field (older payload or a
  /// locally-constructed monitor); callers should fall back to the
  /// standalone `ai_mode` scalar when that happens.
  MonitorAiStatus? get aiStatus {
    final raw = getAttribute('ai');
    if (raw is Map<String, dynamic>) return MonitorAiStatus.fromMap(raw);
    if (raw is Map) {
      return MonitorAiStatus.fromMap(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return null;
  }

  int? get checkInterval => getAttribute('check_interval') as int?;
  int? get timeoutSeconds => getAttribute('timeout_seconds') as int?;
  int? get expectedStatusCode => getAttribute('expected_status_code') as int?;
  bool get sslTracking => getAttribute('ssl_tracking') == true;
  bool get alertOnDown => getAttribute('alert_on_down') == true;
  bool get alertOnWarn => getAttribute('alert_on_warn') == true;

  String? get methodRaw => getAttribute('method') as String?;

  List<String> get regions {
    final raw = getAttribute('regions');
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  Map<String, String> get requestHeaders {
    final raw = getAttribute('request_headers');
    if (raw is Map) {
      return {
        for (final e in raw.entries)
          e.key.toString(): e.value?.toString() ?? '',
      };
    }
    return const {};
  }

  Map<String, dynamic> get authConfig {
    final raw = getAttribute('auth_config');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  /// Hybrid lookup: tries the local SQLite cache first, then falls back to
  /// `GET /monitors/{id}`. See `InteractsWithPersistence.findById`.
  static Future<Monitor?> find(dynamic id) =>
      InteractsWithPersistence.findById<Monitor>(id, Monitor.new);

  /// Loads every monitor from the local cache, populating from API when empty.
  static Future<List<Monitor>> all() =>
      InteractsWithPersistence.allModels<Monitor>(Monitor.new);

  /// Builds a [Monitor] from a `MonitorResource` map. `exists` flips true
  /// when an `id` is present so subsequent `save()` calls hit update, not
  /// insert.
  static Monitor fromMap(Map<String, dynamic> map) {
    return Monitor()
      ..fill(map)
      ..syncOriginal()
      ..exists = map.containsKey('id');
  }

  /// Convenience constructor for inbound broadcast payloads that arrive as
  /// raw JSON strings.
  static Monitor fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return Monitor.fromMap(map);
  }
}
