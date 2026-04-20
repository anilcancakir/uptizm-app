import 'package:magic/magic.dart';

import '../../enums/incident_severity.dart';
import '../../models/incident.dart';
import '../../requests/store_incident_request.dart';

/// Workspace-scoped incident controller.
///
/// Owns the incident list in `rxState` and keeps the currently inspected
/// incident in `_detail` for the detail panel. `load` accepts optional
/// `monitorId` / `status` filters so the same controller backs both the
/// dashboard feed and the monitor Incidents tab.
class IncidentController extends MagicController
    with MagicStateMixin<List<Incident>>, ValidatesRequests {
  static IncidentController get instance =>
      Magic.findOrPut(IncidentController.new);

  Incident? _detail;
  bool _isSubmitting = false;

  List<Incident> get incidents => rxState ?? const [];
  Incident? get detail => _detail;
  bool get isSubmitting => _isSubmitting;

  /// Typed create wrapper used by the incident composer sheet. Builds the
  /// API payload, guards concurrent submits, and flips [isSubmitting].
  Future<Incident?> submitCreate({
    required String monitorId,
    required String title,
    required IncidentSeverity severity,
    String description = '',
    String? metricKey,
    bool notifyTeam = true,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const StoreIncidentRequest().validate({
          'monitor_id': monitorId,
          'title': title,
          'severity': severity,
          'description': description,
          'metric_key': metricKey,
          'notify_team': notifyTeam,
        });
      } on ValidationException catch (e) {
        validationErrors = Map<String, String>.from(e.errors);
        refreshUI();
        return null;
      }
      return await store(payload);
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Loads the incident list, optionally scoped to a monitor or status.
  ///
  /// Backs both the dashboard feed (no filter) and the monitor Incidents tab
  /// (monitor-scoped). Results land in `rxState`; errors surface through
  /// `RxStatus.error` via [fetchList].
  Future<void> load({String? monitorId, String? status}) async {
    clearErrors();
    final query = <String, dynamic>{
      'monitor_id': ?monitorId,
      'status': ?status,
    };
    await fetchList<Incident>(
      '/incidents',
      Incident.fromMap,
      query: query.isEmpty ? null : query,
    );
  }

  /// Fetches a single incident into `_detail` for the detail panel.
  ///
  /// Leaves the list untouched (notifies with the current `incidents`) so the
  /// surrounding list view does not re-render while a detail is opened.
  Future<void> loadOne(String id) async {
    clearErrors();
    setLoading();
    final response = await Http.get('/incidents/$id');
    if (!response.successful) {
      setError(response.errorMessage ?? trans('incident.errors.generic_load'));
      return;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('incident.errors.generic_load'));
      return;
    }
    _detail = Incident.fromMap(data);
    setState(incidents, status: RxStatus.success(), notify: true);
  }

  /// Creates an incident and prepends it to the list on success.
  ///
  /// Expects a payload already produced by [StoreIncidentRequest]; 422 errors
  /// surface as field errors via [handleApiError]. On failure the previous
  /// list is restored without notifying so the UI does not flicker.
  Future<Incident?> store(Map<String, dynamic> payload) async {
    clearErrors();
    final previous = List<Incident>.from(incidents);
    final response = await Http.post('/incidents', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('incident.errors.generic_create'),
      );
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('incident.errors.generic_create'));
      return null;
    }
    final created = Incident.fromMap(data);
    setSuccess([created, ...previous]);
    return created;
  }

  /// Patches an incident and reconciles both the list and the detail pane.
  ///
  /// Replaces the matching entry in place (order preserved) and swaps
  /// `_detail` when the updated entity is the one currently displayed.
  Future<Incident?> update(String id, Map<String, dynamic> payload) async {
    clearErrors();
    final previous = List<Incident>.from(incidents);
    final response = await Http.put('/incidents/$id', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('incident.errors.generic_update'),
      );
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('incident.errors.generic_update'));
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final updated = Incident.fromMap(data);
    final next = [
      for (final item in previous)
        if (item.id == updated.id) updated else item,
    ];
    setSuccess(next);
    if (_detail?.id == updated.id) {
      _detail = updated;
    }
    return updated;
  }

  /// Appends a timeline event (note, ack, status change) to an incident.
  ///
  /// Pushes the returned event into `_detail.events` only when the target
  /// incident is the one currently open, so off-screen incidents are not
  /// mutated under the caller's feet.
  Future<bool> addEvent(String id, Map<String, dynamic> payload) async {
    clearErrors();
    final response = await Http.post('/incidents/$id/events', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('incident.errors.generic_event'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      return true;
    }
    final event = IncidentEvent.fromMap(data);

    // 1. Detail pane open → push into its stream so /incidents/:id updates.
    if (_detail?.id == id) {
      _detail = _detail!.copyWith(events: [..._detail!.events, event]);
    }

    // 2. Drawer reads from the list, not from _detail. Update the matching
    //    list entry so monitor tab sheets reflect the new event on rebuild.
    final list = List<Incident>.from(incidents);
    final idx = list.indexWhere((i) => i.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(events: [...list[idx].events, event]);
      setState(list, status: RxStatus.success(), notify: false);
    }

    refreshUI();
    return true;
  }
}
