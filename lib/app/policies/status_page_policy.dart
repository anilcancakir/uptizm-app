import 'package:magic/magic.dart';

import '../models/status_page.dart';
import '../models/user.dart';

/// Authorization rules for the status page domain.
///
/// Publish and destroy require admin-or-owner role in the same team;
/// update follows the same rule so member-level accounts cannot rename
/// or repaint a shared page. Abilities are namespaced
/// (`status-pages.publish`) to avoid colliding with monitor/incident
/// ability names on the global [Gate].
class StatusPagePolicy {
  const StatusPagePolicy();

  static const _managerRoles = {'owner', 'admin'};

  /// Register all status page abilities on the global [Gate].
  void register() {
    Gate.define('status-pages.create', (user, _) => _authed(user));
    Gate.define(
      'status-pages.update',
      (user, page) => _isManager(user) && _sameTeam(user, page),
    );
    Gate.define(
      'status-pages.destroy',
      (user, page) => _isManager(user) && _sameTeam(user, page),
    );
    Gate.define(
      'status-pages.publish',
      (user, page) => _isManager(user) && _sameTeam(user, page),
    );
  }

  bool _authed(dynamic user) => user is User && user.id.isNotEmpty;

  bool _sameTeam(dynamic user, dynamic page) {
    if (user is! User || page is! StatusPage) return false;
    final teamId = user.currentTeam?.id;
    if (teamId == null || teamId.isEmpty) return false;
    return teamId == page.teamId;
  }

  bool _isManager(dynamic user) {
    if (user is! User) return false;
    return _managerRoles.contains(user.currentTeam?.userRole);
  }
}
