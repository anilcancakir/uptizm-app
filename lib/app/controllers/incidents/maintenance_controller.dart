import 'package:magic/magic.dart';

import '../../models/incident.dart';
import '../../requests/schedule_maintenance_request.dart';

/// Scheduled-maintenance controller.
///
/// Maintenance shares the `incidents` table with realtime incidents on
/// the API side (discriminated by `kind == maintenance`), so this
/// controller stays a thin CRUD wrapper around `/maintenance` and
/// reuses the [Incident] model. The dedicated facade keeps the admin
/// surface cognitively separate from the incident feed.
class MaintenanceController extends MagicController
    with MagicStateMixin<List<Incident>>, ValidatesRequests {
  static MaintenanceController get instance =>
      Magic.findOrPut(MaintenanceController.new);

  Incident? _detail;
  bool _isSubmitting = false;

  List<Incident> get windows => rxState ?? const [];
  Incident? get detail => _detail;
  bool get isSubmitting => _isSubmitting;

  /// Loads scheduled windows. `lane` accepts `upcoming` / `in_progress` /
  /// `history` and maps to the server-side filter; omit for all.
  Future<void> load({String? lane}) async {
    clearErrors();
    await fetchList<Incident>(
      '/maintenance',
      Incident.fromMap,
      query: lane == null ? null : {'lane': lane},
    );
  }

  Future<void> loadOne(String id) async {
    clearErrors();
    setLoading();
    final response = await Http.get('/maintenance/$id');
    if (!response.successful) {
      setError(response.errorMessage ?? trans('maintenance.errors.load'));
      return;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('maintenance.errors.load'));
      return;
    }
    _detail = Incident.fromMap(data);
    setState(windows, status: RxStatus.success(), notify: true);
  }

  /// Typed create wrapper used by the maintenance composer. Validates via
  /// [ScheduleMaintenanceRequest] and prepends the created window on
  /// success.
  Future<Incident?> submitCreate({
    required String title,
    required DateTime scheduledFor,
    required DateTime scheduledUntil,
    required List<String> monitorIds,
    String body = '',
    bool notifyAtStart = true,
    bool notifyAtEnd = true,
    String? maintenanceState,
    String? operationalState,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const ScheduleMaintenanceRequest().validate({
          'title': title,
          'scheduled_for': scheduledFor,
          'scheduled_until': scheduledUntil,
          'monitor_ids': monitorIds,
          'body': body,
          'auto_transition_deliver_notifications_at_start': notifyAtStart,
          'auto_transition_deliver_notifications_at_end': notifyAtEnd,
          'auto_transition_to_maintenance_state': maintenanceState,
          'auto_transition_to_operational_state': operationalState,
        });
      } on ValidationException catch (e) {
        validationErrors = Map<String, String>.from(e.errors);
        refreshUI();
        return null;
      }
      clearErrors();
      final previous = List<Incident>.from(windows);
      final response = await Http.post('/maintenance', data: payload);
      if (!response.successful) {
        handleApiError(response, fallback: trans('maintenance.errors.create'));
        setState(previous, status: rxStatus, notify: false);
        return null;
      }
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        setError(trans('maintenance.errors.create'));
        return null;
      }
      final created = Incident.fromMap(data);
      setSuccess([created, ...previous]);
      return created;
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Cancels a scheduled window before it runs. The API transitions the
  /// row to `completed` with a cancellation update; we reconcile the
  /// local list in place.
  Future<bool> cancel(String id) async {
    clearErrors();
    final response = await Http.post('/maintenance/$id/cancel');
    if (!response.successful) {
      handleApiError(response, fallback: trans('maintenance.errors.cancel'));
      return false;
    }
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      final updated = Incident.fromMap(data);
      final next = [
        for (final item in windows)
          if (item.id == updated.id) updated else item,
      ];
      setSuccess(next);
      if (_detail?.id == updated.id) {
        _detail = updated;
      }
    }
    return true;
  }
}
