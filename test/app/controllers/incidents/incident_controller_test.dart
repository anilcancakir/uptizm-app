import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/incidents/incident_controller.dart';
import 'package:app/app/enums/incident_impact.dart';
import 'package:app/app/enums/incident_severity.dart';
import 'package:app/app/enums/incident_status.dart';

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
  }) async => _record('INDEX', resource);

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

Map<String, dynamic> _incidentPayload({
  String id = 'inc_1',
  String status = 'detected',
  String severity = 'warn',
}) {
  return {
    'id': id,
    'monitor_id': 'mon_1',
    'title': 'Pool degraded',
    'severity': severity,
    'status': status,
    'signal_source': 'user_threshold',
    'trigger_ref': 'db_conn_ms',
    'metric_key': 'db_conn_ms',
    'ai_owned': false,
    'started_at': '2026-04-18T10:00:00Z',
    'resolved_at': null,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncidentController', () {
    late _MockNetworkDriver driver;
    late IncidentController controller;

    setUp(() {
      MagicApp.reset();
      Magic.flush();
      driver = _MockNetworkDriver();
      Magic.singleton('network', () => driver);
      controller = IncidentController();
    });

    test('load GETs /incidents with optional filters', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            _incidentPayload(id: 'inc_1'),
            _incidentPayload(id: 'inc_2'),
          ],
        },
        statusCode: 200,
      );

      await controller.load(monitorId: 'mon_1', status: 'detected');

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/incidents');
      expect(driver.lastQuery?['monitor_id'], 'mon_1');
      expect(driver.lastQuery?['status'], 'detected');
      expect(controller.isSuccess, isTrue);
      expect(controller.incidents, hasLength(2));
      expect(controller.incidents.first.id, 'inc_1');
    });

    test('load surfaces 500 as error state', () async {
      driver.response = MagicResponse(
        data: {'message': 'boom'},
        statusCode: 500,
      );

      await controller.load();

      expect(controller.isError, isTrue);
      expect(controller.incidents, isEmpty);
    });

    test('loadOne GETs /incidents/{id} and hydrates detail', () async {
      driver.response = MagicResponse(
        data: {
          'data': {
            ..._incidentPayload(id: 'inc_42'),
            'events': [
              {
                'at': '2026-04-18T10:01:00Z',
                'actor': 'ai',
                'event_type': 'opened',
                'message': 'Opened',
              },
            ],
          },
        },
        statusCode: 200,
      );

      await controller.loadOne('inc_42');

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/incidents/inc_42');
      expect(controller.detail?.id, 'inc_42');
      expect(controller.detail?.events, hasLength(1));
    });

    test('store POSTs and prepends the new incident into the list', () async {
      await controller.load();
      driver.response = MagicResponse(
        data: {'data': _incidentPayload(id: 'inc_new', status: 'detected')},
        statusCode: 201,
      );

      final result = await controller.store({
        'monitor_id': 'mon_1',
        'title': 'Manual report',
        'severity': 'warn',
      });

      expect(result, isNotNull);
      expect(result!.id, 'inc_new');
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/incidents');
      expect((driver.lastData as Map)['monitor_id'], 'mon_1');
      expect(controller.incidents.first.id, 'inc_new');
    });

    test('store surfaces 422 field errors without adding to list', () async {
      await controller.load();
      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'title': ['The title field is required.'],
          },
        },
        statusCode: 422,
      );

      final result = await controller.store({'monitor_id': 'mon_1'});

      expect(result, isNull);
      expect(controller.getError('title'), 'The title field is required.');
      expect(controller.incidents, isEmpty);
    });

    test('update PUTs status transition and replaces the list row', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_incidentPayload(id: 'inc_1', status: 'detected')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {'data': _incidentPayload(id: 'inc_1', status: 'investigating')},
        statusCode: 200,
      );

      final result = await controller.update('inc_1', {
        'status': 'investigating',
      });

      expect(result, isNotNull);
      expect(result!.status, IncidentStatus.investigating);
      expect(driver.lastMethod, 'PUT');
      expect(driver.lastUrl, '/incidents/inc_1');
      expect(controller.incidents.single.status, IncidentStatus.investigating);
    });

    test('update restores list on 422 failure', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_incidentPayload(id: 'inc_1', severity: 'warn')],
        },
        statusCode: 200,
      );
      await controller.load();
      final before = controller.incidents.single.severity;

      driver.response = MagicResponse(
        data: {
          'message': 'Validation failed',
          'errors': {
            'severity': ['Invalid severity.'],
          },
        },
        statusCode: 422,
      );

      final result = await controller.update('inc_1', {'severity': 'bogus'});

      expect(result, isNull);
      expect(controller.getError('severity'), 'Invalid severity.');
      expect(controller.incidents.single.severity, before);
      expect(controller.incidents.single.severity, IncidentSeverity.warn);
    });

    test('addEvent POSTs and reloads detail', () async {
      driver.response = MagicResponse(
        data: {
          'data': {..._incidentPayload(id: 'inc_1'), 'events': []},
        },
        statusCode: 200,
      );
      await controller.loadOne('inc_1');

      final calls = <(String, String)>[];
      driver.response = MagicResponse(
        data: {
          'data': {
            'id': 'evt_1',
            'at': '2026-04-18T10:05:00Z',
            'actor': 'u-1',
            'event_type': 'note',
            'message': 'Looking at it',
          },
        },
        statusCode: 201,
      );
      final ok = await controller.addEvent('inc_1', {
        'event_type': 'note',
        'message': 'Looking at it',
      });
      calls.add((driver.lastMethod!, driver.lastUrl!));

      expect(ok, isTrue);
      expect(calls.single.$1, 'POST');
      expect(calls.single.$2, '/incidents/inc_1/events');
      expect((driver.lastData as Map)['event_type'], 'note');
    });

    test(
      'addEvent appends to list entry even when detail is not loaded',
      () async {
        driver.response = MagicResponse(
          data: {
            'data': [
              {..._incidentPayload(id: 'inc_1'), 'events': []},
            ],
          },
          statusCode: 200,
        );
        await controller.load(monitorId: 'mon_1');

        expect(controller.incidents.single.events, isEmpty);

        driver.response = MagicResponse(
          data: {
            'data': {
              'id': 'evt_1',
              'at': '2026-04-18T10:05:00Z',
              'actor': 'u-1',
              'event_type': 'note',
              'message': 'Drawer note',
            },
          },
          statusCode: 201,
        );
        final ok = await controller.addEvent('inc_1', {
          'event_type': 'note',
          'message': 'Drawer note',
        });

        expect(ok, isTrue);
        expect(controller.incidents.single.events, hasLength(1));
        expect(
          controller.incidents.single.events.single.message,
          'Drawer note',
        );
      },
    );

    test(
      'submitCreate builds typed payload and toggles isSubmitting',
      () async {
        driver.response = MagicResponse(
          data: {'data': _incidentPayload(id: 'inc_new')},
          statusCode: 201,
        );

        expect(controller.isSubmitting, isFalse);
        final future = controller.submitCreate(
          monitorId: 'mon_1',
          title: '  Latency spike  ',
          severity: IncidentSeverity.warn,
          description: '  trace  ',
          metricKey: 'latency_ms',
          notifyTeam: false,
        );
        expect(controller.isSubmitting, isTrue);
        final result = await future;

        expect(result?.id, 'inc_new');
        expect(controller.isSubmitting, isFalse);
        expect(driver.lastMethod, 'POST');
        expect(driver.lastUrl, '/incidents');
        final payload = driver.lastData as Map;
        expect(payload['monitor_id'], 'mon_1');
        expect(payload['title'], 'Latency spike');
        expect(payload['severity'], 'warn');
        expect(payload['description'], 'trace');
        expect(payload['metric_key'], 'latency_ms');
        expect(payload['notify_team'], false);
      },
    );

    test('submitCreate omits description and metric_key when blank', () async {
      driver.response = MagicResponse(
        data: {'data': _incidentPayload(id: 'inc_x')},
        statusCode: 201,
      );

      await controller.submitCreate(
        monitorId: 'mon_1',
        title: 'Bare minimum',
        severity: IncidentSeverity.info,
      );

      final payload = driver.lastData as Map;
      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('metric_key'), isFalse);
      expect(payload['notify_team'], true);
    });

    test('similar GETs and returns list without mutating state', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            {
              'id': 'sim_1',
              'similarity_score': 0.8,
              'resolution_note': 'Bumped pool',
              'discovered_at': '2026-04-01T00:00:00Z',
              'similar_to': {
                'id': 'inc_old',
                'title': 'Prior pool exhaustion',
                'started_at': '2026-03-10T00:00:00Z',
              },
            },
          ],
        },
        statusCode: 200,
      );

      final similar = await controller.similar('inc_1');

      expect(driver.lastMethod, 'GET');
      expect(driver.lastUrl, '/incidents/inc_1/similar');
      expect(similar, hasLength(1));
      expect(similar.single.id, 'inc_old');
      expect(similar.single.resolutionNote, 'Bumped pool');
    });

    test(
      'postUpdate POSTs /incidents/{id}/updates and appends the row',
      () async {
        driver.response = MagicResponse(
          data: {
            'data': {
              ..._incidentPayload(id: 'inc_1', status: 'identified'),
              'updates': const [],
            },
          },
          statusCode: 200,
        );
        await controller.loadOne('inc_1');

        driver.response = MagicResponse(
          data: {
            'data': {
              'id': 'upd_1',
              'incident_id': 'inc_1',
              'status': 'identified',
              'body': 'Root cause found',
              'display_at': '2026-04-18T10:05:00Z',
              'deliver_notifications': true,
            },
          },
          statusCode: 201,
        );

        final result = await controller.postUpdate(
          incidentId: 'inc_1',
          status: IncidentStatus.identified,
          body: 'Root cause found',
        );

        expect(result, isNotNull);
        expect(driver.lastMethod, 'POST');
        expect(driver.lastUrl, '/incidents/inc_1/updates');
        final payload = driver.lastData as Map;
        expect(payload['status'], 'identified');
        expect(payload['body'], 'Root cause found');
        expect(payload['deliver_notifications'], isTrue);
        expect(controller.detail?.updates, hasLength(1));
        expect(controller.detail?.status, IncidentStatus.identified);
      },
    );

    test('publish POSTs /incidents/{id}/publish and reconciles list', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_incidentPayload(id: 'inc_1')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {
          'data': {..._incidentPayload(id: 'inc_1'), 'is_published': true},
        },
        statusCode: 200,
      );

      final ok = await controller.publish('inc_1');

      expect(ok, isTrue);
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/incidents/inc_1/publish');
      expect(controller.incidents.single.isPublished, isTrue);
    });

    test('overrideImpact POSTs /impact with the chosen impact enum', () async {
      driver.response = MagicResponse(
        data: {
          'data': [_incidentPayload(id: 'inc_1')],
        },
        statusCode: 200,
      );
      await controller.load();

      driver.response = MagicResponse(
        data: {
          'data': {
            ..._incidentPayload(id: 'inc_1'),
            'impact': 'critical',
            'impact_override': true,
          },
        },
        statusCode: 200,
      );

      final ok = await controller.overrideImpact(
        incidentId: 'inc_1',
        impact: IncidentImpact.critical,
      );

      expect(ok, isTrue);
      expect(driver.lastMethod, 'POST');
      expect(driver.lastUrl, '/incidents/inc_1/impact');
      expect((driver.lastData as Map)['impact'], 'critical');
      expect(controller.incidents.single.impact, IncidentImpact.critical);
      expect(controller.incidents.single.impactOverride, isTrue);
    });
  });
}
