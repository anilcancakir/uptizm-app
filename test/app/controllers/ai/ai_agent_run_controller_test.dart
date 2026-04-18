import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/ai/ai_agent_run_controller.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  Map<String, dynamic>? lastQuery;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}
  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    lastMethod = 'GET';
    lastUrl = url;
    lastQuery = query;
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
    String r, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> show(
    String r,
    String id, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> store(
    String r,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> update(
    String r,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> destroy(
    String r,
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

Map<String, dynamic> _runPayload({String id = 'r1'}) {
  return {
    'id': id,
    'agent_name': 'triage',
    'status': 'succeeded',
    'monitor_id': 'm1',
    'provider': 'anthropic',
    'model': 'claude-haiku',
    'tokens_input': 120,
    'tokens_output': 80,
    'cost_usd': 0.001,
    'duration_ms': 850,
    'started_at': '2026-04-18T10:00:00Z',
    'completed_at': '2026-04-18T10:00:01Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiAgentRunController', () {
    late _MockNetworkDriver driver;
    late AiAgentRunController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = AiAgentRunController();
    });

    test('load GETs /ai/agent-runs and populates list', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_runPayload(id: 'r1'), _runPayload(id: 'r2')],
        },
        statusCode: 200,
      );

      await controller.load();

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/ai/agent-runs');
      expect(controller.runs, hasLength(2));
    });

    test('load passes page query when provided', () async {
      driver.response = MagicResponse(
        data: {'data': <Map<String, dynamic>>[]},
        statusCode: 200,
      );
      await controller.load(page: 2);
      expect(driver.lastQuery?['page'], 2);
    });
  });
}
