import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/settings/settings_appearance_view.dart';
import '../../models/appearance_settings.dart';
import '../../requests/update_appearance_request.dart';

/// Workspace appearance (primary color + logo) controller.
///
/// `/settings/appearance` is a single-resource endpoint that patches the
/// current team record. 422 field errors surface via [ValidatesRequests].
class AppearanceController extends MagicController with ValidatesRequests {
  static AppearanceController get instance =>
      Magic.findOrPut(AppearanceController.new);

  /// Route entry point for `/settings/appearance`.
  Widget index() => const SettingsAppearanceView();

  AppearanceSettings? _settings;
  bool _isSubmitting = false;

  AppearanceSettings? get settings => _settings;
  bool get isSubmitting => _isSubmitting;

  /// Typed submit wrapper used by [SettingsAppearanceView]. Trims inputs,
  /// normalizes the optional logo, and guards concurrent submits.
  Future<bool> submit({required String primaryColor, String? logoPath}) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    refreshUI();
    try {
      final payload = const UpdateAppearanceRequest().validate({
        'appearance_primary_color': primaryColor,
        'appearance_logo_path': logoPath,
      });
      return await update(payload);
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Loads the current team's appearance settings into `_settings`.
  Future<void> load() async {
    clearErrors();
    final response = await Http.get('/settings/appearance');
    if (!response.successful) return;
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return;
    _settings = AppearanceSettings.fromMap(data);
    refreshUI();
  }

  /// Patches the current team's appearance settings with [payload].
  ///
  /// On success, refreshes `_settings` from the server response so derived
  /// UI reads the canonical stored values (not the submitted draft). Field
  /// errors surface through [handleApiError]; returns false without
  /// mutating state on failure.
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
