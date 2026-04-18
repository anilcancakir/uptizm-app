import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/status_pages/status_page_create_view.dart';
import '../../../resources/views/status_pages/status_page_list_view.dart';
import '../../../resources/views/status_pages/status_page_show_view.dart';
import '../../models/status_page.dart';

/// Status page CRUD + publish controller.
///
/// Owns the list in `rxState`; holds the currently inspected page in
/// `_detail` so show/edit screens can read fresh data without disturbing
/// the list feed.
class StatusPagesController extends MagicController
    with
        MagicStateMixin<List<StatusPage>>,
        ValidatesRequests,
        ResourceController {
  static StatusPagesController get instance =>
      Magic.findOrPut(StatusPagesController.new);

  /// Only `index`, `create`, and `show` are wired today; the edit screen
  /// is not implemented yet.
  @override
  Set<String> get resourceMethods => const {'index', 'create', 'show'};

  /// Route entry points. Kept alongside the data methods so the controller
  /// stays the single entry point for the status-pages resource.
  @override
  Widget index() => const StatusPageListView();
  @override
  Widget create() => const StatusPageCreateView();
  @override
  Widget show(String id) => StatusPageShowView(statusPageId: id);

  StatusPage? _detail;
  bool _isSubmitting = false;

  List<StatusPage> get pages => rxState ?? const [];
  StatusPage? get detail => _detail;
  bool get isSubmitting => _isSubmitting;

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

  /// Typed create wrapper used by [StatusPageCreateView]. Builds the API
  /// payload, guards concurrent submits, and flips [isSubmitting] so the
  /// view can render a loading button without owning any flag.
  Future<StatusPage?> submitCreate({
    required String title,
    required String slug,
    required String primaryColor,
    String? logoPath,
    required bool isPublic,
    required List<String> monitorIds,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    try {
      return await store({
        'title': title.trim(),
        'slug': slug.trim(),
        'primary_color': primaryColor,
        'is_public': isPublic,
        'monitor_ids': monitorIds,
        'logo_path': ?logoPath,
      });
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
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
