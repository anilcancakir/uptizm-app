import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/settings/settings_ai_view.dart';
import '../../enums/ai_mode.dart';
import '../../models/ai_settings.dart';
import '../../requests/update_ai_settings_request.dart';

/// Workspace-level AI settings controller.
///
/// Owns the single [AiSettings] payload; `load` + `update` mirror the
/// `/settings/ai` resource endpoints. 422 field errors surface via
/// `ValidatesRequests`.
class AiSettingsController extends MagicController with ValidatesRequests {
  static AiSettingsController get instance =>
      Magic.findOrPut(AiSettingsController.new);

  /// Route entry point for `/settings/ai`.
  Widget index() => const SettingsAiView();

  AiSettings? _settings;
  bool _isSubmitting = false;

  AiSettings? get settings => _settings;
  bool get isSubmitting => _isSubmitting;

  /// Typed submit wrapper used by [SettingsAiView]. Wraps [update] with an
  /// `isSubmitting` guard so the view only needs to read the flag.
  Future<bool> submit({
    required AiMode aiMode,
    required bool weeklyDigest,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    refreshUI();
    try {
      final Map<String, dynamic> payload;
      try {
        payload = const UpdateAiSettingsRequest().validate({
          'ai_mode': aiMode,
          'ai_weekly_digest_enabled': weeklyDigest,
        });
      } on ValidationException catch (e) {
        validationErrors = Map<String, String>.from(e.errors);
        refreshUI();
        return false;
      }
      return await update(payload);
    } finally {
      _isSubmitting = false;
      refreshUI();
    }
  }

  /// Loads the current team's AI settings into `_settings`.
  ///
  /// Silently returns on failure so the view can render its skeleton state
  /// without special-casing network errors.
  Future<void> load() async {
    clearErrors();
    final response = await Http.get('/settings/ai');
    if (!response.successful) return;
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return;
    _settings = AiSettings.fromMap(data);
    refreshUI();
  }

  /// Patches `/settings/ai` with [payload] and refreshes `_settings` from
  /// the server response on success. Field errors surface through
  /// [handleApiError]; returns false on failure.
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
