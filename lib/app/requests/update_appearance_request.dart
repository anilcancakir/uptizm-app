import 'package:magic/magic.dart';

/// Form request for `PUT /settings/appearance`.
///
/// Trims the hex color, normalizes a blank logo path to an explicit `null`
/// (the API uses `null` to mean "clear logo"), and enforces presence of
/// the primary color.
class UpdateAppearanceRequest extends FormRequest {
  const UpdateAppearanceRequest();

  /// Normalizes the incoming [data] before rule validation. Trims the hex
  /// color and rewrites a blank logo path to an explicit null so the API
  /// distinguishes "clear logo" from "not provided".
  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    next['appearance_primary_color'] =
        (next['appearance_primary_color'] as String?)?.trim() ?? '';

    // Explicit null signals "clear logo" to the server; empty string would
    // otherwise serialize as a live value.
    final logo = (next['appearance_logo_path'] as String?)?.trim();
    next['appearance_logo_path'] = (logo == null || logo.isEmpty) ? null : logo;

    return next;
  }

  /// Validation rules mirroring the server-side `UpdateAppearanceRequest`.
  @override
  Map<String, List<Rule>> rules() => {
    'appearance_primary_color': [Required()],
    'appearance_logo_path': [],
  };
}
