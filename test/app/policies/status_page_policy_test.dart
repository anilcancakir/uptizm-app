import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';

import 'package:app/app/models/status_page.dart';
import 'package:app/app/models/user.dart';
import 'package:app/app/policies/status_page_policy.dart';

User _user(String id, {String? teamId, String? role}) {
  return User.fromMap({
    'id': id,
    'name': 'Test',
    'email': 'test@example.com',
    if (teamId != null)
      'current_team': {'id': teamId, 'name': 'Team', 'user_role': role},
  });
}

StatusPage _page(String id, String? teamId) {
  return StatusPage(
    id: id,
    title: 'Page',
    slug: 'page',
    primaryColor: '#2563EB',
    isPublic: false,
    teamId: teamId,
  );
}

void main() {
  setUp(() {
    MagicApp.reset();
    Magic.flush();
    Gate.flush();
    const StatusPagePolicy().register();
  });

  tearDown(() {
    Auth.unfake();
    Gate.flush();
  });

  test('status-pages.publish allows admin in same team', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'admin'),
    );
    expect(Gate.allows('status-pages.publish', _page('sp_1', 'tm_1')), isTrue);
  });

  test('status-pages.publish allows owner in same team', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'owner'),
    );
    expect(Gate.allows('status-pages.publish', _page('sp_1', 'tm_1')), isTrue);
  });

  test('status-pages.publish denies plain member', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'member'),
    );
    expect(Gate.allows('status-pages.publish', _page('sp_1', 'tm_1')), isFalse);
  });

  test('status-pages.publish denies admin on foreign team', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_other', role: 'admin'),
    );
    expect(Gate.allows('status-pages.publish', _page('sp_1', 'tm_1')), isFalse);
  });

  test('status-pages.publish denies when page has no team id', () {
    Auth.fake(
      user: _user('u1', teamId: 'tm_1', role: 'admin'),
    );
    expect(Gate.allows('status-pages.publish', _page('sp_1', null)), isFalse);
  });
}
