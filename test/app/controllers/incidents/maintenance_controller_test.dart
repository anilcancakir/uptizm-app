import 'package:app/app/controllers/incidents/maintenance_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

class _MockNetworkDriver implements NetworkDriver {
  String? lastMethod;
  String? lastUrl;
  Map<String, dynamic>? lastQuery;
  dynamic lastData;
  MagicResponse response = MagicResponse(data: {}, statusCode: 500);

  MagicResponse _record(
    String method,
    String url, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    lastMethod = method;
    lastUrl = url;
    lastData = data;
    lastQuery = query;
    return response;
  }

  @override
  void addInterceptor(MagicNetworkInterceptor interceptor) {}

  @override
  Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async => _record('GET', url, query: query);

  @override
  Future<MagicResponse> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record('POST', url, data: data);

  @override
  Future<MagicResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async => _record('PUT', url, data: data);

  @override
  Future<MagicResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async => _record('DELETE', url);

  @override
  Future<MagicResponse> index(
    String resource, {
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
  }) async => _record('INDEX', resource, query: filters);

  @override
  Future<MagicResponse> show(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => _record('SHOW', '$resource/$id');

  @override
  Future<MagicResponse> store(
    String resource,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('STORE', resource, data: data);

  @override
  Future<MagicResponse> update(
    String resource,
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async => _record('UPDATE', '$resource/$id', data: data);

  @override
  Future<MagicResponse> destroy(
    String resource,
    String id, {
    Map<String, String>? headers,
  }) async => _record('DESTROY', '$resource/$id');

  @override
  Future<MagicResponse> upload(
    String url, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> files,
    Map<String, String>? headers,
  }) async => _record('UPLOAD', url, data: data);
}

Map<String, dynamic> _maintenancePayload({
  String id = 'inc_m1',
  String status = 'scheduled',
}) {
  return {
    'id': id,
    'monitor_id': 'mon_1',
    'title': 'DB upgrade',
    'severity': 'info',
    'status': status,
    'kind': 'maintenance',
    'impact': 'maintenance',
    'signal_source': 'manual',
    'started_at': '2026-05-01T10:00:00Z',
    'scheduled_for': '2026-05-01T10:00:00Z',
    'scheduled_until': '2026-05-01T11:00:00Z',
    'is_published': true,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MaintenanceController', () {
    late _MockNetworkDriver driver;
    late MaintenanceController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = MaintenanceController();
    });

    test('load GETs /maintenance with optional lane filter', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_maintenancePayload(id: 'inc_m1')],
        },
        statusCode: 200,
      );

      await controller.load(lane: 'upcoming');

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/maintenance');
      expect(driver.lastQuery?['lane'], 'upcoming');
      expect(controller.isSuccess, isTrue);
      expect(controller.windows, hasLength(1));
    });

    test('submitCreate validates and POSTs normalized payload', () async {
      driver.response = MagicResponse(
        data: {'data': _maintenancePayload(id: 'inc_new')},
        statusCode: 201,
      );

      final start = DateTime.utc(2026, 5, 1, 10);
      final end = DateTime.utc(2026, 5, 1, 11);

      final window = await controller.submitCreate(
        title: '  DB upgrade  ',
        scheduledFor: start,
        scheduledUntil: end,
        monitorIds: ['mon_1'],
        body: '   ',
      );

      expect(window?.id, 'inc_new');
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/maintenance');
      final payload = driver.lastData as Map;
      expect(payload['title'], 'DB upgrade');
      expect(payload['scheduled_for'], start.toIso8601String());
      expect(payload['scheduled_until'], end.toIso8601String());
      expect(payload.containsKey('body'), isFalse);
      expect(payload['monitor_ids'], ['mon_1']);
    });

    test(
      'submitCreate surfaces 422 field errors and leaves list untouched',
      () async {
        driver.response = MagicResponse(
          data: {
            'message': 'Validation failed',
            'errors': {
              'scheduled_until': ['Must be after scheduled_for.'],
            },
          },
          statusCode: 422,
        );

        final result = await controller.submitCreate(
          title: 'x',
          scheduledFor: DateTime.utc(2026, 5, 1),
          scheduledUntil: DateTime.utc(2026, 5, 2),
          monitorIds: ['mon_1'],
        );

        expect(result, isNull);
        expect(
          controller.getError('scheduled_until'),
          'Must be after scheduled_for.',
        );
        expect(controller.windows, isEmpty);
      },
    );

    test('cancel POSTs /maintenance/{id}/cancel and reconciles list', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_maintenancePayload(id: 'inc_m1', status: 'scheduled')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {'data': _maintenancePayload(id: 'inc_m1', status: 'completed')},
        statusCode: 200,
      );

      final ok = await controller.cancel('inc_m1');

      expect(ok, isTrue);
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/maintenance/inc_m1/cancel');
      expect(controller.windows.single.status.name, 'completed');
    });
  });
}
