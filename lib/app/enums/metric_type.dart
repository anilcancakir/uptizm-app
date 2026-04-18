/// Response metric classification used by the Metrics tab mockup.
enum MetricType {
  numeric,
  status,
  string;

  String get labelKey => 'monitor.metric_form.type.$name';

  /// Validate a metric key. Returns null when valid, otherwise an i18n key.
  ///
  /// Rules: lowercase snake_case, must start with a letter, max 40 chars.
  static String? validateMetricKey(String key) {
    if (key.isEmpty) return 'monitor.metric_form.key_validation.required';
    if (key.length > 40) return 'monitor.metric_form.key_validation.too_long';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(key)) {
      return 'monitor.metric_form.key_validation.format';
    }
    return null;
  }
}

/// Threshold band shown as a status dot on numeric metric cards.
enum MetricBand {
  ok,
  warn,
  critical;

  String get toneKey => switch (this) {
    MetricBand.ok => 'up',
    MetricBand.warn => 'degraded',
    MetricBand.critical => 'down',
  };
}
