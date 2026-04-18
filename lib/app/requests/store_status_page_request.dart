import 'package:magic/magic.dart';

/// Form request for `POST /status-pages`.
///
/// Mirrors the `StoreStatusPageRequest` on the API side: trims user strings,
/// drops a blank `logo_path` so the server never persists an empty hero,
/// and enforces presence of title/slug/primary_color/monitor_ids plus type
/// on `is_public`.
class StoreStatusPageRequest extends FormRequest {
  const StoreStatusPageRequest();

  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // 1. Trim user-entered strings so whitespace never reaches the wire.
    next['title'] = (next['title'] as String?)?.trim() ?? '';
    next['slug'] = (next['slug'] as String?)?.trim() ?? '';
    next['primary_color'] = (next['primary_color'] as String?)?.trim() ?? '';

    // 2. Drop logo_path entirely when blank (optional field, empty != unset).
    final logo = (next['logo_path'] as String?)?.trim();
    if (logo == null || logo.isEmpty) {
      next.remove('logo_path');
    } else {
      next['logo_path'] = logo;
    }

    return next;
  }

  @override
  Map<String, List<Rule>> rules() => {
    'title': [Required(), Max(120)],
    'slug': [Required(), Max(63)],
    'primary_color': [Required()],
    'is_public': [],
    'monitor_ids': [],
    'logo_path': [],
  };
}
