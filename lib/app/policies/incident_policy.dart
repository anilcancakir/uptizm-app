import 'package:magic/magic.dart';

import '../models/incident.dart';
import '../models/user.dart';

/// Authorization rules for the incident domain.
///
/// Any team member can log a manual incident, but only managers (owner /
/// admin) can amend a persisted one. Tenant check stays in place so a stale
/// cross-team incident reference cannot accidentally expose mutating
/// affordances.
class IncidentPolicy {
  const IncidentPolicy();

  static const _managerRoles = {'owner', 'admin'};

  /// Register all incident abilities on the global [Gate].
  void register() {
    Gate.define('incidents.create', (user, _) => _authed(user));
    Gate.define(
      'incidents.update',
      (user, incident) => _isManager(user) && _sameTeam(user, incident),
    );
  }

  bool _authed(dynamic user) => user is User && user.id.isNotEmpty;

  bool _sameTeam(dynamic user, dynamic incident) {
    if (user is! User || incident is! Incident) return false;
    final teamId = user.currentTeam?.id;
    if (teamId == null || teamId.isEmpty) return false;
    return teamId == incident.teamId;
  }

  bool _isManager(dynamic user) {
    if (user is! User) return false;
    return _managerRoles.contains(user.currentTeam?.userRole);
  }
}
