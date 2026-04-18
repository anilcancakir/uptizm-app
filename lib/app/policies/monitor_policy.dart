import 'package:magic/magic.dart';

import '../models/monitor.dart';
import '../models/user.dart';

/// Authorization rules for the monitor domain.
///
/// Registered via `GateServiceProvider.boot()` under namespaced abilities
/// so UI affordances can gate on `Gate.allows('monitors.destroy', monitor)`.
/// Tenant check keeps stale cross-team references from rendering mutating
/// controls, and the role check limits destructive ops to team owners.
class MonitorPolicy {
  const MonitorPolicy();

  /// Register all monitor abilities on the global [Gate].
  void register() {
    Gate.define('monitors.create', (user, _) => _authed(user));
    Gate.define('monitors.update', (user, monitor) => _sameTeam(user, monitor));
    Gate.define(
      'monitors.destroy',
      (user, monitor) => _isOwner(user) && _sameTeam(user, monitor),
    );
  }

  bool _authed(dynamic user) => user is User && user.id.isNotEmpty;

  bool _sameTeam(dynamic user, dynamic monitor) {
    if (user is! User || monitor is! Monitor) return false;
    final teamId = user.currentTeam?.id;
    if (teamId == null || teamId.isEmpty) return false;
    return teamId == monitor.teamId;
  }

  bool _isOwner(dynamic user) {
    if (user is! User) return false;
    return user.currentTeam?.userRole == 'owner';
  }
}
