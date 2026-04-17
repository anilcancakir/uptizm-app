/// Lowercase, ASCII-only, hyphen-joined slug. Strips everything outside
/// `[a-z0-9-]`, collapses consecutive hyphens, trims leading/trailing
/// hyphens, and caps at 40 characters. Used by the status-page subdomain
/// preview (`<slug>.uptizm.com`).
String slugify(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-|-$'), '');
  if (s.length > 40) s = s.substring(0, 40);
  s = s.replaceAll(RegExp(r'-$'), '');
  return s;
}

/// Returns an i18n key describing the slug problem, or `null` if valid.
String? validateSlug(String value) {
  if (value.isEmpty) return 'status_page.validation.slug_required';
  if (value.length < 3) return 'status_page.validation.slug_too_short';
  if (value.length > 40) return 'status_page.validation.slug_too_long';
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
    return 'status_page.validation.slug_format';
  }
  if (value.startsWith('-') || value.endsWith('-')) {
    return 'status_page.validation.slug_format';
  }
  return null;
}
