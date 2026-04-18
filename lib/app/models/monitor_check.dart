import 'package:magic/magic.dart';

import '../enums/monitor_status.dart';

/// One probe row returned by GET /monitors/{id}/checks. Read-only: the
/// app never writes check rows, they always land via the relay worker
/// pipeline on the API side.
class MonitorCheck extends Model {
  @override
  String get table => 'monitor_checks';

  @override
  String get resource => 'monitor_checks';

  @override
  bool get incrementing => false;

  @override
  List<String> get fillable => const [
    'id',
    'monitor_id',
    'region',
    'checked_at',
    'status',
    'status_code',
    'response_ms',
    'error_message',
    'method',
    'url',
    'response_body_preview',
    'request_headers',
    'response_headers',
    'timing',
    'created_at',
    'updated_at',
  ];

  @override
  Map<String, dynamic> get casts => {'status': EnumCast(MonitorStatus.values)};

  @override
  String get id => getAttribute('id')?.toString() ?? '';

  String? get monitorId => getAttribute('monitor_id')?.toString();
  String? get region => getAttribute('region') as String?;

  DateTime? get checkedAt {
    final raw = getAttribute('checked_at');
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  MonitorStatus? get status => getAttribute('status') as MonitorStatus?;

  int? get statusCode => getAttribute('status_code') as int?;
  int? get responseMs => getAttribute('response_ms') as int?;
  String? get errorMessage => getAttribute('error_message') as String?;
  String? get method => getAttribute('method') as String?;
  String? get url => getAttribute('url') as String?;
  String? get responseBodyPreview =>
      getAttribute('response_body_preview') as String?;

  Map<String, String> get requestHeaders =>
      _stringMap(getAttribute('request_headers'));
  Map<String, String> get responseHeaders =>
      _stringMap(getAttribute('response_headers'));

  CheckTiming get timing {
    final raw = getAttribute('timing');
    if (raw is! Map) return const CheckTiming();
    int pick(String key) {
      final v = raw[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return CheckTiming(
      dnsMs: pick('dns_ms'),
      connectMs: pick('connect_ms'),
      tlsMs: pick('tls_ms'),
      ttfbMs: pick('ttfb_ms'),
      downloadMs: pick('download_ms'),
    );
  }

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (k is String && v != null) out[k] = v.toString();
    });
    return out;
  }

  /// Builds a [MonitorCheck] from a `MonitorCheckResource` payload.
  static MonitorCheck fromMap(Map<String, dynamic> map) {
    return MonitorCheck()
      ..fill(map)
      ..syncOriginal()
      ..exists = map.containsKey('id');
  }
}

/// Timing breakdown used by the check detail sheet segmented bar.
class CheckTiming {
  const CheckTiming({
    this.dnsMs = 0,
    this.connectMs = 0,
    this.tlsMs = 0,
    this.ttfbMs = 0,
    this.downloadMs = 0,
  });

  final int dnsMs;
  final int connectMs;
  final int tlsMs;
  final int ttfbMs;
  final int downloadMs;

  /// Sum of each phase. Used as the denominator when rendering the
  /// segmented timing bar so each phase maps to a proportional width.
  int get totalMs => dnsMs + connectMs + tlsMs + ttfbMs + downloadMs;
}
