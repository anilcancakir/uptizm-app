import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:app/app/controllers/incidents/incident_controller.dart';
import 'package:app/app/enums/incident_severity.dart';
import 'package:app/app/enums/incident_status.dart';
import 'package:app/app/models/user.dart';
import 'package:app/app/policies/incident_policy.dart';

User _managerUser() => User.fromMap({
  'id': 'usr_owner_1',
  'current_team': {'id': 'team_1', 'user_role': 'owner'},
});

User _memberUser() => User.fromMap({
  'id': 'usr_member_1',
  'current_team': {'id': 'team_1', 'user_role': 'member'},
});

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
  String teamId = 'team_1',
}) {
  return {
    'id': id,
    'team_id': teamId,
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
      Auth.fake(user: _managerUser());
      const IncidentPolicy().register();
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

    test('loadOne preserves the existing list (no state reset)', () async {
      driver.response = MagicResponse(
        data: {
          'data': [
            _incidentPayload(id: 'inc_1'),
            _incidentPayload(id: 'inc_2'),
          ],
        },
        statusCode: 200,
      );
      await controller.load(monitorId: 'mon_1');
      expect(controller.incidents, hasLength(2));

      driver.response = MagicResponse(
        data: {
          'data': {..._incidentPayload(id: 'inc_1'), 'events': []},
        },
        statusCode: 200,
      );
      await controller.loadOne('inc_1');

      expect(controller.incidents, hasLength(2));
      expect(controller.incidents.map((i) => i.id), ['inc_1', 'inc_2']);
      expect(controller.detail?.id, 'inc_1');
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

    test(
      'postUpdate POSTs public update and transitions detail status',
      () async {
        driver.response = MagicResponse(
          data: {
            'data': {..._incidentPayload(id: 'inc_1'), 'updates': []},
          },
          statusCode: 200,
        );
        await controller.loadOne('inc_1');

        driver.response = MagicResponse(
          data: {
            'data': {
              'id': 'upd_1',
              'incident_id': 'inc_1',
              'status': 'investigating',
              'body': 'Looking at it',
              'display_at': '2026-04-18T10:05:00Z',
              'deliver_notifications': true,
            },
          },
          statusCode: 201,
        );
        final ok = await controller.postUpdate(
          id: 'inc_1',
          status: IncidentStatus.investigating,
          body: 'Looking at it',
        );

        expect(ok, isTrue);
        expect(driver.lastMethod, 'POST');
        expect(driver.lastUrl, '/incidents/inc_1/updates');
        expect((driver.lastData as Map)['status'], 'investigating');
        expect((driver.lastData as Map)['body'], 'Looking at it');
        expect(controller.detail?.status, IncidentStatus.investigating);
        expect(controller.detail?.updates, hasLength(1));
        expect(controller.detail?.updates.single.body, 'Looking at it');
      },
    );

    test(
      'postUpdate appends to list entry even when detail is not loaded',
      () async {
        driver.response = MagicResponse(
          data: {
            'data': [
              {..._incidentPayload(id: 'inc_1'), 'updates': []},
            ],
          },
          statusCode: 200,
        );
        await controller.load(monitorId: 'mon_1');

        expect(controller.incidents.single.updates, isEmpty);

        driver.response = MagicResponse(
          data: {
            'data': {
              'id': 'upd_1',
              'incident_id': 'inc_1',
              'status': 'resolved',
              'body': 'Mitigated by rollback',
              'display_at': '2026-04-18T10:05:00Z',
              'deliver_notifications': true,
            },
          },
          statusCode: 201,
        );
        final ok = await controller.postUpdate(
          id: 'inc_1',
          status: IncidentStatus.resolved,
          body: 'Mitigated by rollback',
        );

        expect(ok, isTrue);
        expect(controller.incidents.single.status, IncidentStatus.resolved);
        expect(controller.incidents.single.updates, hasLength(1));
        expect(
          controller.incidents.single.updates.single.body,
          'Mitigated by rollback',
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

    test(
      'store throws AuthorizationException when current user is a guest',
      () async {
        // Re-fake with no user — Gate.allows('incidents.create') must deny
        // because the ability requires _authed(user).
        Auth.fake();

        expect(
          () => controller.store({
            'monitor_id': 'mon_1',
            'title': 'X',
            'severity': 'warn',
          }),
          throwsA(isA<AuthorizationException>()),
        );
        // No Http call should have been made — authorize() throws before
        // the controller hits the network.
        expect(driver.lastMethod, isNull);
      },
    );

    test(
      'update throws AuthorizationException when user is not a manager',
      () async {
        // Seed the list with one incident in team_1 so update() can resolve
        // its target before the gate check fires.
        driver.response = MagicResponse(
          data: {
            'data': [_incidentPayload(id: 'inc_1', teamId: 'team_1')],
          },
          statusCode: 200,
        );
        await controller.load();

        // Re-fake as a member of the same team — same-team check passes
        // but _isManager rejects.
        Auth.fake(user: _memberUser());

        expect(
          () => controller.update('inc_1', {'status': 'investigating'}),
          throwsA(isA<AuthorizationException>()),
        );
      },
    );

    test(
      'postUpdate throws AuthorizationException when user is not a manager',
      () async {
        driver.response = MagicResponse(
          data: {
            'data': [_incidentPayload(id: 'inc_1', teamId: 'team_1')],
          },
          statusCode: 200,
        );
        await controller.load();

        Auth.fake(user: _memberUser());

        expect(
          () => controller.postUpdate(
            id: 'inc_1',
            status: IncidentStatus.investigating,
            body: 'Looking',
          ),
          throwsA(isA<AuthorizationException>()),
        );
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

    group('draftIncidentBundle', () {
      test(
        'POSTs to /monitors/<id>/incidents/draft and returns the drafted bundle',
        () async {
          driver.response = MagicResponse(
            data: {
              'data': {
                'title': 'Polished title',
                'description': 'Polished description',
              },
            },
            statusCode: 200,
          );

          final result = await controller.draftIncidentBundle(
            monitorId: 'mon_1',
            severity: 'critical',
            title: 'raw title',
            description: 'raw description',
            metricKey: 'p95',
          );

          expect(driver.lastMethod, 'POST');
          expect(driver.lastUrl, '/monitors/mon_1/incidents/draft');
          final payload = driver.lastData as Map;
          expect(payload['severity'], 'critical');
          expect(payload['title'], 'raw title');
          expect(payload['description'], 'raw description');
          expect(payload['metric_key'], 'p95');
          expect(result?.title, 'Polished title');
          expect(result?.description, 'Polished description');
        },
      );

      test('omits metric_key from the payload when null', () async {
        driver.response = MagicResponse(
          data: {
            'data': {'title': 'T', 'description': 'D'},
          },
          statusCode: 200,
        );

        await controller.draftIncidentBundle(
          monitorId: 'mon_1',
          severity: 'warning',
          title: 't',
          description: 'd',
        );

        final payload = driver.lastData as Map;
        expect(payload.containsKey('metric_key'), isFalse);
      });

      test('returns null on 429 without throwing', () async {
        driver.response = MagicResponse(
          data: {'message': 'rate limited'},
          statusCode: 429,
        );

        final result = await controller.draftIncidentBundle(
          monitorId: 'mon_1',
          severity: 'info',
          title: 't',
          description: 'd',
        );

        expect(result, isNull);
      });

      test('returns null on non-2xx error', () async {
        driver.response = MagicResponse(
          data: {'message': 'boom'},
          statusCode: 500,
        );

        final result = await controller.draftIncidentBundle(
          monitorId: 'mon_1',
          severity: 'info',
          title: 't',
          description: 'd',
        );

        expect(result, isNull);
      });

      test('returns null when payload shape is unexpected', () async {
        driver.response = MagicResponse(
          data: {
            'data': {'title': 'only title'},
          },
          statusCode: 200,
        );

        final result = await controller.draftIncidentBundle(
          monitorId: 'mon_1',
          severity: 'info',
          title: 't',
          description: 'd',
        );

        expect(result, isNull);
      });
    });

    group('draftUpdate', () {
      test(
        'POSTs to /incidents/<id>/updates/draft and returns the body',
        () async {
          driver.response = MagicResponse(
            data: {
              'data': {'body': 'AI-polished body'},
            },
            statusCode: 200,
          );

          final body = await controller.draftUpdate(
            id: 'inc_1',
            intent: 'acknowledged',
            userDraft: 'starting investigation',
          );

          expect(driver.lastMethod, 'POST');
          expect(driver.lastUrl, '/incidents/inc_1/updates/draft');
          final payload = driver.lastData as Map;
          expect(payload['status'], 'acknowledged');
          expect(payload['body'], 'starting investigation');
          expect(body, 'AI-polished body');
        },
      );

      test('returns null on 429 without throwing', () async {
        driver.response = MagicResponse(
          data: {'message': 'rate limited'},
          statusCode: 429,
        );

        final body = await controller.draftUpdate(
          id: 'inc_1',
          intent: 'none',
          userDraft: 'note',
        );

        expect(body, isNull);
      });

      test('returns null on non-2xx error', () async {
        driver.response = MagicResponse(
          data: {'message': 'boom'},
          statusCode: 500,
        );

        final body = await controller.draftUpdate(
          id: 'inc_1',
          intent: 'none',
          userDraft: 'note',
        );

        expect(body, isNull);
      });

      test('returns null when body field is missing or non-string', () async {
        driver.response = MagicResponse(
          data: {
            'data': {'body': 42},
          },
          statusCode: 200,
        );

        final body = await controller.draftUpdate(
          id: 'inc_1',
          intent: 'none',
          userDraft: 'note',
        );

        expect(body, isNull);
      });
    });
  });
}
