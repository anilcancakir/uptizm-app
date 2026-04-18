import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/status_pages/status_pages_controller.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  dynamic lastData;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  MagicResponse _record(String method, String url, [dynamic data]) {
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
  }) async => _record('POST', url, data);
  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record('PUT', url, data);
  @override
  Future<MagicResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async => _record('DELETE', url);
  @override
  Future<MagicResponse> index(
    String r, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => _record('INDEX', r);
  @override
  Future<MagicResponse> show(
    String r,
    String id, {
    Map<String, String>? headers,
  }) async => _record('SHOW', '$r/$id');
  @override
  Future<MagicResponse> store(
    String r,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('STORE', r, data);
  @override
  Future<MagicResponse> update(
    String r,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('UPDATE', '$r/$id', data);
  @override
  Future<MagicResponse> destroy(
    String r,
    String id, {
    Map<String, String>? headers,
  }) async => _record('DESTROY', '$r/$id');
  @override
  Future<MagicResponse> upload(
    String url, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> files,
    Map<String, String>? headers,
  }) async => _record('UPLOAD', url, data);
}

Map<String, dynamic> _pagePayload({
  String id = 'sp_1',
  String title = 'Cloud',
  bool isPublic = true,
}) {
  return {
    'id': id,
    'title': title,
    'slug': 'cloud',
    'primary_color': '#2563EB',
    'is_public': isPublic,
    'monitors': [],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatusPagesController', () {
    late _MockNetworkDriver driver;
    late StatusPagesController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = StatusPagesController();
    });

    test('load GETs /status-pages and populates list', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_pagePayload(id: 'sp_1'), _pagePayload(id: 'sp_2')],
        },
        statusCode: 200,
      );

      await controller.load();

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/status-pages');
      expect(controller.pages, hasLength(2));
    });

    test('loadOne hydrates detail', () async {
      driver.response = MagicResponse(
        data: {'data': _pagePayload(id: 'sp_9')},
        statusCode: 200,
      );

      await controller.loadOne('sp_9');

      expect(driver.lastUrl, '/status-pages/sp_9');
      expect(controller.detail?.id, 'sp_9');
    });

    test('store POSTs and prepends', () async {
      await controller.load();
      driver.response = MagicResponse(
        data: {'data': _pagePayload(id: 'sp_new')},
        statusCode: 201,
      );
      final result = await controller.store({
        'title': 'Cloud',
        'slug': 'cloud',
      });
      expect(result?.id, 'sp_new');
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/status-pages');
      expect(controller.pages.first.id, 'sp_new');
    });

    test('store surfaces 422 field errors', () async {
      await controller.load();
      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'slug': ['The slug field is required.'],
          },
        },
        statusCode: 422,
      );
      final result = await controller.store({'title': 'Cloud'});
      expect(result, isNull);
      expect(controller.getError('slug'), 'The slug field is required.');
    });

    test('update PUTs and replaces row', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_pagePayload(id: 'sp_1', title: 'Old')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {'data': _pagePayload(id: 'sp_1', title: 'New')},
        statusCode: 200,
      );
      final result = await controller.update('sp_1', {'title': 'New'});
      expect(result?.title, 'New');
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/status-pages/sp_1');
      expect(controller.pages.single.title, 'New');
    });

    test('destroy removes row from list on success', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_pagePayload(id: 'sp_1'), _pagePayload(id: 'sp_2')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(data: {}, statusCode: 204);
      final ok = await controller.destroy('sp_1');
      expect(ok, isTrue);
      expect(driver.lastMethod, 'DELETE');
      expect(driver.lastUrl, '/status-pages/sp_1');
      expect(controller.pages, hasLength(1));
      expect(controller.pages.single.id, 'sp_2');
    });

    test('publish POSTs and refreshes row', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_pagePayload(id: 'sp_1', isPublic: false)],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {'data': _pagePayload(id: 'sp_1', isPublic: true)},
        statusCode: 200,
      );
      final ok = await controller.publish('sp_1');
      expect(ok, isTrue);
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/status-pages/sp_1/publish');
      expect(controller.pages.single.isPublic, isTrue);
    });
  });
}
