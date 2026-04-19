import '../enums/metric_type.dart';
import '../enums/monitor_status.dart';

/// Team-owned public status page.
///
/// Mirrors `StatusPageResource` on the API. `monitors` and `metrics`
/// are eager-loaded on index / show / store / update / publish /
/// unpublish responses; empty otherwise.
class StatusPage {
  const StatusPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.primaryColor,
    required this.isPublic,
    this.teamId,
    this.logoPath,
    this.previewToken,
    this.monitors = const [],
    this.metrics = const [],
  });

  final String id;
  final String title;
  final String slug;

  /// Hex, e.g. `#2563EB`.
  final String primaryColor;
  final String? logoPath;
  final bool isPublic;
  final List<StatusPageMonitor> monitors;
  final List<StatusPageMetric> metrics;

  /// Owning team id. Sourced from `StatusPageResource.team_id` so the client
  /// can enforce tenant-scoped UI affordances (publish, destroy) via `Gate`.
  final String? teamId;

  /// Shareable token for draft preview. Server reveals it only to members
  /// of the owning team; outside viewers get null.
  final String? previewToken;

  /// Public-facing hostname derived from [slug]. Rendered on the status
  /// page card header; no networking is performed by this getter.
  String get subdomain => '$slug.uptizm.com';

  /// Full preview URL including the token, suitable for clipboard share.
  /// Returns null when no token is available (foreign-team read).
  String? get previewUrl {
    final token = previewToken;
    if (token == null || token.isEmpty) return null;
    return 'https://$subdomain/?preview_token=$token';
  }

  /// Two-letter initials for the logo fallback.
  String get initials {
    final parts = title
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Flattened list of attached monitor ids, used by the assign picker to
  /// seed its pre-selected state.
  List<String> get monitorIds => monitors.map((m) => m.id).toList();

  /// Flattened list of attached metric ids, used by the metric picker to
  /// seed its pre-selected state.
  List<String> get metricIds => metrics.map((m) => m.id).toList();

  /// Returns a copy with the mutable status-page surface swapped. [id] and
  /// [teamId] are identity fields and never change here.
  StatusPage copyWith({
    String? title,
    String? slug,
    String? primaryColor,
    String? logoPath,
    bool? isPublic,
    String? previewToken,
    List<StatusPageMonitor>? monitors,
    List<StatusPageMetric>? metrics,
  }) {
    return StatusPage(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      primaryColor: primaryColor ?? this.primaryColor,
      logoPath: logoPath ?? this.logoPath,
      isPublic: isPublic ?? this.isPublic,
      teamId: teamId,
      previewToken: previewToken ?? this.previewToken,
      monitors: monitors ?? this.monitors,
      metrics: metrics ?? this.metrics,
    );
  }

  /// Parses a `StatusPageResource` payload. Defaults [primaryColor] to the
  /// Uptizm brand blue when the server omits it (legacy pages).
  static StatusPage fromMap(Map<String, dynamic> map) {
    final rawMonitors = map['monitors'];
    final rawMetrics = map['metrics'];
    return StatusPage(
      id: map['id']?.toString() ?? '',
      title: (map['title'] as String?) ?? '',
      slug: (map['slug'] as String?) ?? '',
      primaryColor: (map['primary_color'] as String?) ?? '#2563EB',
      logoPath: map['logo_path'] as String?,
      isPublic: map['is_public'] == true,
      teamId: map['team_id']?.toString(),
      previewToken: map['preview_token'] as String?,
      monitors: rawMonitors is List
          ? rawMonitors
                .whereType<Map<String, dynamic>>()
                .map(StatusPageMonitor.fromMap)
                .toList()
          : const [],
      metrics: rawMetrics is List
          ? rawMetrics
                .whereType<Map<String, dynamic>>()
                .map(StatusPageMetric.fromMap)
                .toList()
          : const [],
    );
  }
}

/// Monitor attached to a status page, carrying the pivot fields.
class StatusPageMonitor {
  const StatusPageMonitor({
    required this.id,
    required this.name,
    required this.url,
    required this.lastStatus,
    this.displayOrder = 0,
    this.customLabel,
  });

  final String id;
  final String name;
  final String url;
  final MonitorStatus lastStatus;
  final int displayOrder;
  final String? customLabel;

  /// Visible label used on the public status page — the pivot's custom
  /// override when provided, otherwise the monitor's own name.
  String get label => customLabel ?? name;

  /// Parses one pivot row from `StatusPageResource.monitors`.
  static StatusPageMonitor fromMap(Map<String, dynamic> map) {
    return StatusPageMonitor(
      id: map['id']?.toString() ?? '',
      name: (map['name'] as String?) ?? '',
      url: (map['url'] as String?) ?? '',
      lastStatus: _status(map['last_status']),
      displayOrder: _int(map['display_order']) ?? 0,
      customLabel: map['custom_label'] as String?,
    );
  }

  static MonitorStatus _status(Object? raw) {
    if (raw is! String) return MonitorStatus.paused;
    return MonitorStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MonitorStatus.paused,
    );
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

/// Custom metric pinned to a status page, carrying the pivot fields and
/// the most recent recorded sample so the public viewer renders a live
/// value without a follow-up request.
class StatusPageMetric {
  const StatusPageMetric({
    required this.id,
    required this.monitorId,
    required this.key,
    required this.label,
    required this.type,
    this.groupName,
    this.unit,
    this.unitKind,
    this.displayOrder = 0,
    this.customLabel,
    this.latestNumericValue,
    this.latestStringValue,
    this.latestStatusValue,
    this.latestBand,
    this.latestRecordedAt,
  });

  final String id;
  final String monitorId;
  final String key;
  final String label;
  final String? groupName;
  final MetricType type;
  final String? unit;
  final String? unitKind;
  final int displayOrder;
  final String? customLabel;
  final double? latestNumericValue;
  final String? latestStringValue;
  final MonitorStatus? latestStatusValue;
  final MetricBand? latestBand;
  final DateTime? latestRecordedAt;

  /// Visible label on the public page — the pivot's custom override when
  /// provided, otherwise the metric's own label.
  String get displayLabel => customLabel ?? label;

  /// Parses one row from `StatusPageResource.metrics`.
  static StatusPageMetric fromMap(Map<String, dynamic> map) {
    return StatusPageMetric(
      id: map['id']?.toString() ?? '',
      monitorId: map['monitor_id']?.toString() ?? '',
      key: (map['key'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
      groupName: map['group_name'] as String?,
      type: _type(map['type']),
      unit: map['unit'] as String?,
      unitKind: map['unit_kind'] as String?,
      displayOrder: _int(map['display_order']) ?? 0,
      customLabel: map['custom_label'] as String?,
      latestNumericValue: _double(map['latest_numeric_value']),
      latestStringValue: map['latest_string_value'] as String?,
      latestStatusValue: _status(map['latest_status_value']),
      latestBand: _band(map['latest_band']),
      latestRecordedAt: _dateTime(map['latest_recorded_at']),
    );
  }

  static MetricType _type(Object? raw) {
    if (raw is! String) return MetricType.numeric;
    return MetricType.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MetricType.numeric,
    );
  }

  static MonitorStatus? _status(Object? raw) {
    if (raw is! String) return null;
    return MonitorStatus.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MonitorStatus.paused,
    );
  }

  static MetricBand? _band(Object? raw) {
    if (raw is! String) return null;
    return MetricBand.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => MetricBand.ok,
    );
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static double? _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static DateTime? _dateTime(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }
}
