import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/status_pages/status_page_create_view.dart';
import '../../../resources/views/status_pages/status_page_edit_view.dart';
import '../../../resources/views/status_pages/status_page_list_view.dart';
import '../../../resources/views/status_pages/status_page_show_view.dart';
import '../../models/status_page.dart';
import '../../requests/store_status_page_request.dart';
import '../../requests/update_status_page_request.dart';

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

  @override
  Set<String> get resourceMethods => const {'index', 'create', 'show', 'edit'};

  /// Route entry points. Kept alongside the data methods so the controller
  /// stays the single entry point for the status-pages resource.
  @override
  Widget index() => const StatusPageListView();
  @override
  Widget create() => const StatusPageCreateView();
  @override
  Widget show(String id) => StatusPageShowView(statusPageId: id);
  @override
  Widget edit(String id) => StatusPageEditView(statusPageId: id);

  StatusPage? _detail;
  bool _isSubmitting = false;

  List<StatusPage> get pages => rxState ?? const [];
  StatusPage? get detail => _detail;
  bool get isSubmitting => _isSubmitting;

  /// Loads the status page list into `rxState`.
  Future<void> load() async {
    clearErrors();
    await fetchList<StatusPage>('/status-pages', StatusPage.fromMap);
  }

  /// Loads a single status page into `_detail` for the show / edit screens.
  ///
  /// Keeps the existing list in `rxState` intact — the detail fetch must not
  /// disturb the feed so the user can back out without a reload.
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

  /// Uploads a logo image and returns the stored disk path. The caller
  /// stashes the returned path and submits it as `logo_path` on the
  /// next create/update. Returns null on failure and surfaces a toast
  /// so the view never needs to own the error text.
  Future<String?> uploadLogo(MagicFile file) async {
    clearErrors();
    final response = await Http.upload(
      '/status-pages/logos',
      data: const {},
      files: {'logo': file},
    );
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('status_page.errors.generic_logo_upload'),
      );
      Magic.toast(
        response.errorMessage ??
            trans('status_page.errors.generic_logo_upload'),
      );
      return null;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return null;
    return data['logo_path'] as String?;
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
    List<String> metricIds = const [],
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const StoreStatusPageRequest().validate({
          'title': title,
          'slug': slug,
          'primary_color': primaryColor,
          'is_public': isPublic,
          'monitor_ids': monitorIds,
          'metric_ids': metricIds,
          'logo_path': logoPath,
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

  /// Creates a status page and prepends it to the list so the new page
  /// appears at the top of the feed immediately. Restores the previous
  /// list on failure.
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

  /// Patches a status page, replaces it in the list in place, and refreshes
  /// `_detail` if the updated page is the one being inspected.
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

  /// Deletes a status page after the caller has confirmed. Clears `_detail`
  /// if the deleted page was being inspected so the show screen can pop.
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

  /// Typed update wrapper used by [StatusPageEditView]. Validates through
  /// [UpdateStatusPageRequest] so absent keys stay absent (partial patch),
  /// guards concurrent submits, and returns the refreshed page on success.
  Future<StatusPage?> submitUpdate({
    required String id,
    required String title,
    required String slug,
    required String primaryColor,
    String? logoPath,
    required bool isPublic,
    required List<String> monitorIds,
    required List<String> metricIds,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const UpdateStatusPageRequest().validate({
          'title': title,
          'slug': slug,
          'primary_color': primaryColor,
          'is_public': isPublic,
          'monitor_ids': monitorIds,
          'metric_ids': metricIds,
          'logo_path': ?logoPath,
        });
      } on ValidationException catch (e) {
        validationErrors = Map<String, String>.from(e.errors);
        refreshUI();
        return null;
      }
      return await update(id, payload);
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Publishes a status page (flips visibility + snapshots the current
  /// monitor selection server-side). Returns true even when the response
  /// omits the updated record so the UI can optimistically advance.
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

  /// Unpublishes a status page (flips `is_public` to false). Mirrors
  /// [publish] — same response shape, same optimistic list refresh.
  Future<bool> unpublish(String id) async {
    clearErrors();
    final previous = List<StatusPage>.from(pages);
    final response = await Http.post('/status-pages/$id/unpublish');
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('status_page.errors.generic_unpublish'),
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

  /// Rotates the preview token server-side, returning the fresh value.
  /// Callers (the show screen) refresh the detail afterwards so the new
  /// token is reflected in the copy-link button.
  Future<String?> rotatePreviewToken(String id) async {
    clearErrors();
    final response = await Http.post('/status-pages/$id/preview-token/rotate');
    if (!response.successful) {
      handleApiError(response, fallback: trans('errors.unexpected'));
      return null;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return null;
    final updated = StatusPage.fromMap(data);
    if (_detail?.id == updated.id) {
      _detail = updated;
      refreshUI();
    }
    return updated.previewToken;
  }
}
