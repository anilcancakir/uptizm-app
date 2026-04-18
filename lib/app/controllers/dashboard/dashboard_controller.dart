import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

import '../../../resources/views/dashboard_view.dart';
import '../../helpers/http_cache.dart';
import '../../models/dashboard/ai_suggestion.dart';
import '../../models/dashboard/dashboard_stats.dart';
import '../../models/dashboard/incident_summary.dart';
import '../../models/dashboard/monitor_snapshot.dart';

/// Aggregates the four read-only dashboard endpoints behind a single
/// controller. Each section owns its own `ValueNotifier` so the dashboard
/// view can bind tiles, incidents strip, monitors list, and AI inbox
/// independently without rebuilding siblings when one section refreshes.
class DashboardController extends MagicController {
  static DashboardController get instance =>
      Magic.findOrPut(DashboardController.new);

  final ValueNotifier<DashboardStats?> stats = ValueNotifier(null);
  final ValueNotifier<bool> statsError = ValueNotifier(false);

  final ValueNotifier<List<IncidentSummary>> activeIncidents = ValueNotifier(
    const [],
  );
  final ValueNotifier<bool> activeIncidentsError = ValueNotifier(false);

  final ValueNotifier<List<MonitorSnapshot>> monitors = ValueNotifier(const []);
  final ValueNotifier<bool> monitorsError = ValueNotifier(false);

  final ValueNotifier<List<AiSuggestion>> suggestions = ValueNotifier(const []);
  final ValueNotifier<bool> suggestionsError = ValueNotifier(false);

  /// True until the first [loadAll] completes; views use this to switch
  /// between skeleton placeholders and the live rendering path so a manual
  /// [reload] does not flash the skeleton again.
  final ValueNotifier<bool> firstLoad = ValueNotifier(true);

  /// Flips to true while a [reload] is in-flight so the header refresh
  /// button can render its spinner without touching [firstLoad].
  final ValueNotifier<bool> refreshing = ValueNotifier(false);

  /// Route entry point. Mirrors the monitor resource-controller pattern so
  /// `lib/routes/app.dart` can wire every page through its controller.
  Widget index() => const DashboardView();

  /// Fans out the four dashboard section loads in parallel and flips
  /// `firstLoad` off after the first successful completion so subsequent
  /// refreshes skip the skeleton path.
  Future<void> loadAll() async {
    await Future.wait([
      loadStats(),
      loadActiveIncidents(),
      loadMonitorsSnapshot(),
      loadAiInbox(),
    ]);
    if (firstLoad.value) firstLoad.value = false;
  }

  /// Alias used by the header refresh button + Live polling tick. Keeps the
  /// semantic distinction between "first paint" and "manual refresh".
  Future<void> reload() async {
    refreshing.value = true;
    try {
      await loadAll();
    } finally {
      refreshing.value = false;
    }
  }

  /// Loads the KPI tiles (total monitors, up/down counts, open incidents).
  /// On failure, clears `stats` and flips `statsError` so the tile row can
  /// render its error state without wiping sibling sections.
  Future<void> loadStats() async {
    final response = await HttpCache.get('/dashboard/stats');
    if (!response.successful) {
      stats.value = null;
      statsError.value = true;
      return;
    }
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      stats.value = null;
      statsError.value = true;
      return;
    }
    statsError.value = false;
    stats.value = DashboardStats.fromMap(data);
  }

  /// Loads the active incidents strip shown above the monitors list.
  Future<void> loadActiveIncidents() => _loadList<IncidentSummary>(
    '/dashboard/active-incidents',
    IncidentSummary.fromMap,
    activeIncidents,
    activeIncidentsError,
  );

  /// Loads the compact monitor snapshots that back the dashboard list.
  Future<void> loadMonitorsSnapshot() => _loadList<MonitorSnapshot>(
    '/dashboard/monitors-snapshot',
    MonitorSnapshot.fromMap,
    monitors,
    monitorsError,
  );

  /// Loads the AI suggestion inbox shown in the dashboard side panel.
  Future<void> loadAiInbox() => _loadList<AiSuggestion>(
    '/dashboard/ai-inbox',
    AiSuggestion.fromMap,
    suggestions,
    suggestionsError,
  );

  Future<void> _loadList<E>(
    String url,
    E Function(Map<String, dynamic>) fromMap,
    ValueNotifier<List<E>> target,
    ValueNotifier<bool> errorFlag,
  ) async {
    final response = await HttpCache.get(url);
    if (!response.successful) {
      target.value = const [];
      errorFlag.value = true;
      return;
    }
    final raw = response.data?['data'];
    if (raw is! List) {
      target.value = const [];
      errorFlag.value = true;
      return;
    }
    errorFlag.value = false;
    target.value = raw.whereType<Map<String, dynamic>>().map(fromMap).toList();
  }

  @override
  void onClose() {
    stats.dispose();
    statsError.dispose();
    activeIncidents.dispose();
    activeIncidentsError.dispose();
    monitors.dispose();
    monitorsError.dispose();
    suggestions.dispose();
    suggestionsError.dispose();
    firstLoad.dispose();
    refreshing.dispose();
    super.onClose();
  }
}
