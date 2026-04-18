import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/settings/appearance_controller.dart';
import 'package:app/resources/views/settings/settings_appearance_view.dart';

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

  group('AppearanceController', () {
    late _MockNetworkDriver driver;
    late AppearanceController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = AppearanceController();
    });

    test('load GETs /settings/appearance and hydrates settings', () async {
      driver.response = MagicResponse(
        data: {
          'data': {
            'appearance_primary_color': '#ff0066',
            'appearance_logo_path': 'logos/team.png',
          },
        },
        statusCode: 200,
      );

      await controller.load();

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/settings/appearance');
      expect(controller.settings?.primaryColor, '#ff0066');
      expect(controller.settings?.logoPath, 'logos/team.png');
    });

    test('update PUTs payload and stores returned values', () async {
      driver.response = MagicResponse(
        data: {
          'data': {
            'appearance_primary_color': '#112233',
            'appearance_logo_path': null,
          },
        },
        statusCode: 200,
      );

      final ok = await controller.update({
        'appearance_primary_color': '#112233',
        'appearance_logo_path': null,
      });

      expect(ok, isTrue);
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/settings/appearance');
      expect(controller.settings?.primaryColor, '#112233');
      expect(controller.settings?.logoPath, isNull);
    });

    test('update surfaces 422 field errors', () async {
      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'appearance_primary_color': ['Bad color.'],
          },
        },
        statusCode: 422,
      );

      final ok = await controller.update({'appearance_primary_color': 'nope'});

      expect(ok, isFalse);
      expect(controller.getError('appearance_primary_color'), 'Bad color.');
    });

    test('index() returns SettingsAppearanceView', () {
      expect(controller.index(), isA<SettingsAppearanceView>());
    });

    test('submit trims inputs and toggles isSubmitting', () async {
      driver.response = MagicResponse(
        data: {
          'data': {
            'appearance_primary_color': '#ff0066',
            'appearance_logo_path': 'logos/team.png',
          },
        },
        statusCode: 200,
      );

      expect(controller.isSubmitting, isFalse);
      final future = controller.submit(
        primaryColor: '  #ff0066  ',
        logoPath: '  logos/team.png  ',
      );
      expect(controller.isSubmitting, isTrue);
      final ok = await future;

      expect(ok, isTrue);
      expect(controller.isSubmitting, isFalse);
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/settings/appearance');
      final payload = driver.lastData as Map;
      expect(payload['appearance_primary_color'], '#ff0066');
      expect(payload['appearance_logo_path'], 'logos/team.png');
    });

    test('submit nulls empty logo path', () async {
      driver.response = MagicResponse(
        data: {
          'data': {
            'appearance_primary_color': '#112233',
            'appearance_logo_path': null,
          },
        },
        statusCode: 200,
      );

      await controller.submit(primaryColor: '#112233', logoPath: '   ');

      expect((driver.lastData as Map)['appearance_logo_path'], isNull);
    });
  });
}
