import '../enums/monitor_type.dart';
import '../../resources/views/components/monitors/monitor_form_shell.dart';

/// Pure data-transformation helpers for the monitor create / edit form.
///
/// Owns the [MonitorFormValues] → API payload mapping so the controller
/// stays focused on HTTP + state concerns. Stateless; safe to share as a
/// container singleton.
class MonitorFormService {
  const MonitorFormService();

  /// Builds the request body sent to `POST /monitors` (when [forCreate] is
  /// true) and `PUT /monitors/{id}` (when false).
  ///
  /// Create mode omits empty `request_headers` and `auth_config` so the
  /// validator does not reject absent rows. Update mode always emits both
  /// so the server can reconcile removals.
  Map<String, dynamic> buildPayload(
    MonitorFormValues values, {
    required bool forCreate,
  }) {
    final expected = int.tryParse(values.expectedStatus.trim());
    final headers = _headersToMap(values.headers);
    final payload = <String, dynamic>{
      'name': values.name.trim(),
      'type': values.type.name,
      'url': values.url.trim(),
      'method': values.method.name,
      'check_interval': values.interval.seconds,
      'timeout_seconds': values.timeout.seconds,
      'regions': values.regions.toList(),
      'ssl_tracking': values.sslTracking,
      'alert_on_down': values.alertOnDown,
      'alert_on_warn': values.alertOnWarn,
      'expected_status_code': ?expected,
    };

    if (forCreate) {
      if (headers.isNotEmpty) payload['request_headers'] = headers;
      if (values.authType != HttpAuthType.none) {
        payload['auth_config'] = _buildAuthConfig(values);
      }
      return payload;
    }

    payload['request_headers'] = headers;
    payload['auth_config'] = _buildAuthConfig(values);
    return payload;
  }

  Map<String, String> _headersToMap(List<MonitorFormHeader> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      final name = header.name.trim();
      if (name.isEmpty) continue;
      result[name] = header.value;
    }
    return result;
  }

  Map<String, dynamic> _buildAuthConfig(MonitorFormValues values) {
    switch (values.authType) {
      case HttpAuthType.none:
        return {'type': 'none'};
      case HttpAuthType.basic:
        return {
          'type': 'basic',
          'username': values.authUsername,
          'password': values.authPassword,
        };
      case HttpAuthType.bearer:
        return {'type': 'bearer', 'token': values.authToken};
      case HttpAuthType.apiKey:
        return {
          'type': 'api_key',
          'header': values.authApiKeyName,
          'value': values.authApiKeyValue,
        };
    }
  }
}
