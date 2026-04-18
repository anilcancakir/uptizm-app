import 'dart:convert';

import 'package:magic/magic.dart';

import '../enums/monitor_status.dart';
import '../enums/monitor_type.dart';

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
    'incident_threshold',
    'ssl_tracking',
    'alert_on_down',
    'alert_on_warn',
  ];

  @override
  Map<String, String> get casts => {};

  @override
  String get id => getAttribute('id')?.toString() ?? '';

  String? get teamId => getAttribute('team_id')?.toString();

  String? get name => getAttribute('name') as String?;
  set name(String? value) => setAttribute('name', value);

  String? get url => getAttribute('url') as String?;
  set url(String? value) => setAttribute('url', value);

  MonitorType? get type {
    final raw = getAttribute('type') as String?;
    if (raw == null) return null;
    return MonitorType.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MonitorType.http,
    );
  }

  MonitorStatus? get status {
    final raw = getAttribute('status') as String?;
    if (raw == null) return null;
    return MonitorStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MonitorStatus.up,
    );
  }

  MonitorStatus? get lastStatus {
    final raw = getAttribute('last_status') as String?;
    if (raw == null) return null;
    return MonitorStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MonitorStatus.up,
    );
  }

  DateTime? get lastCheckedAt {
    final raw = getAttribute('last_checked_at');
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  int? get lastResponseMs => getAttribute('last_response_ms') as int?;

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

  static Future<Monitor?> find(dynamic id) =>
      InteractsWithPersistence.findById<Monitor>(id, Monitor.new);

  static Future<List<Monitor>> all() =>
      InteractsWithPersistence.allModels<Monitor>(Monitor.new);

  static Monitor fromMap(Map<String, dynamic> map) {
    return Monitor()
      ..setRawAttributes(map, sync: true)
      ..exists = map.containsKey('id');
  }

  static Monitor fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return Monitor.fromMap(map);
  }
}
