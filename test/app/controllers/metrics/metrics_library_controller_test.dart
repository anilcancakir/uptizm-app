import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/metrics/metrics_library_controller.dart';
import 'package:app/resources/views/settings/settings_metrics_library_view.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastUrl;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    lastUrl = url;
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
    String resource, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> show(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> store(
    String resource,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => response;
  @override
  Future<MagicResponse> destroy(
    String resource,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetricsLibraryController', () {
    late _MockNetworkDriver driver;
    late MetricsLibraryController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MetricsLibraryController();
    });

    test('load GETs /settings/metrics-library', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            {
              'id': 'met_1',
              'group_name': 'Performance',
              'label': 'Latency',
              'key': 'latency_ms',
              'type': 'numeric',
              'source': 'json_path',
            },
          ],
        },
        statusCode: 200,
      );

      await controller.load();

      expect(driver.lastUrl, '/settings/metrics-library');
      expect(controller.isSuccess, isTrue);
      expect(controller.metrics.single.label, 'Latency');
    });

    test('load emits empty state when no metrics exist', () async {
      driver.response = MagicResponse(data: {'data': []}, statusCode: 200);

      await controller.load();

      expect(controller.isEmpty, isTrue);
    });

    test('load surfaces error state on failure', () async {
      driver.response = MagicResponse(
        data: {'message': 'Server error'},
        statusCode: 500,
      );

      await controller.load();

      expect(controller.isError, isTrue);
    });

    test('index() returns SettingsMetricsLibraryView', () {
      expect(controller.index(), isA<SettingsMetricsLibraryView>());
    });
  });
}
