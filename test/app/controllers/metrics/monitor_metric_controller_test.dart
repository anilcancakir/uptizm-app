import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/metrics/monitor_metric_controller.dart';
import 'package:app/app/enums/metric_type.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  Map<String, dynamic>? lastQuery;
  dynamic lastData;
  final List<({String method, String url, dynamic data})> calls = [];
  final List<MagicResponse> _queue = [];
  MagicResponse _default = MagicResponse(data: {}, statusCode: 500);

  void enqueue(MagicResponse r) => _queue.add(r);
  set response(MagicResponse r) => _default = r;

  MagicResponse _record(
    String method,
    String url, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    lastMethod = method;
    lastUrl = url;
    lastData = data;
    lastQuery = query;
    calls.add((method: method, url: url, data: data));
    return _queue.isNotEmpty ? _queue.removeAt(0) : _default;
  }

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async => _record('GET', url, query: query);

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

Map<String, dynamic> _metricPayload({
  String id = 'met_1',
  String group = 'Performance',
  String label = 'Latency',
  String key = 'latency_ms',
}) => {
  'id': id,
  'monitor_id': 'mon_1',
  'group_name': group,
  'label': label,
  'key': key,
  'type': 'numeric',
  'source': 'json_path',
  'extraction_path': r'$.latency',
  'unit': 'ms',
  'threshold_direction': 'high_bad',
  'warn_bound': 200,
  'critical_bound': 500,
  'display_order': 1,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonitorMetricController', () {
    late _MockNetworkDriver driver;
    late MonitorMetricController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MonitorMetricController();
    });

    test('load GETs monitor metrics and groups by group_name', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            _metricPayload(),
            _metricPayload(
              id: 'met_2',
              group: 'Business',
              label: 'Orders',
              key: 'orders',
            ),
          ],
        },
        statusCode: 200,
      );

      await controller.load('mon_1');

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/monitors/mon_1/metrics');
      expect(controller.isSuccess, isTrue);
      expect(controller.metrics.length, 2);
      expect(controller.groups.keys, containsAll(['Performance', 'Business']));
      expect(controller.metrics.first.type, MetricType.numeric);
      expect(controller.metrics.first.warnBound, 200);
    });

    test('load emits empty state when API returns []', () async {
      driver.response = MagicResponse(data: {'data': []}, statusCode: 200);

      await controller.load('mon_1');

      expect(controller.isEmpty, isTrue);
      expect(controller.metrics, isEmpty);
    });

    test('load surfaces 404 as error state', () async {
      driver.response = MagicResponse(
        data: {'message': 'Not found'},
        statusCode: 404,
      );

      await controller.load('mon_missing');

      expect(controller.isError, isTrue);
    });

    test('store POSTs payload under nested route and reloads list', () async {
      driver.enqueue(
        MagicResponse(data: {'data': _metricPayload()}, statusCode: 201),
      );
      driver.enqueue(
        MagicResponse(
          data: {
            'data': [_metricPayload()],
          },
          statusCode: 200,
        ),
      );

      final metric = await controller.store('mon_1', {
        'group_name': 'Performance',
        'label': 'Latency',
        'key': 'latency_ms',
      });

      expect(metric, isNotNull);
      expect(metric!.id, 'met_1');
      expect(driver.lastUrl, '/monitors/mon_1/metrics');
      expect(controller.metrics.length, 1);
    });

    test('store surfaces 422 field errors without wiping list', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_metricPayload()],
        },
        statusCode: 200,
      );
      await controller.load('mon_1');
      expect(controller.metrics.length, 1);

      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'key': ['The key field is required.'],
          },
        },
        statusCode: 422,
      );

      final result = await controller.store('mon_1', {});

      expect(result, isNull);
      expect(controller.isError, isTrue);
      expect(controller.getError('key'), 'The key field is required.');
      expect(controller.metrics.length, 1);
    });

    test('update PUTs payload and reloads list', () async {
      driver.enqueue(
        MagicResponse(
          data: {'data': _metricPayload(label: 'Latency p95')},
          statusCode: 200,
        ),
      );
      driver.enqueue(
        MagicResponse(
          data: {
            'data': [_metricPayload(label: 'Latency p95')],
          },
          statusCode: 200,
        ),
      );

      final metric = await controller.update('mon_1', 'met_1', {
        'label': 'Latency p95',
      });

      expect(metric, isNotNull);
      expect(driver.lastMethod, 'GET');
      expect(controller.metrics.single.label, 'Latency p95');
    });

    test('destroy DELETEs and reloads list', () async {
      driver.enqueue(MagicResponse(data: {}, statusCode: 204));
      driver.enqueue(MagicResponse(data: {'data': []}, statusCode: 200));

      final ok = await controller.destroy('mon_1', 'met_1');

      expect(ok, isTrue);
      expect(controller.isEmpty, isTrue);
    });

    test('destroy returns false and preserves list on failure', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_metricPayload()],
        },
        statusCode: 200,
      );
      await controller.load('mon_1');

      driver.response = MagicResponse(
        data: {'message': 'Cannot delete'},
        statusCode: 403,
      );

      final ok = await controller.destroy('mon_1', 'met_1');

      expect(ok, isFalse);
      expect(controller.metrics.length, 1);
    });

    test(
      'preview POSTs rule and maps response into MetricPreviewResult',
      () async {
        driver.response = MagicResponse(
          data: {
            'status_code': 200,
            'latency_ms': 142,
            'extracted_value': '42.7',
            'type_valid': true,
            'error': null,
          },
          statusCode: 200,
        );

        final result = await controller.preview(
          'mon_1',
          source: 'json_path',
          extractionPath: 'data.latency',
          type: 'numeric',
        );

        expect(driver.lastMethod, 'POST');
        expect(driver.lastUrl, '/monitors/mon_1/metrics/preview');
        expect(driver.lastData, {
          'source': 'json_path',
          'extraction_path': 'data.latency',
          'type': 'numeric',
        });
        expect(result, isNotNull);
        expect(result!.statusCode, 200);
        expect(result.latencyMs, 142);
        expect(result.extractedValue, '42.7');
        expect(result.typeValid, isTrue);
        expect(result.error, isNull);
      },
    );

    test('preview returns null when server errors', () async {
      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );

      final result = await controller.preview(
        'mon_1',
        source: 'regex',
        extractionPath: 'x',
        type: 'string',
      );

      expect(result, isNull);
    });

    test('preview surfaces extraction error via response body', () async {
      driver.response = MagicResponse(
        data: {
          'status_code': 200,
          'latency_ms': 88,
          'extracted_value': null,
          'type_valid': false,
          'error': 'No value at path `missing`.',
        },
        statusCode: 200,
      );

      final result = await controller.preview(
        'mon_1',
        source: 'json_path',
        extractionPath: 'missing',
        type: 'numeric',
      );

      expect(result, isNotNull);
      expect(result!.extractedValue, isNull);
      expect(result.error, 'No value at path `missing`.');
    });

    test('series GETs values with range query', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            {
              'recorded_at': '2026-04-17T10:00:00Z',
              'numeric_value': 123.4,
              'string_value': null,
              'status_value': null,
              'band': 'ok',
            },
          ],
        },
        statusCode: 200,
      );

      final values = await controller.series('mon_1', 'met_1', range: '7d');

      expect(driver.lastUrl, '/monitors/mon_1/metrics/met_1/series');
      expect(driver.lastQuery, {'range': '7d'});
      expect(values.length, 1);
      expect(values.first.numericValue, 123.4);
    });

    test('reorder PUTs sequential display_order and reloads list', () async {
      driver.enqueue(MagicResponse(data: {}, statusCode: 204));
      driver.enqueue(
        MagicResponse(
          data: {
            'data': [_metricPayload()],
          },
          statusCode: 200,
        ),
      );

      final ok = await controller.reorder('mon_1', ['a', 'b', 'c']);

      expect(ok, isTrue);
      final putCall = driver.calls.firstWhere((c) => c.method == 'PUT');
      expect(putCall.url, '/monitors/mon_1/metrics/reorder');
      final order = (putCall.data as Map<String, dynamic>)['order'] as List;
      expect(order.length, 3);
      expect(order[0], {'id': 'a', 'display_order': 0});
      expect(order[2], {'id': 'c', 'display_order': 2});
      expect(driver.calls.any((c) => c.method == 'GET'), isTrue);
    });

    test('reorder returns false on non-2xx', () async {
      driver.response = MagicResponse(
        data: {'message': 'nope'},
        statusCode: 500,
      );

      final ok = await controller.reorder('mon_1', ['a']);
      expect(ok, isFalse);
    });
  });
}
