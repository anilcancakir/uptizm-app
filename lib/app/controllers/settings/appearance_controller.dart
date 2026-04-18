import 'package:magic/magic.dart';

import '../../models/appearance_settings.dart';

/// Workspace appearance (primary color + logo) controller.
///
/// `/settings/appearance` is a single-resource endpoint that patches the
/// current team record. 422 field errors surface via [ValidatesRequests].
class AppearanceController extends MagicController with ValidatesRequests {
  static AppearanceController get instance =>
      Magic.findOrPut(AppearanceController.new);

  AppearanceSettings? _settings;

  AppearanceSettings? get settings => _settings;

  Future<void> load() async {
    clearErrors();
    final response = await Http.get('/settings/appearance');
    if (!response.successful) return;
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return;
    _settings = AppearanceSettings.fromMap(data);
    refreshUI();
  }

  Future<bool> update(Map<String, dynamic> payload) async {
    clearErrors();
    final response = await Http.put('/settings/appearance', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('settings.appearance.errors.generic_update'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      _settings = AppearanceSettings.fromMap(data);
      refreshUI();
    }
    return true;
  }
}
