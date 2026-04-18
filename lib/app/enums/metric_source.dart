/// Where in an HTTP response a custom metric value should be extracted from.
enum MetricSource {
  jsonPath,
  regex,
  xpath,
  header,
  httpStatus;

  String get labelKey => 'monitor.metric_form.source.$name';
  String get placeholderKey => 'monitor.metric_form.source_placeholder.$name';
}
