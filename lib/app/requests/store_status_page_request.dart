import 'package:magic/magic.dart';

import '_unique_slug_resolver.dart';

/// Form request for `POST /status-pages`.
///
/// Mirrors the `StoreStatusPageRequest` on the API side: trims user strings,
/// drops a blank `logo_path` so the server never persists an empty hero,
/// and enforces presence of title/slug/primary_color/monitor_ids plus type
/// on `is_public`. Slug uniqueness is probed async via the magic `Unique`
/// rule against `POST /validate/unique`.
class StoreStatusPageRequest extends FormRequest {
  const StoreStatusPageRequest();

  /// Run authorize → prepare → validate (sync + async). Mirrors the magic
  /// FormRequest's `validate(data)` shape, but invokes `Validator.validateAsync`
  /// so the `Unique` slug rule actually fires. Sync-only `validate(data)`
  /// silently skips async rules per their contract.
  Future<Map<String, dynamic>> validateAsync(Map<String, dynamic> data) async {
    if (!authorize()) {
      throw const AuthorizationException();
    }
    final normalized = prepared(data);
    return Validator.make(normalized, rules()).validateAsync();
  }

  /// Normalizes the incoming [data] before rule validation. Trims the
  /// required string fields and drops a blank logo path so the server
  /// never persists an empty hero.
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

  /// Validation rules mirroring the server-side `StoreStatusPageRequest`.
  @override
  Map<String, List<Rule>> rules() => {
    'title': [Required(), Max(120)],
    'slug': [
      Required(),
      Max(63),
      Unique('/validate/unique', field: 'slug').via(uniqueSlugResolver()),
    ],
    'primary_color': [Required()],
    'is_public': [],
    'monitor_ids': [],
    'metric_ids': [],
    'logo_path': [],
  };
}
