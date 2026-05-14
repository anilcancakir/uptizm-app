import 'package:magic/magic.dart';

import '_unique_slug_resolver.dart';

/// Form request for `PATCH /status-pages/{id}`.
///
/// Mirrors the `UpdateStatusPageRequest` on the API side: only present
/// keys are forwarded so partial edits never clear unrelated fields.
/// Keys absent from the submitted map remain untouched on the server.
class UpdateStatusPageRequest extends FormRequest {
  const UpdateStatusPageRequest();

  /// Run the partial-update validation pipeline including the async slug
  /// uniqueness probe scoped to [pageId]. Edit flows call this instead of
  /// the inherited sync `validate(data)` so the `Unique` rule actually
  /// fires and the controller's POST envelope receives `ignore_id`.
  Future<Map<String, dynamic>> validateForUpdate(
    Map<String, dynamic> data, {
    required String pageId,
  }) async {
    if (!authorize()) {
      throw const AuthorizationException();
    }
    final normalized = prepared(data);
    final rulesWithSlug = {
      ...rules(),
      'slug': [
        Max(63),
        Unique(
          '/validate/unique',
          field: 'slug',
        ).via(uniqueSlugResolver(ignoreId: pageId)),
      ],
    };
    return Validator.make(normalized, rulesWithSlug).validateAsync();
  }

  /// Normalizes the incoming [data] before rule validation. Trims string
  /// fields in place and removes the `logo_path` key when blank so the
  /// server does not interpret empty as a clear.
  @override
  Map<String, dynamic> prepared(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // 1. Trim string fields only when the caller supplied them — absent
    //    keys must stay absent so the server leaves the column alone.
    for (final key in const ['title', 'slug', 'primary_color']) {
      if (next.containsKey(key)) {
        final trimmed = (next[key] as String?)?.trim();
        if (trimmed == null || trimmed.isEmpty) {
          next.remove(key);
        } else {
          next[key] = trimmed;
        }
      }
    }

    // 2. Drop logo_path when blank so the server never persists an empty
    //    hero path, but keep it absent entirely when the caller never set it.
    if (next.containsKey('logo_path')) {
      final logo = (next['logo_path'] as String?)?.trim();
      if (logo == null || logo.isEmpty) {
        next.remove('logo_path');
      } else {
        next['logo_path'] = logo;
      }
    }

    return next;
  }

  /// Validation rules mirroring the server-side `UpdateStatusPageRequest`.
  /// All fields are optional — the server treats absent keys as no-op.
  @override
  Map<String, List<Rule>> rules() => {
    'title': [Max(120)],
    'slug': [Max(63)],
    'primary_color': [],
    'is_public': [],
    'monitor_ids': [],
    'metric_ids': [],
    'logo_path': [],
  };
}
