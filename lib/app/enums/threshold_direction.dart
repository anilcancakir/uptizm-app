/// Which side of the numeric range counts as "bad" for a threshold band.
///
/// [highBad] means higher values trigger warn/critical (e.g. latency).
/// [lowBad] means lower values trigger warn/critical (e.g. free-memory).
enum ThresholdDirection {
  highBad,
  lowBad;

  String get labelKey => 'monitor.metric_form.direction.$name';
  String get hintKey => 'monitor.metric_form.direction_hint.$name';

  /// Validate that warn/critical bounds are ordered correctly for [dir].
  /// Returns null when valid, otherwise an i18n key describing the error.
  static String? validate(
    ThresholdDirection dir,
    double warn,
    double critical,
  ) {
    return switch (dir) {
      ThresholdDirection.highBad =>
        warn < critical
            ? null
            : 'monitor.metric_form.direction_validation.high_bad',
      ThresholdDirection.lowBad =>
        warn > critical
            ? null
            : 'monitor.metric_form.direction_validation.low_bad',
    };
  }
}
