import 'package:flutter_test/flutter_test.dart';

import 'package:app/app/enums/monitor_type.dart';
import 'package:app/app/services/monitor_form_service.dart';
import 'package:app/resources/views/components/monitors/monitor_form_shell.dart';

MonitorFormValues _values({
  HttpAuthType authType = HttpAuthType.none,
  List<MonitorFormHeader> headers = const [],
  String expectedStatus = '200',
}) {
  return MonitorFormValues(
    name: ' Checkout API ',
    url: ' https://api.example.com/health ',
    expectedStatus: expectedStatus,
    type: MonitorType.http,
    method: HttpMethod.get,
    interval: CheckInterval.m1,
    regions: {'eu-west', 'us-east'},
    sslTracking: true,
    alertOnDown: true,
    alertOnWarn: false,
    timeout: MonitorFormTimeout.s30,
    headers: headers,
    authType: authType,
    authUsername: 'u',
    authPassword: 'p',
    authToken: 't',
    authApiKeyName: 'X-API-Key',
    authApiKeyValue: 'v',
  );
}

void main() {
  final service = MonitorFormService();

  group('MonitorFormService.buildPayload (create)', () {
    test('trims name and url, serialises canonical enums', () {
      final payload = service.buildPayload(_values(), forCreate: true);

      expect(payload['name'], 'Checkout API');
      expect(payload['url'], 'https://api.example.com/health');
      expect(payload['type'], 'http');
      expect(payload['method'], 'get');
      expect(payload['check_interval'], 60);
      expect(payload['timeout_seconds'], 30);
      expect(payload['expected_status_code'], 200);
      expect(payload['regions'], containsAll(['eu-west', 'us-east']));
      expect(payload['ssl_tracking'], isTrue);
      expect(payload['alert_on_down'], isTrue);
      expect(payload['alert_on_warn'], isFalse);
    });

    test('omits request_headers and auth_config when empty / none', () {
      final payload = service.buildPayload(_values(), forCreate: true);

      expect(payload.containsKey('request_headers'), isFalse);
      expect(payload.containsKey('auth_config'), isFalse);
    });

    test('skips blank header rows', () {
      final payload = service.buildPayload(
        _values(
          headers: const [
            MonitorFormHeader(name: 'Accept', value: 'application/json'),
            MonitorFormHeader(name: '  ', value: 'skip-me'),
          ],
        ),
        forCreate: true,
      );

      expect(payload['request_headers'], {'Accept': 'application/json'});
    });

    test('emits api_key auth_config with snake-case type', () {
      final payload = service.buildPayload(
        _values(authType: HttpAuthType.apiKey),
        forCreate: true,
      );

      final auth = payload['auth_config'] as Map<String, dynamic>;
      expect(auth['type'], 'api_key');
      expect(auth['header'], 'X-API-Key');
      expect(auth['value'], 'v');
    });

    test('emits basic auth_config', () {
      final payload = service.buildPayload(
        _values(authType: HttpAuthType.basic),
        forCreate: true,
      );

      expect(payload['auth_config'], {
        'type': 'basic',
        'username': 'u',
        'password': 'p',
      });
    });

    test('emits bearer auth_config', () {
      final payload = service.buildPayload(
        _values(authType: HttpAuthType.bearer),
        forCreate: true,
      );

      expect(payload['auth_config'], {'type': 'bearer', 'token': 't'});
    });

    test('drops expected_status_code when not a valid integer', () {
      final payload = service.buildPayload(
        _values(expectedStatus: 'abc'),
        forCreate: true,
      );

      expect(payload.containsKey('expected_status_code'), isFalse);
    });
  });

  group('MonitorFormService.buildPayload (update)', () {
    test('always includes request_headers and auth_config even when empty', () {
      final payload = service.buildPayload(_values(), forCreate: false);

      expect(payload['request_headers'], <String, String>{});
      expect(payload['auth_config'], {'type': 'none'});
    });
  });
}
