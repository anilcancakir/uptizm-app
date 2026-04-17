/// Mock status page record used by the v1 design.
///
/// Values are hardcoded; a backend binding will replace these once the API
/// lands. `subdomain` is derived, never stored separately.
class StatusPage {
  const StatusPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.primaryColor,
    required this.monitorIds,
    required this.isPublic,
    this.logoPath,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String slug;

  /// Hex, e.g. `#2563EB`.
  final String primaryColor;

  /// Local asset or file path preview. `null` → initials fallback.
  final String? logoPath;

  final List<String> monitorIds;
  final bool isPublic;
  final DateTime createdAt;

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
      return p.length >= 2
          ? p.substring(0, 2).toUpperCase()
          : p.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static List<StatusPage> mockAll() => [
        StatusPage(
          id: 'sample',
          title: 'Uptizm Cloud',
          slug: 'cloud',
          primaryColor: '#2563EB',
          monitorIds: const ['m1', 'm2', 'm3', 'm4'],
          isPublic: true,
          createdAt: DateTime(2026, 3, 12),
        ),
        StatusPage(
          id: 'internal',
          title: 'Internal Tools',
          slug: 'internal',
          primaryColor: '#10B981',
          monitorIds: const ['m5', 'm6'],
          isPublic: false,
          createdAt: DateTime(2026, 2, 2),
        ),
      ];

  static StatusPage findOr404(String id) {
    final list = mockAll();
    return list.firstWhere(
      (p) => p.id == id,
      orElse: () => list.first,
    );
  }
}

/// Mock monitor option used by the status-page assign list.
class StatusPageMonitorOption {
  const StatusPageMonitorOption({
    required this.id,
    required this.name,
    required this.url,
    required this.statusTone,
  });

  final String id;
  final String name;
  final String url;

  /// `'up' | 'down' | 'degraded' | 'paused'`, matches monitor tone tokens.
  final String statusTone;

  static List<StatusPageMonitorOption> mockAll() => const [
        StatusPageMonitorOption(
          id: 'm1',
          name: 'Production API',
          url: 'https://api.example.com/health',
          statusTone: 'up',
        ),
        StatusPageMonitorOption(
          id: 'm2',
          name: 'Checkout service',
          url: 'https://checkout.example.com',
          statusTone: 'degraded',
        ),
        StatusPageMonitorOption(
          id: 'm3',
          name: 'CDN origin',
          url: 'https://cdn.example.com',
          statusTone: 'up',
        ),
        StatusPageMonitorOption(
          id: 'm4',
          name: 'Auth service',
          url: 'https://auth.example.com',
          statusTone: 'up',
        ),
        StatusPageMonitorOption(
          id: 'm5',
          name: 'Worker queue',
          url: 'https://worker.example.com',
          statusTone: 'down',
        ),
        StatusPageMonitorOption(
          id: 'm6',
          name: 'Staging API',
          url: 'https://staging.example.com',
          statusTone: 'paused',
        ),
      ];
}
