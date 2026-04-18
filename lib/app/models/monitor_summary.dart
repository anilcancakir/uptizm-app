/// Aggregate stats for a monitor's Overview tab. Mirrors the JSON
/// returned by GET /monitors/{id}/summary, including the previous
/// period snapshot used to render delta chips on the KPI cards.
class MonitorSummary {
  const MonitorSummary({
    required this.range,
    required this.uptimeRatio,
    required this.avgResponseMs,
    required this.incidentCount,
    required this.mttrSeconds,
    required this.previousUptimeRatio,
    required this.previousAvgResponseMs,
    required this.previousIncidentCount,
    required this.previousMttrSeconds,
  });

  final String range;
  final double uptimeRatio;
  final int? avgResponseMs;
  final int incidentCount;
  final int? mttrSeconds;
  final double? previousUptimeRatio;
  final int? previousAvgResponseMs;
  final int previousIncidentCount;
  final int? previousMttrSeconds;

  /// Parses the monitor summary JSON. Missing aggregates fall back to
  /// zero or null so the KPI grid can render every tile without branching
  /// on partial payloads.
  static MonitorSummary fromMap(Map<String, dynamic> map) {
    return MonitorSummary(
      range: map['range']?.toString() ?? '24h',
      uptimeRatio: (map['uptime_ratio'] as num?)?.toDouble() ?? 0,
      avgResponseMs: (map['avg_response_ms'] as num?)?.round(),
      incidentCount: (map['incident_count'] as num?)?.toInt() ?? 0,
      mttrSeconds: (map['mttr_seconds'] as num?)?.round(),
      previousUptimeRatio: (map['previous_uptime_ratio'] as num?)?.toDouble(),
      previousAvgResponseMs: (map['previous_avg_response_ms'] as num?)?.round(),
      previousIncidentCount:
          (map['previous_incident_count'] as num?)?.toInt() ?? 0,
      previousMttrSeconds: (map['previous_mttr_seconds'] as num?)?.round(),
    );
  }
}
