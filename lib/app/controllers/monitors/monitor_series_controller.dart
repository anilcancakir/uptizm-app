import 'package:magic/magic.dart';

import '../../helpers/http_cache.dart';
import '../../models/response_time_sample.dart';

/// Loads the response-time series powering the Performance chart on the
/// monitor show screen. The API collapses any amount of history into a
/// fixed sample budget per range, so the caller only picks the range.
class MonitorSeriesController extends MagicController
    with MagicStateMixin<List<ResponseTimeSample>> {
  static MonitorSeriesController get instance =>
      Magic.findOrPut(MonitorSeriesController.new);

  String? _currentMonitorId;
  String _currentRange = '24h';

  String? get currentMonitorId => _currentMonitorId;
  String get currentRange => _currentRange;
  List<ResponseTimeSample> get samples => rxState ?? const [];

  /// Loads the response-time series for a monitor + range, distinguishing
  /// empty (no samples) from error so the chart can render an empty state.
  Future<void> load(String monitorId, {String range = '24h'}) async {
    _currentMonitorId = monitorId;
    _currentRange = range;
    setLoading();
    final items = await _fetch(monitorId, range);
    if (items == null) {
      setError(trans('errors.unexpected'));
      return;
    }
    if (items.isEmpty) {
      setEmpty();
      return;
    }
    setSuccess(items);
  }

  /// Non-destructive refresh for live polling: preserves the existing
  /// samples on failure so the chart keeps rendering between ticks.
  Future<void> reload() async {
    final id = _currentMonitorId;
    if (id == null) return;
    final items = await _fetch(id, _currentRange);
    if (items == null) return;
    setSuccess(items);
  }

  Future<List<ResponseTimeSample>?> _fetch(
    String monitorId,
    String range,
  ) async {
    final response = await HttpCache.get(
      '/monitors/$monitorId/response-times',
      query: {'range': range},
    );
    if (!response.successful) return null;
    final raw = response.data?['data'];
    if (raw is! List) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ResponseTimeSample.fromMap)
        .whereType<ResponseTimeSample>()
        .toList();
  }
}
