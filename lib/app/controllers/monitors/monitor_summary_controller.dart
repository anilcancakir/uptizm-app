import 'package:magic/magic.dart';

import '../../helpers/http_cache.dart';
import '../../models/monitor_summary.dart';

/// Loads the aggregate stats (uptime %, avg response, incidents, MTTR)
/// shown in the Overview tab's KPI grid. Range-scoped: callers pass one
/// of `24h | 7d | 30d | 90d`; unknown values are normalised to `24h` by
/// the API.
class MonitorSummaryController extends MagicController
    with MagicStateMixin<MonitorSummary> {
  static MonitorSummaryController get instance =>
      Magic.findOrPut(MonitorSummaryController.new);

  String? _currentMonitorId;
  String _currentRange = '24h';

  String? get currentMonitorId => _currentMonitorId;
  String get currentRange => _currentRange;
  MonitorSummary? get summary => rxState;

  /// Loads the aggregate KPI summary (uptime, avg response, incidents, MTTR)
  /// for a monitor scoped to the given time range.
  Future<void> load(String monitorId, {String range = '24h'}) async {
    _currentMonitorId = monitorId;
    _currentRange = range;
    setLoading();
    final response = await Http.get(
      '/monitors/$monitorId/summary',
      query: {'range': range},
    );
    if (!response.successful) {
      setError(trans('errors.unexpected'));
      return;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('errors.unexpected'));
      return;
    }
    setSuccess(MonitorSummary.fromMap(data));
  }

  /// Non-destructive refresh for live polling: keeps the last-good value
  /// on any failure so the KPI grid does not flash empty between ticks.
  Future<void> reload() async {
    final id = _currentMonitorId;
    if (id == null) return;
    final response = await HttpCache.get(
      '/monitors/$id/summary',
      query: {'range': _currentRange},
    );
    if (!response.successful) return;
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return;
    setSuccess(MonitorSummary.fromMap(data));
  }
}
