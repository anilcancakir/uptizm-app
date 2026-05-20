import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/monitors/monitor_check_controller.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastUrl;
  Map<String, dynamic>? lastQuery;
  int getCallCount = 0;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    lastUrl = url;
    lastQuery = query;
    getCallCount++;
    return response;
  }

  @override
  Future<MagicResponse> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> index(
    String resource, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> show(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> store(
    String resource,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> destroy(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> upload(
    String url, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> files,
    Map<String, String>? headers,
  }) async => response;
}

Map<String, dynamic> _checkPayload(String id) => {
  'id': id,
  'monitor_id': 'mon_1',
  'region': 'eu-west',
  'status': 'up',
  'response_ms': 120,
  'checked_at': '2026-05-19T00:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitorCheckController', () {
    late _MockNetworkDriver driver;
    late MonitorCheckController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MonitorCheckController();
    });

    test('load GETs /monitors/<id>/checks with per_page in URL', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_checkPayload('chk_1'), _checkPayload('chk_2')],
        },
        statusCode: 200,
      );

      await controller.load('mon_1');

      expect(driver.lastUrl, '/monitors/mon_1/checks?per_page=20');
      expect(controller.currentMonitorId, 'mon_1');
      expect(controller.isSuccess, isTrue);
      expect(controller.checks, hasLength(2));
    });

    test('load honors custom perPage in the URL', () async {
      driver.response = MagicResponse(data: {'data': []}, statusCode: 200);

      await controller.load('mon_1', perPage: 50);

      expect(driver.lastUrl, '/monitors/mon_1/checks?per_page=50');
    });

    test('load emits empty state when no checks exist', () async {
      driver.response = MagicResponse(data: {'data': []}, statusCode: 200);

      await controller.load('mon_1');

      expect(controller.isEmpty, isTrue);
      expect(controller.checks, isEmpty);
    });

    test('load surfaces error state on non-2xx', () async {
      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );

      await controller.load('mon_1');

      expect(controller.isError, isTrue);
    });

    test('reload swaps the list in place on success', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_checkPayload('chk_1')],
        },
        statusCode: 200,
      );
      await controller.load('mon_1');
      expect(controller.checks, hasLength(1));

      driver.response = MagicResponse(
        data: {
          'data': [
            _checkPayload('chk_1'),
            _checkPayload('chk_2'),
            _checkPayload('chk_3'),
          ],
        },
        statusCode: 200,
      );
      await controller.reload('mon_1');

      expect(controller.checks, hasLength(3));
      expect(controller.isSuccess, isTrue);
    });

    test('reload leaves previous list visible on failure', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_checkPayload('chk_1')],
        },
        statusCode: 200,
      );
      await controller.load('mon_1');

      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );
      await controller.reload('mon_1');

      expect(controller.checks, hasLength(1));
      expect(controller.isSuccess, isTrue);
    });
  });
}
