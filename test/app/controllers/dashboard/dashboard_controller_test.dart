import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/ai/ai_suggestion_controller.dart';
import 'package:app/app/controllers/dashboard/dashboard_controller.dart';
import 'package:app/app/helpers/http_cache.dart';
import 'package:app/resources/views/dashboard_view.dart';

class _MockNetworkDriver implements NetworkDriver {
  final List<String> urls = [];
  final Map<String, MagicResponse> routes = {};
  MagicResponse fallback = MagicResponse(data: {}, statusCode: 500);

  MagicResponse _record(String url) {
    urls.add(url);
    return routes[url] ?? fallback;
  }

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async => _record(url);

  @override
  Future<MagicResponse> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record(url);

  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record(url);

  @override
  Future<MagicResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async => _record(url);

  @override
  Future<MagicResponse> index(
    String resource, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => _record(resource);

  @override
  Future<MagicResponse> show(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => _record('$resource/$id');

  @override
  Future<MagicResponse> store(
    String resource,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record(resource);

  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('$resource/$id');

  @override
  Future<MagicResponse> destroy(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => _record('$resource/$id');

  @override
  Future<MagicResponse> upload(
    String url, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> files,
    Map<String, String>? headers,
  }) async => _record(url);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardController', () {
    late _MockNetworkDriver driver;
    late DashboardController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      HttpCache.reset();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = DashboardController();
    });

    test(
      'loadStats GETs /dashboard/stats and populates statsNotifier',
      () async {
        driver.routes['/dashboard/stats'] = MagicResponse(
          data: {
            'data': {
              'monitors_total': 10,
              'monitors_down': 2,
              'active_incidents': 1,
              'pending_suggestions': 3,
            },
          },
          statusCode: 200,
        );

        await controller.loadStats();

        expect(driver.urls.single, '/dashboard/stats');
        expect(controller.stats.value?.monitorsTotal, 10);
        expect(controller.stats.value?.pendingSuggestions, 3);
      },
    );

    test('loadStats surfaces 500 as null stats + error flag', () async {
      await controller.loadStats();
      expect(controller.stats.value, isNull);
      expect(controller.statsError.value, isTrue);
    });

    test('loadActiveIncidents parses list', () async {
      driver.routes['/dashboard/active-incidents'] = MagicResponse(
        data: {
          'data': [
            {
              'id': 'i1',
              'monitor_id': 'm1',
              'title': 'Pool',
              'severity': 'warn',
              'status': 'detected',
              'started_at': '2026-04-18T10:00:00Z',
              'ai_owned': false,
            },
          ],
        },
        statusCode: 200,
      );

      await controller.loadActiveIncidents();

      expect(controller.activeIncidents.value, hasLength(1));
      expect(controller.activeIncidents.value.first.id, 'i1');
    });

    test('loadMonitorsSnapshot parses list', () async {
      driver.routes['/dashboard/monitors-snapshot'] = MagicResponse(
        data: {
          'data': [
            {
              'id': 'm1',
              'name': 'Prod',
              'url': 'https://x',
              'last_status': 'up',
              'last_response_ms': 120,
            },
          ],
        },
        statusCode: 200,
      );

      await controller.loadMonitorsSnapshot();

      expect(controller.monitors.value, hasLength(1));
      expect(controller.monitors.value.first.name, 'Prod');
    });

    test('loadAiInbox parses suggestions', () async {
      driver.routes['/dashboard/ai-inbox'] = MagicResponse(
        data: {
          'data': [
            {
              'id': 's1',
              'monitor_id': 'm1',
              'title': 'Cache drift',
              'severity': 'info',
              'confidence': 'high',
              'tldr': 'x',
              'status': 'pending',
              'created_at': '2026-04-18T10:00:00Z',
            },
          ],
        },
        statusCode: 200,
      );

      await controller.loadAiInbox();

      expect(controller.suggestions.value, hasLength(1));
      expect(controller.suggestions.value.first.title, 'Cache drift');
    });

    test('loadAll fires all four endpoints in one call', () async {
      driver.fallback = MagicResponse(data: {'data': []}, statusCode: 200);
      await controller.loadAll();
      expect(
        driver.urls,
        containsAll(<String>[
          '/dashboard/stats',
          '/dashboard/active-incidents',
          '/dashboard/monitors-snapshot',
          '/dashboard/ai-inbox',
        ]),
      );
    });

    test('loadAll flips firstLoad to false after the first run', () async {
      driver.fallback = MagicResponse(data: {'data': []}, statusCode: 200);
      expect(controller.firstLoad.value, isTrue);
      await controller.loadAll();
      expect(controller.firstLoad.value, isFalse);
    });

    test('reload toggles refreshing and re-hits every endpoint', () async {
      driver.fallback = MagicResponse(data: {'data': []}, statusCode: 200);
      await controller.loadAll();
      driver.urls.clear();
      final future = controller.reload();
      expect(controller.refreshing.value, isTrue);
      await future;
      expect(controller.refreshing.value, isFalse);
      expect(driver.urls, hasLength(4));
    });

    test(
      'concurrent DashboardController.loadAiInbox + AiSuggestionController.load '
      'fires /dashboard/ai-inbox exactly once (in-flight dedup)',
      () async {
        driver.fallback = MagicResponse(data: {'data': []}, statusCode: 200);
        final suggestions = AiSuggestionController();
        final futures = Future.wait([
          controller.loadAiInbox(),
          suggestions.load(),
        ]);
        await futures;
        final aiInboxHits = driver.urls
            .where((u) => u == '/dashboard/ai-inbox')
            .length;
        expect(aiInboxHits, 1);
      },
    );

    test('index() returns DashboardView', () {
      expect(controller.index(), isA<DashboardView>());
    });
  });
}
