/// Categorical grouping for [MetricUnit] — drives the form's picker sections.
enum MetricUnitKind {
  size,
  duration,
  percent,
  ratio,
  count,
  custom;

  String get labelKey => 'monitor.metric_form.unit_kind.kind.$name';
}

/// Unit formatting strategy for a numeric metric. The wire value is the
/// PHP backing string (snake_case) so the picker can round-trip via
/// [MetricUnit.values.byName].
enum MetricUnit {
  bytesAuto,
  byte,
  kilobyte,
  megabyte,
  gigabyte,
  terabyte,
  durationAuto,
  millisecond,
  second,
  minute,
  hour,
  percent,
  ratio,
  count,
  countShort,
  custom;

  String get labelKey => 'monitor.metric_form.unit_kind.unit.$name';

  /// Which logical group this unit belongs to (drives the picker layout).
  MetricUnitKind get kind => switch (this) {
    MetricUnit.bytesAuto ||
    MetricUnit.byte ||
    MetricUnit.kilobyte ||
    MetricUnit.megabyte ||
    MetricUnit.gigabyte ||
    MetricUnit.terabyte => MetricUnitKind.size,
    MetricUnit.durationAuto ||
    MetricUnit.millisecond ||
    MetricUnit.second ||
    MetricUnit.minute ||
    MetricUnit.hour => MetricUnitKind.duration,
    MetricUnit.percent => MetricUnitKind.percent,
    MetricUnit.ratio => MetricUnitKind.ratio,
    MetricUnit.count || MetricUnit.countShort => MetricUnitKind.count,
    MetricUnit.custom => MetricUnitKind.custom,
  };

  /// True when the unit auto-selects the best scale (e.g. bytes_auto picks
  /// between B/KB/MB/.../TB per-sample).
  bool get isAuto =>
      this == MetricUnit.bytesAuto || this == MetricUnit.durationAuto;

  /// Wire value (PHP backing string).
  String get wire => switch (this) {
    MetricUnit.bytesAuto => 'bytes_auto',
    MetricUnit.byte => 'byte',
    MetricUnit.kilobyte => 'kilobyte',
    MetricUnit.megabyte => 'megabyte',
    MetricUnit.gigabyte => 'gigabyte',
    MetricUnit.terabyte => 'terabyte',
    MetricUnit.durationAuto => 'duration_auto',
    MetricUnit.millisecond => 'millisecond',
    MetricUnit.second => 'second',
    MetricUnit.minute => 'minute',
    MetricUnit.hour => 'hour',
    MetricUnit.percent => 'percent',
    MetricUnit.ratio => 'ratio',
    MetricUnit.count => 'count',
    MetricUnit.countShort => 'count_short',
    MetricUnit.custom => 'custom',
  };

  static MetricUnit? fromWire(String? raw) {
    if (raw == null) return null;
    return switch (raw) {
      'bytes_auto' => MetricUnit.bytesAuto,
      'byte' => MetricUnit.byte,
      'kilobyte' => MetricUnit.kilobyte,
      'megabyte' => MetricUnit.megabyte,
      'gigabyte' => MetricUnit.gigabyte,
      'terabyte' => MetricUnit.terabyte,
      'duration_auto' => MetricUnit.durationAuto,
      'millisecond' => MetricUnit.millisecond,
      'second' => MetricUnit.second,
      'minute' => MetricUnit.minute,
      'hour' => MetricUnit.hour,
      'percent' => MetricUnit.percent,
      'ratio' => MetricUnit.ratio,
      'count' => MetricUnit.count,
      'count_short' => MetricUnit.countShort,
      'custom' => MetricUnit.custom,
      _ => null,
    };
  }
}
