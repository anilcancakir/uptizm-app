import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/helpers/http_cache.dart';

/// Driver that never auto-resolves. Each GET returns a future backed by a
/// `Completer`, which the test controls explicitly so we can observe what
/// happens while a request is "in flight".
class _ControlledNetworkDriver implements NetworkDriver {
  int fireCount = 0;
  final List<Completer<MagicResponse>> pending = [];

  void resolveAll({Map<String, dynamic>? data, int statusCode = 200}) {
    for (final c in pending) {
      c.complete(MagicResponse(data: data ?? const {}, statusCode: statusCode));
    }
    pending.clear();
  }

  void failAll() {
    for (final c in pending) {
      c.complete(MagicResponse(data: const {}, statusCode: 500));
    }
    pending.clear();
  }

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    fireCount++;
    final completer = Completer<MagicResponse>();
    pending.add(completer);
    return completer.future;
  }

  // Remaining methods unused; fallback to 500.
  @override
  Future<MagicResponse> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> index(
    String resource, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> show(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> store(
    String resource,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> destroy(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);

  @override
  Future<MagicResponse> upload(
    String url, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> files,
    Map<String, String>? headers,
  }) async => MagicResponse(data: const {}, statusCode: 500);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpCache', () {
    late _ControlledNetworkDriver driver;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      HttpCache.reset();
      driver = _ControlledNetworkDriver();
      Magic.singleton('network', () => driver);
    });

    test(
      'coalesces two concurrent GETs on the same URL into one fire',
      () async {
        final a = HttpCache.get('/dashboard/ai-inbox');
        final b = HttpCache.get('/dashboard/ai-inbox');

        expect(driver.fireCount, 1);

        driver.resolveAll(data: const {'data': []});
        await Future.wait([a, b]);
      },
    );

    test('second call after first resolves fires a new request', () async {
      final a = HttpCache.get('/dashboard/stats');
      driver.resolveAll();
      await a;

      final b = HttpCache.get('/dashboard/stats');
      expect(driver.fireCount, 2);

      driver.resolveAll();
      await b;
    });

    test('different query params key differently and both fire', () async {
      final a = HttpCache.get('/monitors/1/series', query: {'range': '24h'});
      final b = HttpCache.get('/monitors/1/series', query: {'range': '7d'});

      expect(driver.fireCount, 2);

      driver.resolveAll();
      await Future.wait([a, b]);
    });

    test(
      'failure clears the in-flight entry; retry fires a new request',
      () async {
        final a = HttpCache.get('/dashboard/stats');
        driver.failAll();
        await a;

        final b = HttpCache.get('/dashboard/stats');
        expect(driver.fireCount, 2);

        driver.resolveAll();
        await b;
      },
    );
  });
}
