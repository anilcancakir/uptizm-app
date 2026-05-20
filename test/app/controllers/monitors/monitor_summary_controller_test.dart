import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/monitors/monitor_summary_controller.dart';

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

Map<String, dynamic> _summaryPayload({
  String range = '24h',
  double uptime = 0.997,
  int? avg = 185,
  int incidents = 3,
}) => {
  'range': range,
  'uptime_ratio': uptime,
  'avg_response_ms': avg,
  'incident_count': incidents,
  'mttr_seconds': 240,
  'previous_uptime_ratio': 0.992,
  'previous_avg_response_ms': 200,
  'previous_incident_count': 5,
  'previous_mttr_seconds': 320,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitorSummaryController', () {
    late _MockNetworkDriver driver;
    late MonitorSummaryController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MonitorSummaryController();
    });

    test('load GETs /monitors/<id>/summary with range query', () async {
      driver.response = MagicResponse(
        data: {'data': _summaryPayload(range: '7d')},
        statusCode: 200,
      );

      await controller.load('mon_1', range: '7d');

      expect(driver.lastUrl, '/monitors/mon_1/summary');
      expect(driver.lastQuery, {'range': '7d'});
      expect(controller.currentMonitorId, 'mon_1');
      expect(controller.currentRange, '7d');
      expect(controller.isSuccess, isTrue);
      expect(controller.summary?.range, '7d');
      expect(controller.summary?.uptimeRatio, 0.997);
      expect(controller.summary?.incidentCount, 3);
    });

    test('load defaults range to 24h when omitted', () async {
      driver.response = MagicResponse(
        data: {'data': _summaryPayload()},
        statusCode: 200,
      );

      await controller.load('mon_1');

      expect(driver.lastQuery, {'range': '24h'});
      expect(controller.currentRange, '24h');
    });

    test('load surfaces error state on non-2xx', () async {
      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );

      await controller.load('mon_1');

      expect(controller.isError, isTrue);
    });

    test('load surfaces error when data envelope is missing', () async {
      driver.response = MagicResponse(data: {'data': null}, statusCode: 200);

      await controller.load('mon_1');

      expect(controller.isError, isTrue);
    });

    test('reload before load is a no-op (no currentMonitorId)', () async {
      await controller.reload();
      expect(driver.getCallCount, 0);
    });

    test('reload swaps the summary in place on success', () async {
      driver.response = MagicResponse(
        data: {'data': _summaryPayload(uptime: 0.99, incidents: 1)},
        statusCode: 200,
      );
      await controller.load('mon_1');
      expect(controller.summary?.incidentCount, 1);

      driver.response = MagicResponse(
        data: {'data': _summaryPayload(uptime: 0.995, incidents: 4)},
        statusCode: 200,
      );
      await controller.reload();

      expect(controller.summary?.incidentCount, 4);
      expect(controller.summary?.uptimeRatio, 0.995);
      expect(controller.isSuccess, isTrue);
    });

    test('reload preserves last-good summary on failure', () async {
      driver.response = MagicResponse(
        data: {'data': _summaryPayload(incidents: 7)},
        statusCode: 200,
      );
      await controller.load('mon_1');

      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );
      await controller.reload();

      expect(controller.summary?.incidentCount, 7);
      expect(controller.isSuccess, isTrue);
    });
  });
}
