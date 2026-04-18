/// Workspace KPI counters powering the dashboard stats bar.
///
/// Mirrors `DashboardStatsResource` on the API. All values default to 0 so
/// the UI never renders a missing or null counter.
class DashboardStats {
  const DashboardStats({
    this.monitorsTotal = 0,
    this.monitorsDown = 0,
    this.activeIncidents = 0,
    this.pendingSuggestions = 0,
  });

  final int monitorsTotal;
  final int monitorsDown;
  final int activeIncidents;
  final int pendingSuggestions;

  static DashboardStats fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      monitorsTotal: _int(map['monitors_total']),
      monitorsDown: _int(map['monitors_down']),
      activeIncidents: _int(map['active_incidents']),
      pendingSuggestions: _int(map['pending_suggestions']),
    );
  }

  static int _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }
}
