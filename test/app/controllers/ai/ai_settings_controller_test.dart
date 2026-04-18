import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/ai/ai_settings_controller.dart';
import 'package:app/app/enums/ai_mode.dart';
import 'package:app/resources/views/settings/settings_ai_view.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiSettingsController', () {
    late _MockNetworkDriver driver;
    late AiSettingsController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = AiSettingsController();
    });

    test('load GETs /settings/ai and hydrates settings', () async {
      driver.response = MagicResponse(
        data: {
          'data': {'ai_mode': 'suggest', 'ai_daily_digest_enabled': true},
        },
        statusCode: 200,
      );

      await controller.load();

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/settings/ai');
      expect(controller.settings?.aiMode, AiMode.suggest);
      expect(controller.settings?.dailyDigestEnabled, isTrue);
    });

    test('update PUTs and stores returned values', () async {
      driver.response = MagicResponse(
        data: {
          'data': {'ai_mode': 'auto', 'ai_daily_digest_enabled': false},
        },
        statusCode: 200,
      );

      final ok = await controller.update({
        'ai_mode': 'auto',
        'ai_daily_digest_enabled': false,
      });

      expect(ok, isTrue);
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/settings/ai');
      expect(controller.settings?.aiMode, AiMode.auto);
      expect(controller.settings?.dailyDigestEnabled, isFalse);
    });

    test('update surfaces 422 field errors', () async {
      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'ai_mode': ['The ai mode field is invalid.'],
          },
        },
        statusCode: 422,
      );

      final ok = await controller.update({'ai_mode': 'bad'});

      expect(ok, isFalse);
      expect(controller.getError('ai_mode'), 'The ai mode field is invalid.');
    });

    test('index() returns SettingsAiView', () {
      expect(controller.index(), isA<SettingsAiView>());
    });

    test('submit builds typed payload and toggles isSubmitting', () async {
      driver.response = MagicResponse(
        data: {
          'data': {'ai_mode': 'auto', 'ai_daily_digest_enabled': false},
        },
        statusCode: 200,
      );

      expect(controller.isSubmitting, isFalse);
      final future = controller.submit(aiMode: AiMode.auto, dailyDigest: false);
      expect(controller.isSubmitting, isTrue);
      final ok = await future;

      expect(ok, isTrue);
      expect(controller.isSubmitting, isFalse);
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/settings/ai');
      expect((driver.lastData as Map)['ai_mode'], 'auto');
      expect((driver.lastData as Map)['ai_daily_digest_enabled'], false);
    });

    test('submit returns false and surfaces 422 via getError', () async {
      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'ai_mode': ['Invalid.'],
          },
        },
        statusCode: 422,
      );

      final ok = await controller.submit(
        aiMode: AiMode.suggest,
        dailyDigest: true,
      );

      expect(ok, isFalse);
      expect(controller.isSubmitting, isFalse);
      expect(controller.getError('ai_mode'), 'Invalid.');
    });
  });
}
