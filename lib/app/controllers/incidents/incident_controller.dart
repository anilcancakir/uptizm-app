import 'package:magic/magic.dart';

import '../../models/incident.dart';

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

  List<Incident> get incidents => rxState ?? const [];
  Incident? get detail => _detail;

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
