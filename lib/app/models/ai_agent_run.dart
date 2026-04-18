/// One AI agent invocation record (read-only audit log entry).
///
/// Mirrors `AiAgentRunResource` on the API. `status` is kept as a raw
/// string (pending/succeeded/failed); views key off the value without a
/// dedicated enum.
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
  final DateTime? startedAt;
  final DateTime? completedAt;

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
}
