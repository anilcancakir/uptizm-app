import 'package:magic/magic.dart';

import '../../models/ai_settings.dart';

/// Workspace-level AI settings controller.
///
/// Owns the single [AiSettings] payload; `load` + `update` mirror the
/// `/settings/ai` resource endpoints. 422 field errors surface via
/// `ValidatesRequests`.
class AiSettingsController extends MagicController with ValidatesRequests {
  static AiSettingsController get instance =>
      Magic.findOrPut(AiSettingsController.new);

  AiSettings? _settings;

  AiSettings? get settings => _settings;

  Future<void> load() async {
    clearErrors();
    final response = await Http.get('/settings/ai');
    if (!response.successful) return;
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return;
    _settings = AiSettings.fromMap(data);
    refreshUI();
  }

  Future<bool> update(Map<String, dynamic> payload) async {
    clearErrors();
    final response = await Http.put('/settings/ai', data: payload);
    if (!response.successful) {
      handleApiError(
        response,
        fallback: trans('settings.ai.errors.generic_update'),
      );
      return false;
    }
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      _settings = AiSettings.fromMap(data);
      refreshUI();
    }
    return true;
  }
}
