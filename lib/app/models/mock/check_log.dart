import '../../enums/monitor_status.dart';

/// Single recorded check result for a monitor.
///
/// Mock shape used by the Checks timeline: enough to render a one-line entry
/// plus a bottom-sheet detail with request/response and timing breakdown.
class CheckLog {
  const CheckLog({
    required this.id,
    required this.checkedAt,
    required this.region,
    required this.status,
    required this.statusCode,
    required this.responseMs,
    this.method = 'GET',
    this.url,
    this.requestHeaders = const {},
    this.responseHeaders = const {},
    this.responseBodyPreview,
    this.errorMessage,
    this.timing = const CheckTiming(),
  });

  final String id;
  final DateTime checkedAt;
  final String region;
  final MonitorStatus status;
  final int? statusCode;
  final int? responseMs;
  final String method;
  final String? url;
  final Map<String, String> requestHeaders;
  final Map<String, String> responseHeaders;
  final String? responseBodyPreview;
  final String? errorMessage;
  final CheckTiming timing;
}

/// Timing breakdown rendered as a segmented bar in the detail sheet.
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

  int get totalMs => dnsMs + connectMs + tlsMs + ttfbMs + downloadMs;
}
