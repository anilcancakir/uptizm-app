import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/monitors/monitor_series_controller.dart';

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

Map<String, dynamic> _samplePayload(String iso, int ms) => {
  'checked_at': iso,
  'response_ms': ms,
  'status': 'up',
  'region': 'eu-west',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitorSeriesController', () {
    late _MockNetworkDriver driver;
    late MonitorSeriesController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MonitorSeriesController();
    });

    test('load GETs /monitors/<id>/response-times with range query', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            _samplePayload('2026-05-19T00:00:00Z', 120),
            _samplePayload('2026-05-19T00:05:00Z', 132),
          ],
        },
        statusCode: 200,
      );

      await controller.load('mon_1', range: '7d');

      expect(driver.lastUrl, '/monitors/mon_1/response-times');
      expect(driver.lastQuery, {'range': '7d'});
      expect(controller.currentMonitorId, 'mon_1');
      expect(controller.currentRange, '7d');
      expect(controller.isSuccess, isTrue);
      expect(controller.samples, hasLength(2));
    });

    test('load defaults range to 24h when omitted', () async {
      driver.response = MagicResponse(data: {'data': []}, statusCode: 200);

      await controller.load('mon_1');

      expect(driver.lastQuery, {'range': '24h'});
      expect(controller.currentRange, '24h');
    });

    test('load emits empty state when series has no samples', () async {
      driver.response = MagicResponse(data: {'data': []}, statusCode: 200);

      await controller.load('mon_1');

      expect(controller.isEmpty, isTrue);
      expect(controller.samples, isEmpty);
    });

    test('load surfaces error state on non-2xx', () async {
      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );

      await controller.load('mon_1');

      expect(controller.isError, isTrue);
    });

    test('load skips malformed samples without failing the request', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            _samplePayload('2026-05-19T00:00:00Z', 120),
            {'response_ms': 500}, // missing checked_at -> dropped
          ],
        },
        statusCode: 200,
      );

      await controller.load('mon_1');

      expect(controller.isSuccess, isTrue);
      expect(controller.samples, hasLength(1));
    });

    test('reload before load is a no-op (no currentMonitorId)', () async {
      await controller.reload();
      expect(driver.getCallCount, 0);
    });

    test('reload swaps samples in place on success', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_samplePayload('2026-05-19T00:00:00Z', 100)],
        },
        statusCode: 200,
      );
      await controller.load('mon_1');
      expect(controller.samples, hasLength(1));

      driver.response = MagicResponse(
        data: {
          'data': [
            _samplePayload('2026-05-19T00:00:00Z', 100),
            _samplePayload('2026-05-19T00:01:00Z', 110),
          ],
        },
        statusCode: 200,
      );
      await controller.reload();

      expect(controller.samples, hasLength(2));
      expect(controller.isSuccess, isTrue);
    });

    test('reload preserves previous samples on failure', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_samplePayload('2026-05-19T00:00:00Z', 100)],
        },
        statusCode: 200,
      );
      await controller.load('mon_1');

      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );
      await controller.reload();

      expect(controller.samples, hasLength(1));
      expect(controller.isSuccess, isTrue);
    });
  });
}
