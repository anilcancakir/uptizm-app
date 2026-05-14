import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/requests/store_status_page_request.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  dynamic lastData;
  MagicResponse response = MagicResponse(data: {}, statusCode: 200);

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

void main() {
  group('StoreStatusPageRequest', () {
    test('trims strings and drops blank logo_path', () {
      final payload = const StoreStatusPageRequest().validate({
        'title': '  Trust Page  ',
        'slug': '  trust  ',
        'primary_color': '#111827',
        'is_public': true,
        'monitor_ids': ['m_1'],
        'logo_path': '  ',
      });

      expect(payload['title'], 'Trust Page');
      expect(payload['slug'], 'trust');
      expect(payload['primary_color'], '#111827');
      expect(payload['is_public'], true);
      expect(payload['monitor_ids'], ['m_1']);
      expect(payload.containsKey('logo_path'), isFalse);
    });

    test('keeps trimmed logo_path when present', () {
      final payload = const StoreStatusPageRequest().validate({
        'title': 'Trust',
        'slug': 'trust',
        'primary_color': '#111827',
        'is_public': false,
        'monitor_ids': const [],
        'logo_path': ' /uploads/logo.png ',
      });

      expect(payload['logo_path'], '/uploads/logo.png');
    });

    test('rejects missing required fields', () {
      expect(
        () => const StoreStatusPageRequest().validate({
          'title': '',
          'slug': '',
          'primary_color': '',
          'is_public': false,
          'monitor_ids': const [],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    group('slug Unique async rule', () {
      late _MockNetworkDriver driver;

      setUp(() {
        MagicApp.reset();
        Magic.flush();
        driver = _MockNetworkDriver();
        Magic.singleton('network', () => driver);
      });

      test('passes when /validate/unique returns 200 unique:true', () async {
        driver.response = MagicResponse(
          data: {'unique': true},
          statusCode: 200,
        );

        final payload = await const StoreStatusPageRequest().validateAsync({
          'title': 'Trust',
          'slug': 'free-slug',
          'primary_color': '#111827',
          'is_public': false,
          'monitor_ids': const [],
        });

        expect(payload['slug'], 'free-slug');
        expect(driver.lastMethod, 'POST');
        expect(driver.lastUrl, '/validate/unique');
        final body = driver.lastData as Map;
        expect(body['model'], 'status_page');
        expect(body['field'], 'slug');
        expect(body['value'], 'free-slug');
        expect(body.containsKey('ignore_id'), isFalse);
      });

      test('fails when /validate/unique returns 422', () async {
        driver.response = MagicResponse(
          data: {
            'message': 'Validation failed',
            'errors': {
              'slug': ['The slug has already been taken.'],
            },
          },
          statusCode: 422,
        );

        await expectLater(
          const StoreStatusPageRequest().validateAsync({
            'title': 'Trust',
            'slug': 'taken-slug',
            'primary_color': '#111827',
            'is_public': false,
            'monitor_ids': const [],
          }),
          throwsA(isA<ValidationException>()),
        );
      });

      test('passes on 5xx (graceful degradation)', () async {
        driver.response = MagicResponse(data: {}, statusCode: 500);

        final payload = await const StoreStatusPageRequest().validateAsync({
          'title': 'Trust',
          'slug': 'wobbly',
          'primary_color': '#111827',
          'is_public': false,
          'monitor_ids': const [],
        });

        expect(payload['slug'], 'wobbly');
      });

      test('passes on transport failure (statusCode 0, offline)', () async {
        // Dio's _handleError returns statusCode: 0 when the request cannot
        // reach the server at all (DNS failure, no network, connection
        // refused). The resolver must treat that as "not authoritative"
        // and pass, otherwise offline users see false "slug taken" errors.
        driver.response = MagicResponse(data: {}, statusCode: 0);

        final payload = await const StoreStatusPageRequest().validateAsync({
          'title': 'Trust',
          'slug': 'offline-slug',
          'primary_color': '#111827',
          'is_public': false,
          'monitor_ids': const [],
        });

        expect(payload['slug'], 'offline-slug');
      });
    });
  });
}
