import 'package:magic/magic.dart';

import '../../enums/incident_impact.dart';
import '../../enums/incident_severity.dart';
import '../../enums/incident_status.dart';
import '../../models/incident.dart';
import '../../requests/publish_postmortem_request.dart';
import '../../requests/store_incident_request.dart';
import '../../requests/store_incident_update_request.dart';

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
    if (data is Map<String, dynamic> && _detail?.id == id) {
      _detail = _detail!.copyWith(
        events: [..._detail!.events, IncidentEvent.fromMap(data)],
      );
      refreshUI();
    }
    return true;
  }

  /// Posts a public update to the incident's reverse-chrono update stream.
  ///
  /// Validates via [StoreIncidentUpdateRequest] so the status enum collapses
  /// to its snake_case wire value and `deliver_notifications` defaults to
  /// true. When the target incident is open in the detail pane, the
  /// returned update is appended in place so the UI reflects the new row
  /// without a follow-up round-trip.
  Future<IncidentUpdate?> postUpdate({
    required String incidentId,
    required IncidentStatus status,
    required String body,
    bool deliverNotifications = true,
    List<Map<String, dynamic>> affectedComponents = const [],
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const StoreIncidentUpdateRequest().validate({
          'status': status,
          'body': body,
          'deliver_notifications': deliverNotifications,
          'affected_components': affectedComponents,
        });
      } on ValidationException catch (e) {
        validationErrors = Map<String, String>.from(e.errors);
        refreshUI();
        return null;
      }
      clearErrors();
      final response = await Http.post(
        '/incidents/$incidentId/updates',
        data: payload,
      );
      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('incident.errors.generic_update'),
        );
        return null;
      }
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return null;
      final created = IncidentUpdate.fromMap(data);
      if (_detail?.id == incidentId) {
        _detail = _detail!.copyWith(
          status: created.status,
          updates: [created, ..._detail!.updates],
        );
        refreshUI();
      }
      return created;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Flips an incident from draft to public. Updates both the detail pane
  /// and the corresponding list entry so the Drafts tab empties as the
  /// Active tab grows.
  Future<bool> publish(String id) async {
    clearErrors();
    final response = await Http.post('/incidents/$id/publish');
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('incident.errors.generic_update'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      _reconcileOne(Incident.fromMap(data));
    }
    return true;
  }

  /// Publishes the incident postmortem. `notify` defaults to false so the
  /// subscriber fan-out is opt-in on postmortem publishes.
  Future<bool> publishPostmortem({
    required String incidentId,
    required String body,
    bool notify = false,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const PublishPostmortemRequest().validate({
          'body': body,
          'notify': notify,
        });
      } on ValidationException catch (e) {
        validationErrors = Map<String, String>.from(e.errors);
        refreshUI();
        return false;
      }
      clearErrors();
      final response = await Http.post(
        '/incidents/$incidentId/postmortem',
        data: payload,
      );
      if (!response.successful) {
        handleApiError(
          response,
          fallback: trans('incident.errors.generic_update'),
        );
        return false;
      }
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        _reconcileOne(Incident.fromMap(data));
      }
      return true;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Manually pins the incident impact, flipping `impact_override` on so
  /// the server-side rollup stops re-deriving it from affected monitors.
  Future<bool> overrideImpact({
    required String incidentId,
    required IncidentImpact impact,
  }) async {
    clearErrors();
    final response = await Http.post(
      '/incidents/$incidentId/impact',
      data: {'impact': impact.name},
    );
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('incident.errors.generic_update'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      _reconcileOne(Incident.fromMap(data));
    }
    return true;
  }

  /// Replaces the matching list entry in place and swaps `_detail` when
  /// it's the currently open incident. Used by publish / postmortem /
  /// impact endpoints that return the full incident resource.
  void _reconcileOne(Incident incident) {
    final next = [
      for (final item in incidents)
        if (item.id == incident.id) incident else item,
    ];
    setSuccess(next);
    if (_detail?.id == incident.id) {
      _detail = incident;
    }
  }

  /// Fetches AI-surfaced similar past incidents for the detail panel.
  ///
  /// Returns an empty list instead of throwing when the backend is offline
  /// or returns a non-list payload, because "similar" is a nice-to-have
  /// surface and must not block the incident detail from rendering.
  Future<List<SimilarIncident>> similar(String id) async {
    final response = await Http.get('/incidents/$id/similar');
    if (!response.successful) return const [];
    final raw = response.data?['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SimilarIncident.fromMap)
        .toList();
  }
}
