import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/models/monitor.dart';
import 'package:app/app/models/user.dart';
import 'package:app/app/policies/monitor_policy.dart';

User _user(String id, {String? teamId, String? role}) {
  return User.fromMap({
    'id': id,
    'name': 'Test',
    'email': 'test@example.com',
    if (teamId != null)
      'current_team': {'id': teamId, 'name': 'Team', 'user_role': role},
  });
}

Monitor _monitor(String id, String teamId) {
  return Monitor.fromMap({'id': id, 'name': 'API', 'team_id': teamId});
}

void main() {
  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Gate.flush();
    const MonitorPolicy().register();
  });

  tearDown(() {
    Auth.unfake();
    Gate.flush();
  });

  test('monitors.create allows any authenticated user', () {
    Auth.fake(user: _user('u1'));
    expect(Gate.allows('monitors.create'), isTrue);
  });

  test('monitors.destroy denies when actor is not team owner', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'admin'),
    );
    expect(Gate.allows('monitors.destroy', _monitor('m_1', 'tm_1')), isFalse);
  });

  test('monitors.destroy allows owner of the same team', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'owner'),
    );
    expect(Gate.allows('monitors.destroy', _monitor('m_1', 'tm_1')), isTrue);
  });

  test('monitors.destroy denies cross-team owner', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_other', role: 'owner'),
    );
    expect(Gate.allows('monitors.destroy', _monitor('m_1', 'tm_1')), isFalse);
  });

  test('monitors.update allows any role within same team', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'member'),
    );
    expect(Gate.allows('monitors.update', _monitor('m_1', 'tm_1')), isTrue);
  });
}
