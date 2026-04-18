import 'package:magic/magic.dart';

import '../../helpers/http_cache.dart';
import '../../models/metric_preview_result.dart';
import '../../models/monitor_metric.dart';
import '../../models/monitor_metric_value.dart';

/// Nested CRUD over `/monitors/{monitor}/metrics` plus a read-only
/// time-series fetch for the metric detail sheet.
///
/// The controller owns the current monitor's metric list in `rxState`.
/// Mutations restore the previous list on failure so validation errors
/// surface without wiping the UI.
class MonitorMetricController extends MagicController
    with MagicStateMixin<List<MonitorMetric>>, ValidatesRequests {
  static MonitorMetricController get instance =>
      Magic.findOrPut(MonitorMetricController.new);

  String? _currentMonitorId;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  String? get currentMonitorId => _currentMonitorId;
  List<MonitorMetric> get metrics => rxState ?? const [];
  bool get isSubmitting => _isSubmitting;
  bool get isDeleting => _isDeleting;

  Map<String, List<MonitorMetric>> get groups {
    final grouped = <String, List<MonitorMetric>>{};
    for (final metric in metrics) {
      final key = metric.groupName ?? '';
      grouped.putIfAbsent(key, () => []).add(metric);
    }
    return grouped;
  }

  Future<void> load(String monitorId) async {
    _currentMonitorId = monitorId;
    clearErrors();
    await fetchList('/monitors/$monitorId/metrics', MonitorMetric.fromMap);
  }

  /// Non-destructive refresh for live polling: swap the list in place without
  /// flipping `rxStatus` back to loading / empty. Failures are swallowed so
  /// the UI keeps rendering the last-good list between ticks.
  Future<void> reload(String monitorId) async {
    final response = await HttpCache.get('/monitors/$monitorId/metrics');
    if (!response.successful) return;
    final raw = response.data?['data'];
    if (raw is! List) return;
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map(MonitorMetric.fromMap)
        .toList();
    setSuccess(items);
  }

  Future<MonitorMetric?> store(
    String monitorId,
    Map<String, dynamic> payload,
  ) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    clearErrors();
    final previous = rxState;
    try {
      final response = await Http.post(
        '/monitors/$monitorId/metrics',
        data: payload,
      );
      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('metric.errors.generic_create'),
        );
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        setError(trans('metric.errors.generic_create'));
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final metric = MonitorMetric.fromMap(data);
      await load(monitorId);
      return metric;
    } catch (e, stackTrace) {
      Log.error('[MonitorMetricController.store] $e\n$stackTrace');
      setError(trans('errors.unexpected'));
      setState(previous, status: rxStatus, notify: false);
      return null;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  Future<MonitorMetric?> update(
    String monitorId,
    String metricId,
    Map<String, dynamic> payload,
  ) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    clearErrors();
    final previous = rxState;
    try {
      final response = await Http.put(
        '/monitors/$monitorId/metrics/$metricId',
        data: payload,
      );
      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('metric.errors.generic_update'),
        );
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        setError(trans('metric.errors.generic_update'));
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final metric = MonitorMetric.fromMap(data);
      await load(monitorId);
      return metric;
    } catch (e, stackTrace) {
      Log.error('[MonitorMetricController.update] $e\n$stackTrace');
      setError(trans('errors.unexpected'));
      setState(previous, status: rxStatus, notify: false);
      return null;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  Future<bool> destroy(String monitorId, String metricId) async {
    if (_isDeleting) return false;
    _isDeleting = true;
    refreshUI();
    clearErrors();
    final previous = rxState;
    try {
      final response = await Http.delete(
        '/monitors/$monitorId/metrics/$metricId',
      );
      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('metric.errors.generic_delete'),
        );
        setState(previous, status: rxStatus, notify: false);
        return false;
      }
      await load(monitorId);
      return true;
    } catch (e, stackTrace) {
      Log.error('[MonitorMetricController.destroy] $e\n$stackTrace');
      setError(trans('errors.unexpected'));
      setState(previous, status: rxStatus, notify: false);
      return false;
    } finally {
      _isDeleting = false;
      refreshUI();
    }
  }

  /// Dispatch a draft extraction rule to the server and receive a fresh
  /// fetch + extracted value back. Used by the form's live preview
  /// before the metric is persisted. Returns null on network or
  /// server-level failures so the UI can show a generic error; the
  /// extraction-level error field on the response carries user-facing
  /// detail when the request itself succeeded.
  Future<MetricPreviewResult?> preview(
    String monitorId, {
    required String source,
    required String extractionPath,
    required String type,
  }) async {
    final response = await Http.post(
      '/monitors/$monitorId/metrics/preview',
      data: {'source': source, 'extraction_path': extractionPath, 'type': type},
    );
    if (!response.successful) return null;
    final data = response.data;
    if (data is! Map<String, dynamic>) return null;
    return MetricPreviewResult.fromMap(data);
  }

  Future<List<MonitorMetricValue>> series(
    String monitorId,
    String metricId, {
    String range = '24h',
  }) async {
    final response = await Http.get(
      '/monitors/$monitorId/metrics/$metricId/series',
      query: {'range': range},
    );
    if (!response.successful) return const [];
    final raw = response.data?['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MonitorMetricValue.fromMap)
        .toList();
  }
}
