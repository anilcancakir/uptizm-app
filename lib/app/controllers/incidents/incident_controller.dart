import 'package:magic/magic.dart';

import '../../enums/incident_severity.dart';
import '../../enums/incident_status.dart';
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
  bool _isDrafting = false;

  List<Incident> get incidents => rxState ?? const [];
  Incident? get detail => _detail;
  bool get isSubmitting => _isSubmitting;
  bool get isDrafting => _isDrafting;

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
  /// Never touches `rxState` / `rxStatus`. The drawer opens on top of a live
  /// list; flipping the mixin's status to loading here would wipe the
  /// underlying list render ("All clear" flash) until the detail lands.
  Future<void> loadOne(String id) async {
    clearErrors();
    final response = await Http.get('/incidents/$id');
    if (!response.successful) {
      return;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      return;
    }
    _detail = Incident.fromMap(data);
    refreshUI();
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

  /// Posts a public-facing incident update.
  ///
  /// Atomic on the backend: writes an `IncidentUpdate` row on the public
  /// stream, transitions the incident status when it moved, and fans out
  /// subscriber notifications. The drawer and the status page read from
  /// the same `updates` relation, so both see the new entry on next
  /// rebuild.
  ///
  /// Pushes the parsed [IncidentUpdate] and the derived status into
  /// `_detail.updates` + `_detail.status` and mirrors the change to the
  /// list entry when the incident is visible in the current feed.
  Future<bool> postUpdate({
    required String id,
    required IncidentStatus status,
    required String body,
    bool deliverNotifications = true,
  }) async {
    clearErrors();
    final response = await Http.post(
      '/incidents/$id/updates',
      data: {
        'status': status.name,
        'body': body,
        'deliver_notifications': deliverNotifications,
      },
    );
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('incident.errors.generic_update'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      return true;
    }
    final update = IncidentUpdate.fromMap(data);

    // 1. Detail pane: append the update and reflect the new status.
    if (_detail?.id == id) {
      _detail = _detail!.copyWith(
        status: status,
        updates: [..._detail!.updates, update],
        resolvedAt: status == IncidentStatus.resolved
            ? (_detail!.resolvedAt ?? DateTime.now())
            : _detail!.resolvedAt,
      );
    }

    // 2. List mirror: keep the monitor tab and dashboard feed in sync.
    final list = List<Incident>.from(incidents);
    final idx = list.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final current = list[idx];
      list[idx] = current.copyWith(
        status: status,
        updates: [...current.updates, update],
        resolvedAt: status == IncidentStatus.resolved
            ? (current.resolvedAt ?? DateTime.now())
            : current.resolvedAt,
      );
      setState(list, status: RxStatus.success(), notify: false);
    }

    refreshUI();
    return true;
  }

  /// Asks the backend drafter agent to polish the incident title AND
  /// description together, from the "Report incident" composer, before
  /// any incident row has been created. Returns a `(title, description)`
  /// record on success so the composer can replace both fields in one
  /// gesture. Returns `null` on 429 (with a toast) or network error.
  Future<({String title, String description})?> draftIncidentBundle({
    required String monitorId,
    required String severity,
    required String title,
    required String description,
    String? metricKey,
  }) async {
    if (_isDrafting) return null;
    _isDrafting = true;
    refreshUI();
    try {
      final response = await Http.post(
        '/monitors/$monitorId/incidents/draft',
        data: {
          'severity': severity,
          'title': title,
          'description': description,
          'metric_key': ?metricKey,
        },
      );
      if (response.statusCode == 429) {
        Magic.toast(trans('incident.update.ai_limit_reached'));
        return null;
      }
      if (!response.successful) {
        Magic.toast(trans('incident.update.ai_error'));
        return null;
      }
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final t = data['title'];
      final d = data['description'];
      if (t is! String || d is! String) {
        return null;
      }
      return (title: t, description: d);
    } finally {
      _isDrafting = false;
      refreshUI();
    }
  }

  /// Asks the backend drafter agent for a polished (or generated) update
  /// body the operator can drop into the composer. Returns the drafted
  /// text on success, `null` on failure. 429 surfaces as a toast and
  /// returns null without throwing so the caller just re-enables its
  /// button.
  ///
  /// `intent` is the status pill the operator selected in the composer;
  /// `none` is accepted for "note only" entries that do not transition
  /// the incident.
  Future<String?> draftUpdate({
    required String id,
    required String intent,
    required String userDraft,
  }) async {
    if (_isDrafting) return null;
    _isDrafting = true;
    refreshUI();
    try {
      final response = await Http.post(
        '/incidents/$id/updates/draft',
        data: {'status': intent, 'body': userDraft},
      );
      if (response.statusCode == 429) {
        Magic.toast(trans('incident.update.ai_limit_reached'));
        return null;
      }
      if (!response.successful) {
        Magic.toast(trans('incident.update.ai_error'));
        return null;
      }
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final body = data['body'];
      return body is String ? body : null;
    } finally {
      _isDrafting = false;
      refreshUI();
    }
  }
}
