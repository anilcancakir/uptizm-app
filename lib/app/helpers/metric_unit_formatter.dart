import '../enums/metric_unit.dart';

/// Rendered representation of a numeric metric value.
class FormattedMetric {
  const FormattedMetric({required this.value, required this.suffix});

  /// Formatted number portion (e.g. `"7.76"`, `"1.2k"`, `"900"`).
  final String value;

  /// Unit suffix (e.g. `"GB"`, `"ms"`, `"%"`) — empty string when there is
  /// nothing to append (unlabeled `count`, `custom` without a label).
  final String suffix;

  /// Convenience `"value suffix"` or `"value"` when the suffix is empty.
  String get combined => suffix.isEmpty ? value : '$value $suffix';
}

/// Scales and labels numeric metric samples per their [MetricUnit].
///
/// Auto variants (`bytes_auto`, `duration_auto`) pick the best scale per
/// sample; fixed variants always render in the requested unit. `custom`
/// falls back to a user-supplied freetext suffix.
class MetricUnitFormatter {
  const MetricUnitFormatter._();

  static const int _bytesBase = 1024;
  static const List<String> _byteSuffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// Format [value] according to [unit].
  ///
  /// [customLabel] is the freetext suffix from the metric's `unit` column;
  /// only used when [unit] is [MetricUnit.custom].
  static FormattedMetric format(
    double value,
    MetricUnit unit, {
    String? customLabel,
    int precision = 2,
  }) {
    return switch (unit) {
      MetricUnit.bytesAuto => _bytesAuto(value, precision),
      MetricUnit.byte => _fixed(value, 1, 'B', precision),
      MetricUnit.kilobyte => _fixed(
        value,
        _bytesBase.toDouble(),
        'KB',
        precision,
      ),
      MetricUnit.megabyte => _fixed(
        value,
        _bytesBase * _bytesBase.toDouble(),
        'MB',
        precision,
      ),
      MetricUnit.gigabyte => _fixed(
        value,
        _bytesBase * _bytesBase * _bytesBase.toDouble(),
        'GB',
        precision,
      ),
      MetricUnit.terabyte => _fixed(
        value,
        _bytesBase * _bytesBase * _bytesBase * _bytesBase.toDouble(),
        'TB',
        precision,
      ),
      MetricUnit.durationAuto => _durationAuto(value, precision),
      MetricUnit.millisecond => _fixed(value, 1, 'ms', precision),
      MetricUnit.second => _fixed(value, 1000, 's', precision),
      MetricUnit.minute => _fixed(value, 60_000, 'min', precision),
      MetricUnit.hour => _fixed(value, 3_600_000, 'hr', precision),
      MetricUnit.percent => FormattedMetric(
        value: _trim(value, precision),
        suffix: '%',
      ),
      MetricUnit.ratio => FormattedMetric(
        value: _trim(value * 100, precision),
        suffix: '%',
      ),
      MetricUnit.count => FormattedMetric(
        value: _trim(value, 0),
        suffix: customLabel ?? '',
      ),
      MetricUnit.countShort => _countShort(value, precision),
      MetricUnit.custom => FormattedMetric(
        value: _trim(value, precision),
        suffix: customLabel ?? '',
      ),
    };
  }

  static FormattedMetric _bytesAuto(double value, int precision) {
    // 1. Negative or zero falls straight to plain bytes — avoids log(0).
    if (value <= 0) {
      return FormattedMetric(value: _trim(value, 0), suffix: 'B');
    }
    var scaled = value;
    var index = 0;
    while (scaled >= _bytesBase && index < _byteSuffixes.length - 1) {
      scaled /= _bytesBase;
      index++;
    }
    return FormattedMetric(
      value: _trim(scaled, index == 0 ? 0 : precision),
      suffix: _byteSuffixes[index],
    );
  }

  static FormattedMetric _durationAuto(double valueMs, int precision) {
    if (valueMs < 1000) {
      return FormattedMetric(value: _trim(valueMs, 0), suffix: 'ms');
    }
    final seconds = valueMs / 1000;
    if (seconds < 60) {
      return FormattedMetric(value: _trim(seconds, precision), suffix: 's');
    }
    final minutes = seconds / 60;
    if (minutes < 60) {
      return FormattedMetric(value: _trim(minutes, precision), suffix: 'min');
    }
    return FormattedMetric(value: _trim(minutes / 60, precision), suffix: 'hr');
  }

  static FormattedMetric _fixed(
    double value,
    double divisor,
    String suffix,
    int precision,
  ) {
    return FormattedMetric(
      value: _trim(value / divisor, precision),
      suffix: suffix,
    );
  }

  static FormattedMetric _countShort(double value, int precision) {
    final abs = value.abs();
    if (abs < 1000) {
      return FormattedMetric(value: _trim(value, 0), suffix: '');
    }
    const suffixes = ['k', 'M', 'B', 'T'];
    var scaled = value;
    var index = -1;
    while (scaled.abs() >= 1000 && index < suffixes.length - 1) {
      scaled /= 1000;
      index++;
    }
    return FormattedMetric(
      value: _trim(scaled, precision),
      suffix: suffixes[index],
    );
  }

  /// Strip trailing zeros when the scaled value is an integer, otherwise
  /// cap at [precision] digits.
  static String _trim(double value, int precision) {
    if (precision <= 0 || value == value.truncateToDouble()) {
      return value.truncateToDouble().toStringAsFixed(0);
    }
    return value.toStringAsFixed(precision);
  }
}
