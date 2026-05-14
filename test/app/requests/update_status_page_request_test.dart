import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/requests/update_status_page_request.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateStatusPageRequest', () {
    setUp(() {
      MagicApp.reset();
      Magic.flush();
    });

    test('trims present strings and drops blank logo_path', () {
      final result = const UpdateStatusPageRequest().validate({
        'title': '  Cloud  ',
        'slug': '  cloud  ',
        'primary_color': '  #111111  ',
        'logo_path': '   ',
      });
      expect(result['title'], 'Cloud');
      expect(result['slug'], 'cloud');
      expect(result['primary_color'], '#111111');
      expect(result.containsKey('logo_path'), isFalse);
    });

    test('absent keys stay absent (partial patch)', () {
      final result = const UpdateStatusPageRequest().validate({
        'title': 'Only title',
      });
      expect(result.keys.toSet(), {'title'});
    });

    test('keeps logo_path when non-blank', () {
      final result = const UpdateStatusPageRequest().validate({
        'logo_path': '  logos/brand.png  ',
      });
      expect(result['logo_path'], 'logos/brand.png');
    });

    group('validateForUpdate (slug Unique with ignore_id)', () {
      late _MockNetworkDriver driver;

      setUp(() {
        driver = _MockNetworkDriver();
        Magic.singleton('network', () => driver);
      });

      test('includes ignore_id in the POST envelope', () async {
        driver.response = MagicResponse(
          data: {'unique': true},
          statusCode: 200,
        );

        await const UpdateStatusPageRequest().validateForUpdate({
          'slug': 'cloud',
        }, pageId: 'pg_1');

        expect(driver.lastMethod, 'POST');
        expect(driver.lastUrl, '/validate/unique');
        final body = driver.lastData as Map;
        expect(body['model'], 'status_page');
        expect(body['field'], 'slug');
        expect(body['value'], 'cloud');
        expect(body['ignore_id'], 'pg_1');
      });

      test(
        'passes when slug is taken but ignore_id matches (api returns 200)',
        () async {
          driver.response = MagicResponse(
            data: {'unique': true},
            statusCode: 200,
          );

          final result = await const UpdateStatusPageRequest()
              .validateForUpdate({'slug': 'cloud'}, pageId: 'pg_1');

          expect(result['slug'], 'cloud');
        },
      );

      test('passes on transport failure (statusCode 0, offline)', () async {
        // Mirrors the Store request guard: offline users must not be blocked
        // by a false "slug taken" error when the probe never reaches the
        // server. The server's submit-time validation remains the source of
        // truth for uniqueness.
        driver.response = MagicResponse(data: {}, statusCode: 0);

        final result = await const UpdateStatusPageRequest().validateForUpdate({
          'slug': 'cloud',
        }, pageId: 'pg_1');

        expect(result['slug'], 'cloud');
      });

      test(
        'fails when slug collides with a different record (api returns 422)',
        () async {
          driver.response = MagicResponse(
            data: {
              'errors': {
                'slug': ['The slug has already been taken.'],
              },
            },
            statusCode: 422,
          );

          await expectLater(
            const UpdateStatusPageRequest().validateForUpdate({
              'slug': 'cloud',
            }, pageId: 'pg_1'),
            throwsA(isA<ValidationException>()),
          );
        },
      );
    });
  });
}
