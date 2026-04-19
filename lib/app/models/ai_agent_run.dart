/// One AI agent invocation record (read-only audit log entry).
///
/// Mirrors `AiAgentRunResource` on the API. `status` is kept as a raw
/// string (pending/succeeded/failed); views key off the value without a
/// dedicated enum. `inputPrompt`, `outputText`, and `structuredOutput`
/// back the expandable detail row in the activity view.
class AiAgentRun {
  const AiAgentRun({
    required this.id,
    required this.agentName,
    required this.status,
    this.monitorId,
    this.incidentId,
    this.suggestionId,
    this.provider,
    this.model,
    this.tokensInput,
    this.tokensOutput,
    this.costUsd,
    this.durationMs,
    this.errorMessage,
    this.inputPrompt,
    this.outputText,
    this.structuredOutput,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String agentName;
  final String status;
  final String? monitorId;
  final String? incidentId;
  final String? suggestionId;
  final String? provider;
  final String? model;
  final int? tokensInput;
  final int? tokensOutput;
  final double? costUsd;
  final int? durationMs;
  final String? errorMessage;
  final String? inputPrompt;
  final String? outputText;
  final Map<String, dynamic>? structuredOutput;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// True when the structured output explicitly says an anomaly was found.
  /// Null when the agent did not emit the flag (e.g. failed runs).
  bool? get anomalyDetected => structuredOutput?['anomaly_detected'] as bool?;

  /// Metric key the anomaly was attributed to, sanitized by the backend
  /// against the monitor's real key list.
  String? get structuredMetricKey => structuredOutput?['metric_key'] as String?;

  /// Severity the agent assigned to an anomaly (critical / warn / info).
  String? get structuredSeverity => structuredOutput?['severity'] as String?;

  /// Confidence label the agent emitted (high / medium / low).
  String? get structuredConfidence =>
      structuredOutput?['confidence'] as String?;

  /// One-line summary the agent wrote; used for incident title / suggestion blurb.
  String? get structuredTldr => structuredOutput?['tldr'] as String?;

  /// Parses an `AiAgentRunResource` payload. Status defaults to `pending`
  /// when missing; numeric fields silently coerce from numbers or strings.
  static AiAgentRun fromMap(Map<String, dynamic> map) {
    return AiAgentRun(
      id: map['id']?.toString() ?? '',
      agentName: (map['agent_name'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      monitorId: map['monitor_id']?.toString(),
      incidentId: map['incident_id']?.toString(),
      suggestionId: map['suggestion_id']?.toString(),
      provider: map['provider'] as String?,
      model: map['model'] as String?,
      tokensInput: _int(map['tokens_input']),
      tokensOutput: _int(map['tokens_output']),
      costUsd: _double(map['cost_usd']),
      durationMs: _int(map['duration_ms']),
      errorMessage: map['error_message'] as String?,
      inputPrompt: map['input_prompt'] as String?,
      outputText: map['output_text'] as String?,
      structuredOutput: _map(map['structured_output']),
      startedAt: _date(map['started_at']),
      completedAt: _date(map['completed_at']),
    );
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static double? _double(Object? raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static DateTime? _date(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static Map<String, dynamic>? _map(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }
}
