import '../enums/monitor_status.dart';

/// Team-owned public status page.
///
/// Mirrors `StatusPageResource` on the API. `monitors` is eager-loaded
/// on index / show / store / update / publish responses; empty otherwise.
class StatusPage {
  const StatusPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.primaryColor,
    required this.isPublic,
    this.logoPath,
    this.monitors = const [],
  });

  final String id;
  final String title;
  final String slug;

  /// Hex, e.g. `#2563EB`.
  final String primaryColor;
  final String? logoPath;
  final bool isPublic;
  final List<StatusPageMonitor> monitors;

  String get subdomain => '$slug.uptizm.com';

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

  List<String> get monitorIds => monitors.map((m) => m.id).toList();

  StatusPage copyWith({
    String? title,
    String? slug,
    String? primaryColor,
    String? logoPath,
    bool? isPublic,
    List<StatusPageMonitor>? monitors,
  }) {
    return StatusPage(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      primaryColor: primaryColor ?? this.primaryColor,
      logoPath: logoPath ?? this.logoPath,
      isPublic: isPublic ?? this.isPublic,
      monitors: monitors ?? this.monitors,
    );
  }

  static StatusPage fromMap(Map<String, dynamic> map) {
    final rawMonitors = map['monitors'];
    return StatusPage(
      id: map['id']?.toString() ?? '',
      title: (map['title'] as String?) ?? '',
      slug: (map['slug'] as String?) ?? '',
      primaryColor: (map['primary_color'] as String?) ?? '#2563EB',
      logoPath: map['logo_path'] as String?,
      isPublic: map['is_public'] == true,
      monitors: rawMonitors is List
          ? rawMonitors
                .whereType<Map<String, dynamic>>()
                .map(StatusPageMonitor.fromMap)
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

  String get label => customLabel ?? name;

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
