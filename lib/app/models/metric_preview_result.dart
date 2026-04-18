/// Response shape of `POST /monitors/{monitor}/metrics/preview`.
///
/// Read-only view object consumed by the metric form's live-preview
/// card. `statusCode` / `latencyMs` come from the fresh HTTP fetch
/// performed server-side; `extractedValue` is the raw string the
/// extraction rule yielded, `typeValid` reflects whether that value
/// matches the declared metric type, and `error` carries a
/// human-readable reason when extraction itself failed.
class MetricPreviewResult {
  const MetricPreviewResult({
    required this.statusCode,
    required this.latencyMs,
    required this.extractedValue,
    required this.typeValid,
    required this.error,
  });

  final int? statusCode;
  final int latencyMs;
  final String? extractedValue;
  final bool typeValid;
  final String? error;

  /// True when the extraction rule actually yielded a value, even if the
  /// type validation failed. The preview card uses this to pick between the
  /// "no match" empty state and the value + validity chip.
  bool get hasValue => extractedValue != null;

  /// Parses the preview endpoint response.
  static MetricPreviewResult fromMap(Map<String, dynamic> map) {
    return MetricPreviewResult(
      statusCode: map['status_code'] as int?,
      latencyMs: (map['latency_ms'] as num?)?.toInt() ?? 0,
      extractedValue: map['extracted_value'] as String?,
      typeValid: map['type_valid'] as bool? ?? false,
      error: map['error'] as String?,
    );
  }
}
