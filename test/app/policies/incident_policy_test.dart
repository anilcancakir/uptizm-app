import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/enums/incident_severity.dart';
import 'package:app/app/enums/incident_status.dart';
import 'package:app/app/enums/signal_source.dart';
import 'package:app/app/models/incident.dart';
import 'package:app/app/models/user.dart';
import 'package:app/app/policies/incident_policy.dart';

User _user(String id, {String? teamId, String? role}) {
  return User.fromMap({
    'id': id,
    'name': 'Test',
    'email': 'test@example.com',
    if (teamId != null)
      'current_team': {'id': teamId, 'name': 'Team', 'user_role': role},
  });
}

Incident _incident(String id, String? teamId) {
  return Incident(
    id: id,
    monitorId: 'm_1',
    teamId: teamId,
    title: 'Outage',
    severity: IncidentSeverity.warn,
    status: IncidentStatus.detected,
    startedAt: DateTime(2026, 4, 18),
    signalSource: SignalSource.manual,
  );
}

void main() {
  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Gate.flush();
    const IncidentPolicy().register();
  });

  tearDown(() {
    Auth.unfake();
    Gate.flush();
  });

  test('incidents.create allows any authenticated user', () {
    Auth.fake(user: _user('u1'));
    expect(Gate.allows('incidents.create'), isTrue);
  });

  test('incidents.update denies plain member', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'member'),
    );
    expect(Gate.allows('incidents.update', _incident('i_1', 'tm_1')), isFalse);
  });

  test('incidents.update allows admin in same team', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'admin'),
    );
    expect(Gate.allows('incidents.update', _incident('i_1', 'tm_1')), isTrue);
  });
}
