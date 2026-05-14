import 'package:magic/magic.dart';

/// Shared `Unique` async-rule resolver for status-page slug uniqueness.
///
/// Replaces the default `Unique` GET-style resolver with one that POSTs the
/// envelope `UniqueValidationController` (`POST /api/v1/validate/unique`)
/// expects: `{model: 'status_page', field, value, ?ignore_id}`.
///
/// Status code handling mirrors the default resolver's contract at
/// `references/magic/lib/src/validation/rules/unique.dart:118-122`: 422 is
/// the only authoritative "not unique" answer; anything outside the 2xx
/// success range (statusCode 0 for transport / offline failures, 5xx, etc.)
/// passes gracefully so a flaky network never blocks the form. The
/// server-side validator on submit remains the source of truth.
///
/// Pass [ignoreId] from edit flows so a record's own current slug never
/// 422s against itself when the user submits without changing it.
Future<bool> Function(String, String, dynamic) uniqueSlugResolver({
  String? ignoreId,
}) {
  return (String endpoint, String field, dynamic value) async {
    final response = await Http.post(
      endpoint,
      data: {
        'model': 'status_page',
        'field': field,
        'value': value,
        if (ignoreId != null && ignoreId.isNotEmpty) 'ignore_id': ignoreId,
      },
    );
    if (response.statusCode == 422) return false;
    if (!response.successful) return true;
    final body = response.data;
    return body is Map<String, dynamic> && body['unique'] == true;
  };
}
