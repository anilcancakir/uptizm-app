import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/ai/ai_suggestion_controller.dart';

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

Map<String, dynamic> _suggPayload({String id = 's1'}) {
  return {
    'id': id,
    'monitor_id': 'm1',
    'title': 'Latency rising',
    'severity': 'medium',
    'confidence': 'high',
    'tldr': 'db.conn_ms rising',
    'metric_key': 'db.conn_ms',
    'status': 'pending',
    'created_at': '2026-04-18T10:00:00Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiSuggestionController', () {
    late _MockNetworkDriver driver;
    late AiSuggestionController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = AiSuggestionController();
    });

    test('load GETs /dashboard/ai-inbox and populates list', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_suggPayload(id: 's1'), _suggPayload(id: 's2')],
        },
        statusCode: 200,
      );

      await controller.load();

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/dashboard/ai-inbox');
      expect(controller.suggestions, hasLength(2));
    });

    test('accept POSTs and removes item on success', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_suggPayload(id: 's1'), _suggPayload(id: 's2')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {
          'data': {'id': 'inc_new', 'monitor_id': 'm1', 'title': 't'},
        },
        statusCode: 201,
      );
      final incidentId = await controller.accept('s1');
      expect(incidentId, 'inc_new');
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/ai/suggestions/s1/accept');
      expect(controller.suggestions.any((s) => s.id == 's1'), isFalse);
    });

    test('skip POSTs and removes item on success', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_suggPayload(id: 's1')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {'data': _suggPayload(id: 's1')},
        statusCode: 200,
      );
      final ok = await controller.skip('s1');
      expect(ok, isTrue);
      expect(driver.lastUrl, '/ai/suggestions/s1/skip');
      expect(controller.suggestions, isEmpty);
    });

    test('accept restores list on failure', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_suggPayload(id: 's1')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(data: {}, statusCode: 409);
      final incidentId = await controller.accept('s1');
      expect(incidentId, isNull);
      expect(controller.suggestions.single.id, 's1');
    });
  });
}
