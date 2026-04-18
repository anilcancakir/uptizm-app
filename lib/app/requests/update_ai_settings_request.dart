import 'package:magic/magic.dart';

import '../enums/ai_mode.dart';

/// Form request for `PUT /settings/ai`.
///
/// Accepts either an [AiMode] instance or the wire string (`off`, `suggest`,
/// `auto`) and always emits the normalized wire name. `ai_daily_digest_enabled`
/// must be a bool; server-side typing rejects anything else regardless.
class UpdateAiSettingsRequest extends FormRequest {
  const UpdateAiSettingsRequest();

  /// Normalizes the incoming [data] before rule validation. Collapses
  /// [AiMode] instances to their wire name so `rules()` only has to
  /// whitelist a single representation.
  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // Collapse enum instances down to their wire name so rules() only has
    // to whitelist a single representation.
    final mode = next['ai_mode'];
    if (mode is AiMode) {
      next['ai_mode'] = mode.name;
    }

    return next;
  }

  /// Validation rules mirroring the server-side `UpdateAiSettingsRequest`.
  @override
  Map<String, List<Rule>> rules() => {
    'ai_mode': [Required(), InList<AiMode>(AiMode.values)],
    'ai_daily_digest_enabled': [],
  };
}
