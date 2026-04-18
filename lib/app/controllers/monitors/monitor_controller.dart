import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../helpers/http_cache.dart';
import '../../enums/ai_mode.dart';
import '../../models/monitor.dart';
import '../../services/monitor_form_service.dart';
import '../../../resources/views/monitors/monitor_create_view.dart';
import '../../../resources/views/monitors/monitor_edit_view.dart';
import '../../../resources/views/monitors/monitor_list_view.dart';
import '../../../resources/views/monitors/monitor_show_view.dart';
import '../../../resources/views/components/monitors/monitor_form_shell.dart';

/// Laravel-style resource controller for the monitor domain.
///
/// Owns the view builders (index/show/create/edit) used by the router and
/// the load/store/update/destroy flows. The loaded [Monitor] lives in
/// `rxState` so show and edit surfaces share one payload.
class MonitorController extends MagicController
    with MagicStateMixin<Monitor?>, ValidatesRequests {
  static MonitorController get instance =>
      Magic.findOrPut(MonitorController.new);

  final MonitorFormService _formService = const MonitorFormService();

  bool _isSubmitting = false;
  bool _isDeleting = false;

  final ValueNotifier<List<Monitor>> list = ValueNotifier(const []);
  final ValueNotifier<bool> listLoading = ValueNotifier(false);
  final ValueNotifier<bool> listError = ValueNotifier(false);

  Monitor? get monitor => rxState;
  bool get isSubmitting => _isSubmitting;
  bool get isDeleting => _isDeleting;

  Widget index() => const MonitorListView();
  Widget show(String id) => MonitorShowView(monitorId: id);
  Widget create() => const MonitorCreateView();
  Widget edit(String id) => MonitorEditView(monitorId: id);

  Future<void> load(String id) async {
    clearErrors();
    await fetchOne('/monitors/$id', Monitor.fromMap);
  }

  /// Workspace-level monitor list, used by the list view and by the status
  /// page assign picker. Keeps its own notifiers so it does not collide with
  /// the single-entity `rxState` used by show/edit.
  Future<void> loadList() async {
    listLoading.value = true;
    listError.value = false;
    final response = await Http.get('/monitors');
    listLoading.value = false;
    if (!response.successful) {
      listError.value = true;
      return;
    }
    final raw = response.data?['data'];
    if (raw is! List) {
      list.value = const [];
      return;
    }
    list.value = raw
        .whereType<Map<String, dynamic>>()
        .map(Monitor.fromMap)
        .toList();
  }

  /// Non-destructive refresh for live polling: skips the loading flash, keeps
  /// the previous monitor on failure so the UI never flickers into an error
  /// or empty state between ticks.
  Future<void> reload(String id) async {
    final response = await HttpCache.get('/monitors/$id');
    if (!response.successful) return;
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return;
    setSuccess(Monitor.fromMap(data));
  }

  Future<Monitor?> store(MonitorFormValues values) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    clearErrors();
    try {
      final response = await Http.post(
        '/monitors',
        data: _formService.buildPayload(values, forCreate: true),
      );
      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('monitor.create.error_generic'),
        );
        return null;
      }
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        setError(trans('monitor.create.error_generic'));
        return null;
      }
      final monitor = Monitor.fromMap(data);
      setSuccess(monitor);
      return monitor;
    } catch (e, stackTrace) {
      Log.error('[MonitorController.store] $e\n$stackTrace');
      setError(trans('errors.unexpected'));
      return null;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  Future<Monitor?> update(String id, MonitorFormValues values) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    clearErrors();
    final previous = monitor;
    try {
      final response = await Http.put(
        '/monitors/$id',
        data: _formService.buildPayload(values, forCreate: false),
      );
      if (!response.successful) {
        handleApiError(response, fallback: trans('monitor.edit.error_generic'));
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        setError(trans('monitor.edit.error_generic'));
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final monitor = Monitor.fromMap(data);
      setSuccess(monitor);
      return monitor;
    } catch (e, stackTrace) {
      Log.error('[MonitorController.update] $e\n$stackTrace');
      setError(trans('errors.unexpected'));
      setState(previous, status: rxStatus, notify: false);
      return null;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Per-monitor AI mode patch used by the monitor detail card.
  ///
  /// Sends only `ai_mode` so the endpoint's other validators do not fire
  /// against stale form values. Returns the persisted [AiMode] on success.
  Future<AiMode?> updateAiMode(String id, AiMode mode) async {
    clearErrors();
    final previous = monitor;
    final response = await Http.put(
      '/monitors/$id',
      data: {'ai_mode': mode.name},
    );
    if (!response.successful) {
      handleApiError(response, fallback: trans('monitor.edit.error_generic'));
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      setSuccess(Monitor.fromMap(data));
    }
    return mode;
  }

  Future<bool> destroy(String id) async {
    if (_isDeleting) return false;
    _isDeleting = true;
    refreshUI();
    clearErrors();
    final previous = monitor;
    try {
      final response = await Http.delete('/monitors/$id');
      if (!response.successful) {
        handleApiError(response, fallback: trans('monitor.edit.error_delete'));
        setState(previous, status: rxStatus, notify: false);
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      Log.error('[MonitorController.destroy] $e\n$stackTrace');
      setError(trans('errors.unexpected'));
      setState(previous, status: rxStatus, notify: false);
      return false;
    } finally {
      _isDeleting = false;
      refreshUI();
    }
  }
}
