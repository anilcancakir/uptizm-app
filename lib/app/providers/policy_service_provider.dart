import 'package:magic/magic.dart';

import '../policies/incident_policy.dart';
import '../policies/monitor_policy.dart';
import '../policies/status_page_policy.dart';

/// Registers domain authorization policies on the global [Gate].
///
/// Runs in `boot()` so [Auth.user] is available by the time any policy
/// callback fires. Policies are namespaced on the ability key
/// (`monitors.destroy`, `status-pages.publish`, ...) to avoid collisions
/// across domains — Magic's Gate dispatches by ability string, not by
/// argument type.
class PolicyServiceProvider extends ServiceProvider {
  PolicyServiceProvider(super.app);

  @override
  void register() {}

  @override
  Future<void> boot() async {
    const MonitorPolicy().register();
    const StatusPagePolicy().register();
    const IncidentPolicy().register();
  }
}
