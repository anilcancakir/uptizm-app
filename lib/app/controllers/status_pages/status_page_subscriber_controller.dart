import 'package:magic/magic.dart';

import '../../models/status_page_subscriber.dart';

/// Admin-side controller for managing a status page's email subscribers.
///
/// Public subscribe endpoints (confirm / unsubscribe) are hit by the
/// Blade SSR side, not from the app. The app only needs to list, export,
/// and manually remove entries — hence the minimal surface.
class StatusPageSubscriberController extends MagicController
    with MagicStateMixin<List<StatusPageSubscriber>>, ValidatesRequests {
  static StatusPageSubscriberController get instance =>
      Magic.findOrPut(StatusPageSubscriberController.new);

  String? _statusPageId;

  List<StatusPageSubscriber> get subscribers => rxState ?? const [];
  String? get statusPageId => _statusPageId;

  /// Loads every subscriber for the given status page into `rxState`.
  Future<void> load(String statusPageId) async {
    _statusPageId = statusPageId;
    clearErrors();
    await fetchList<StatusPageSubscriber>(
      '/status-pages/$statusPageId/subscribers',
      StatusPageSubscriber.fromMap,
    );
  }

  /// Manually removes a subscriber. Optimistic: pops the entry locally,
  /// restores on failure.
  Future<bool> remove(String subscriberId) async {
    final pageId = _statusPageId;
    if (pageId == null) return false;
    clearErrors();
    final previous = List<StatusPageSubscriber>.from(subscribers);
    final next = previous.where((s) => s.id != subscriberId).toList();
    setSuccess(next);
    final response = await Http.delete(
      '/status-pages/$pageId/subscribers/$subscriberId',
    );
    if (!response.successful) {
      handleApiError(response, fallback: trans('subscriber.errors.remove'));
      setState(previous, status: rxStatus, notify: true);
      return false;
    }
    return true;
  }
}
