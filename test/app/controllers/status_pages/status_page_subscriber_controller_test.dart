import 'package:app/app/controllers/status_pages/status_page_subscriber_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  MagicResponse _record(String method, String url) {
    lastMethod = method;
    lastUrl = url;
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
  }) async => _record('POST', url);

  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record('PUT', url);

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
  }) async => _record('STORE', resource);

  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('UPDATE', '$resource/$id');

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
  }) async => _record('UPLOAD', url);
}

Map<String, dynamic> _subscriber({
  String id = 'sub_1',
  String state = 'active',
}) {
  return {
    'id': id,
    'status_page_id': 'sp_1',
    'email': 'ops@example.com',
    'state': state,
    'monitor_ids': null,
    'confirmed_at': '2026-04-01T00:00:00Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatusPageSubscriberController', () {
    late _MockNetworkDriver driver;
    late StatusPageSubscriberController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = StatusPageSubscriberController();
    });

    test('load GETs /status-pages/{id}/subscribers', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_subscriber(id: 'sub_1'), _subscriber(id: 'sub_2')],
        },
        statusCode: 200,
      );

      await controller.load('sp_1');

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/status-pages/sp_1/subscribers');
      expect(controller.isSuccess, isTrue);
      expect(controller.subscribers, hasLength(2));
      expect(controller.statusPageId, 'sp_1');
    });

    test('remove optimistically drops entry and DELETEs endpoint', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_subscriber(id: 'sub_1'), _subscriber(id: 'sub_2')],
        },
        statusCode: 200,
      );
      await controller.load('sp_1');

      driver.response = MagicResponse(data: {}, statusCode: 204);
      final removed = await controller.remove('sub_1');

      expect(removed, isTrue);
      expect(driver.lastMethod, 'DELETE');
      expect(driver.lastUrl, '/status-pages/sp_1/subscribers/sub_1');
      expect(controller.subscribers.map((s) => s.id), ['sub_2']);
    });

    test('remove restores previous list when API fails', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_subscriber(id: 'sub_1'), _subscriber(id: 'sub_2')],
        },
        statusCode: 200,
      );
      await controller.load('sp_1');

      driver.response = MagicResponse(
        data: {'message': 'Boom'},
        statusCode: 500,
      );
      final removed = await controller.remove('sub_1');

      expect(removed, isFalse);
      expect(controller.subscribers.map((s) => s.id), ['sub_1', 'sub_2']);
    });

    test('remove without prior load returns false', () async {
      final removed = await controller.remove('sub_1');
      expect(removed, isFalse);
      expect(driver.lastMethod, isNull);
    });
  });
}
