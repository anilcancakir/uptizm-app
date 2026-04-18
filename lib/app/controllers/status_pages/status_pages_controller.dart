import 'package:magic/magic.dart';

import '../../models/status_page.dart';

/// Status page CRUD + publish controller.
///
/// Owns the list in `rxState`; holds the currently inspected page in
/// `_detail` so show/edit screens can read fresh data without disturbing
/// the list feed.
class StatusPagesController extends MagicController
    with MagicStateMixin<List<StatusPage>>, ValidatesRequests {
  static StatusPagesController get instance =>
      Magic.findOrPut(StatusPagesController.new);

  StatusPage? _detail;

  List<StatusPage> get pages => rxState ?? const [];
  StatusPage? get detail => _detail;

  Future<void> load() async {
    clearErrors();
    await fetchList<StatusPage>('/status-pages', StatusPage.fromMap);
  }

  Future<void> loadOne(String id) async {
    clearErrors();
    setLoading();
    final response = await Http.get('/status-pages/$id');
    if (!response.successful) {
      setError(
        response.errorMessage ?? trans('status_page.errors.generic_load'),
      );
      return;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('status_page.errors.generic_load'));
      return;
    }
    _detail = StatusPage.fromMap(data);
    setState(pages, status: RxStatus.success(), notify: true);
  }

  Future<StatusPage?> store(Map<String, dynamic> payload) async {
    clearErrors();
    final previous = List<StatusPage>.from(pages);
    final response = await Http.post('/status-pages', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('status_page.errors.generic_create'),
      );
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('status_page.errors.generic_create'));
      return null;
    }
    final created = StatusPage.fromMap(data);
    setSuccess([created, ...previous]);
    return created;
  }

  Future<StatusPage?> update(String id, Map<String, dynamic> payload) async {
    clearErrors();
    final previous = List<StatusPage>.from(pages);
    final response = await Http.put('/status-pages/$id', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('status_page.errors.generic_update'),
      );
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      setError(trans('status_page.errors.generic_update'));
      setState(previous, status: rxStatus, notify: false);
      return null;
    }
    final updated = StatusPage.fromMap(data);
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

  Future<bool> destroy(String id) async {
    clearErrors();
    final previous = List<StatusPage>.from(pages);
    final response = await Http.delete('/status-pages/$id');
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('status_page.errors.generic_delete'),
      );
      return false;
    }
    setSuccess(previous.where((p) => p.id != id).toList());
    if (_detail?.id == id) {
      _detail = null;
    }
    return true;
  }

  Future<bool> publish(String id) async {
    clearErrors();
    final previous = List<StatusPage>.from(pages);
    final response = await Http.post('/status-pages/$id/publish');
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('status_page.errors.generic_publish'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      return true;
    }
    final updated = StatusPage.fromMap(data);
    final next = [
      for (final item in previous)
        if (item.id == updated.id) updated else item,
    ];
    setSuccess(next);
    if (_detail?.id == updated.id) {
      _detail = updated;
    }
    return true;
  }
}
