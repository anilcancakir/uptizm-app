import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/monitors/monitor_controller.dart';
import 'package:app/app/enums/monitor_status.dart';
import 'package:app/app/enums/monitor_type.dart';
import 'package:app/resources/views/components/monitors/monitor_form_shell.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  dynamic lastData;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  MagicResponse _record(String method, String url, {dynamic data}) {
    lastMethod = method;
    lastUrl = url;
    lastData = data;
    return response;
  }

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async => _record('GET', url);

  @override
  Future<MagicResponse> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record('POST', url, data: data);

  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record('PUT', url, data: data);

  @override
  Future<MagicResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async => _record('DELETE', url);

  @override
  Future<MagicResponse> index(
    String resource, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => _record('INDEX', resource);

  @override
  Future<MagicResponse> show(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => _record('SHOW', '$resource/$id');

  @override
  Future<MagicResponse> store(
    String resource,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('STORE', resource, data: data);

  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('UPDATE', '$resource/$id', data: data);

  @override
  Future<MagicResponse> destroy(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => _record('DESTROY', '$resource/$id');

  @override
  Future<MagicResponse> upload(
    String url, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> files,
    Map<String, String>? headers,
  }) async => _record('UPLOAD', url, data: data);
}

Map<String, dynamic> _payload() => {
  'id': 'mon_1',
  'team_id': 'team_1',
  'name': 'Checkout API',
  'type': 'http',
  'url': 'https://api.example.com/health',
  'method': 'post',
  'status': 'up',
  'request_headers': {'Accept': 'application/json'},
  'expected_status_code': 204,
  'check_interval': 300,
  'timeout_seconds': 15,
  'regions': ['eu-west-1', 'us-east-1'],
  'auth_config': {'type': 'api_key', 'header': 'X-API', 'value': 'secret'},
  'ssl_tracking': true,
  'alert_on_down': true,
  'alert_on_warn': true,
};

MonitorFormValues _values({
  HttpAuthType authType = HttpAuthType.none,
  List<MonitorFormHeader> headers = const [],
}) {
  return MonitorFormValues(
    name: ' Checkout API ',
    url: 'https://api.example.com/health',
    expectedStatus: '200',
    type: MonitorType.http,
    method: HttpMethod.get,
    interval: CheckInterval.m1,
    regions: {'eu-west-1', 'us-east-1'},
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitorController', () {
    late _MockNetworkDriver driver;
    late MonitorController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MonitorController();
    });

    test(
      'load GETs the monitor and hydrates detail + form snapshots',
      () async {
        driver.response = MagicResponse(
          data: {'data': _payload()},
          statusCode: 200,
        );

        await controller.load('mon_1');

        expect(driver.lastMethod, 'GET');
        expect(driver.lastUrl, '/monitors/mon_1');
        expect(controller.isSuccess, isTrue);

        final monitor = controller.monitor!;
        expect(monitor.id, 'mon_1');
        expect(monitor.name, 'Checkout API');
        expect(monitor.type, MonitorType.http);
        expect(monitor.status, MonitorStatus.up);
        expect(monitor.regions.length, 2);
        expect(monitor.checkInterval, 300);

        final initial = MonitorFormValues.fromMap(monitor.toMap());
        expect(initial.method, HttpMethod.post);
        expect(initial.expectedStatus, '204');
        expect(initial.interval, CheckInterval.m5);
        expect(initial.timeout, MonitorFormTimeout.s15);
        expect(initial.authType, HttpAuthType.apiKey);
        expect(initial.authApiKeyName, 'X-API');
        expect(initial.headers.single.name, 'Accept');
      },
    );

    test('load surfaces 404 as error state', () async {
      driver.response = MagicResponse(
        data: {'message': 'Not found'},
        statusCode: 404,
      );

      await controller.load('mon_missing');

      expect(controller.isError, isTrue);
      expect(controller.monitor, isNull);
    });

    test('store POSTs payload with canonical enums and trimmed name', () async {
      driver.response = MagicResponse(
        data: {
          'data': {'id': 'mon_42', 'name': 'Checkout API', 'team_id': 'team_1'},
        },
        statusCode: 201,
      );

      final monitor = await controller.store(_values());

      expect(monitor, isNotNull);
      expect(monitor!.id, 'mon_42');
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/monitors');

      final payload = driver.lastData as Map<String, dynamic>;
      expect(payload['name'], 'Checkout API');
      expect(payload['type'], 'http');
      expect(payload['method'], 'get');
      expect(payload['check_interval'], 60);
      expect(payload['timeout_seconds'], 30);
      expect(payload['expected_status_code'], 200);
      expect(payload['regions'], containsAll(['eu-west-1', 'us-east-1']));
      expect(payload.containsKey('auth_config'), isFalse);
      expect(payload.containsKey('request_headers'), isFalse);
    });

    test('store emits api_key auth_config with snake-case type', () async {
      driver.response = MagicResponse(
        data: {
          'data': {'id': 'mon_1'},
        },
        statusCode: 201,
      );

      await controller.store(_values(authType: HttpAuthType.apiKey));

      final auth =
          (driver.lastData as Map<String, dynamic>)['auth_config']
              as Map<String, dynamic>;
      expect(auth['type'], 'api_key');
      expect(auth['header'], 'X-API-Key');
      expect(auth['value'], 'v');
    });

    test('store serialises header rows into a map, skipping blanks', () async {
      driver.response = MagicResponse(
        data: {
          'data': {'id': 'mon_1'},
        },
        statusCode: 201,
      );

      await controller.store(
        _values(
          headers: const [
            MonitorFormHeader(name: 'Accept', value: 'application/json'),
            MonitorFormHeader(name: '', value: 'skip-me'),
          ],
        ),
      );

      final payload = driver.lastData as Map<String, dynamic>;
      expect(payload['request_headers'], {'Accept': 'application/json'});
    });

    test('store surfaces 422 as error state without navigating', () async {
      driver.response = MagicResponse(
        data: {'message': 'Validation failed'},
        statusCode: 422,
      );

      final monitor = await controller.store(_values());

      expect(monitor, isNull);
      expect(controller.isError, isTrue);
    });

    test('update PUTs payload and refreshes initial snapshot', () async {
      driver.response = MagicResponse(
        data: {
          'data': {..._payload(), 'name': 'Renamed'},
        },
        statusCode: 200,
      );

      final monitor = await controller.update('mon_1', _values());

      expect(monitor, isNotNull);
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/monitors/mon_1');
      final payload = driver.lastData as Map<String, dynamic>;
      expect(payload['check_interval'], 60);
      expect(payload['auth_config'], {'type': 'none'});
      expect(payload['request_headers'], <String, String>{});
      expect(controller.monitor!.name, 'Renamed');
    });

    test('update surfaces 422 field errors', () async {
      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'url': ['The url field is required.'],
          },
        },
        statusCode: 422,
      );

      final monitor = await controller.update('mon_1', _values());

      expect(monitor, isNull);
      expect(controller.isError, isTrue);
      expect(controller.getError('url'), 'The url field is required.');
    });

    test('destroy DELETEs and returns true on success', () async {
      driver.response = MagicResponse(data: {}, statusCode: 204);

      final ok = await controller.destroy('mon_1');

      expect(ok, isTrue);
      expect(driver.lastMethod, 'DELETE');
      expect(driver.lastUrl, '/monitors/mon_1');
    });

    test('destroy returns false and surfaces error on failure', () async {
      driver.response = MagicResponse(
        data: {'message': 'Cannot delete'},
        statusCode: 403,
      );

      final ok = await controller.destroy('mon_1');

      expect(ok, isFalse);
      expect(controller.isError, isTrue);
    });
  });
}
