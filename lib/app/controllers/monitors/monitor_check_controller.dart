import 'package:magic/magic.dart';

import '../../helpers/http_cache.dart';
import '../../models/monitor_check.dart';

/// Read-only list of a monitor's recent checks. Backs the Recent Checks
/// panel on the monitor show screen. Live polling calls [reload] to swap
/// the list in place without flipping back to loading.
class MonitorCheckController extends MagicController
    with MagicStateMixin<List<MonitorCheck>> {
  static MonitorCheckController get instance =>
      Magic.findOrPut(MonitorCheckController.new);

  String? _currentMonitorId;

  String? get currentMonitorId => _currentMonitorId;
  List<MonitorCheck> get checks => rxState ?? const [];

  Future<void> load(String monitorId, {int perPage = 20}) async {
    _currentMonitorId = monitorId;
    await fetchList(
      '/monitors/$monitorId/checks?per_page=$perPage',
      MonitorCheck.fromMap,
    );
  }

  Future<void> reload(String monitorId, {int perPage = 20}) async {
    final response = await HttpCache.get(
      '/monitors/$monitorId/checks',
      query: {'per_page': perPage.toString()},
    );
    if (!response.successful) return;
    final raw = response.data?['data'];
    if (raw is! List) return;
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map(MonitorCheck.fromMap)
        .toList();
    setSuccess(items);
  }
}
