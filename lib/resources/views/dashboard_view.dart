import 'dart:async';

import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../app/controllers/ai/ai_suggestion_controller.dart';
import '../../app/controllers/dashboard/dashboard_controller.dart';
import '../../app/enums/ai_mode.dart';
import '../../app/models/dashboard/dashboard_stats.dart';
import '../../app/models/dashboard/incident_summary.dart';
import '../../app/models/dashboard/monitor_snapshot.dart';
import 'components/common/error_banner.dart';
import 'components/common/refresh_icon_button.dart';
import 'components/common/skeleton_block.dart';
import 'components/dashboard/active_incidents_strip.dart';
import 'components/dashboard/ai_inbox_section.dart';
import 'components/dashboard/dashboard_monitors_section.dart';
import 'components/dashboard/workspace_stats_bar.dart';

/// Dashboard view: Uptizm authenticated landing page.
///
/// Four sections hydrate in parallel from [DashboardController]. Each
/// binds to its own `ValueNotifier` so a slow endpoint only delays its
/// own card. A Live toggle in the header polls every 60s.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with WidgetsBindingObserver {
  static const Duration _pollInterval = Duration(seconds: 60);

  DashboardController get _c => DashboardController.instance;
  AiSuggestionController get _suggestions => AiSuggestionController.instance;

  Timer? _pollTimer;
  bool _liveMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.loadAll();
      _suggestions.load();
      _startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_liveMode) return;
        unawaited(_c.reload());
        unawaited(_suggestions.load());
        _startPolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        _pollTimer = null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_liveMode) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _c.reload();
      _suggestions.load();
    });
  }

  void _toggleLive() {
    setState(() => _liveMode = !_liveMode);
    if (_liveMode) {
      _startPolling();
      unawaited(_c.reload());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _manualRefresh() async {
    await Future.wait([_c.reload(), _suggestions.load()]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _manualRefresh,
      child: WDiv(
        className: 'p-4 lg:p-6 flex flex-col gap-6',
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _c.refreshing,
            builder: (_, refreshing, _) => MagicStarterPageHeader(
              title: trans('dashboard.title'),
              subtitle: trans('dashboard.subtitle'),
              inlineActions: true,
              actions: [
                _LiveToggle(isLive: _liveMode, onTap: _toggleLive),
                RefreshIconButton(
                  onTap: _manualRefresh,
                  isRefreshing: refreshing,
                ),
              ],
            ),
          ),
          _statsBar(),
          _activeIncidents(),
          _monitors(),
          _aiInbox(),
        ],
      ),
    );
  }

  Widget _statsBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _c.firstLoad,
      builder: (_, firstLoad, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _c.statsError,
          builder: (_, hasError, _) {
            return ValueListenableBuilder<DashboardStats?>(
              valueListenable: _c.stats,
              builder: (_, stats, _) {
                if (hasError && stats == null) {
                  return ErrorBanner(onRetry: _c.loadStats);
                }
                if (firstLoad && stats == null) {
                  return const SkeletonBlock(
                    className: 'w-full h-24 rounded-xl',
                  );
                }
                final activeIncidents = stats?.activeIncidents ?? 0;
                return WorkspaceStatsBar(
                  uptimePercent: _uptimePercent(stats),
                  activeIncidents: activeIncidents,
                  avgResponseMs: 0,
                  aiActions24h: stats?.pendingSuggestions ?? 0,
                  onIncidentsTap: () => MagicRoute.to('/monitors'),
                  onAiTap: () => MagicRoute.to('/settings/ai'),
                );
              },
            );
          },
        );
      },
    );
  }

  double _uptimePercent(DashboardStats? stats) {
    if (stats == null || stats.monitorsTotal == 0) return 100.0;
    final down = stats.monitorsDown.clamp(0, stats.monitorsTotal);
    return ((stats.monitorsTotal - down) / stats.monitorsTotal) * 100.0;
  }

  Widget _activeIncidents() {
    return ValueListenableBuilder<bool>(
      valueListenable: _c.firstLoad,
      builder: (_, firstLoad, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _c.activeIncidentsError,
          builder: (_, hasError, _) {
            return ValueListenableBuilder<List<IncidentSummary>>(
              valueListenable: _c.activeIncidents,
              builder: (_, list, _) {
                if (hasError && list.isEmpty) {
                  return ErrorBanner(onRetry: _c.loadActiveIncidents);
                }
                if (firstLoad && list.isEmpty) {
                  return const SkeletonBlock(
                    className: 'w-full h-20 rounded-xl',
                  );
                }
                return ValueListenableBuilder<List<MonitorSnapshot>>(
                  valueListenable: _c.monitors,
                  builder: (_, monitors, _) {
                    final nameById = {for (final m in monitors) m.id: m.name};
                    return ActiveIncidentsStrip(
                      incidents: [
                        for (final i in list)
                          ActiveIncidentItem(
                            monitorId: i.monitorId,
                            monitorName: nameById[i.monitorId] ?? i.monitorId,
                            title: i.title,
                            severity: i.severity,
                            status: i.status,
                            relativeTime: _relativeTime(i.startedAt),
                            aiOwned: i.aiOwned,
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _monitors() {
    return ValueListenableBuilder<bool>(
      valueListenable: _c.firstLoad,
      builder: (_, firstLoad, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _c.monitorsError,
          builder: (_, hasError, _) {
            return ValueListenableBuilder<List<MonitorSnapshot>>(
              valueListenable: _c.monitors,
              builder: (_, list, _) {
                if (hasError && list.isEmpty) {
                  return ErrorBanner(onRetry: _c.loadMonitorsSnapshot);
                }
                if (firstLoad && list.isEmpty) {
                  return const SkeletonBlock(
                    className: 'w-full h-40 rounded-xl',
                  );
                }
                return DashboardMonitorsSection(
                  monitors: [
                    for (final m in list)
                      DashboardMonitorItem(
                        id: m.id,
                        name: m.name,
                        status: m.lastStatus,
                        aiMode: AiMode.off,
                        responseMs: m.lastResponseMs,
                        recentSamples: List.filled(12, m.lastStatus),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _aiInbox() {
    return ValueListenableBuilder<bool>(
      valueListenable: _c.firstLoad,
      builder: (_, firstLoad, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _c.suggestionsError,
          builder: (_, hasError, _) {
            return AnimatedBuilder(
              animation: _suggestions,
              builder: (_, _) {
                final list = _suggestions.suggestions;
                if (hasError && list.isEmpty) {
                  return ErrorBanner(onRetry: _c.loadAiInbox);
                }
                if (firstLoad && list.isEmpty) {
                  return const SkeletonBlock(
                    className: 'w-full h-32 rounded-xl',
                  );
                }
                return ValueListenableBuilder<List<MonitorSnapshot>>(
                  valueListenable: _c.monitors,
                  builder: (_, monitors, _) {
                    final nameById = {for (final m in monitors) m.id: m.name};
                    return AiInboxSection(
                      suggestions: [
                        for (final s in list)
                          AiInboxItem(
                            id: s.id,
                            monitorName: nameById[s.monitorId] ?? s.monitorId,
                            tldr: s.tldr,
                            confidence: s.confidence,
                            relativeTime: _relativeTime(s.createdAt),
                            metricKey: s.metricKey,
                          ),
                      ],
                      onAccept: _onAccept,
                      onSkip: _onSkip,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onAccept(String id) async {
    final incidentId = await _suggestions.accept(id);
    if (!mounted) return;
    if (incidentId == null) {
      Magic.toast(trans('ai.suggestions.errors.generic_accept'));
      return;
    }
    MagicRoute.to('/monitors');
  }

  Future<void> _onSkip(String id) async {
    final ok = await _suggestions.skip(id);
    if (!mounted) return;
    if (!ok) {
      Magic.toast(trans('ai.suggestions.errors.generic_skip'));
    }
  }

  String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return trans('dashboard.time.just_now');
    if (diff.inMinutes < 60) {
      return trans('dashboard.time.minutes_ago', {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return trans('dashboard.time.hours_ago', {'n': '${diff.inHours}'});
    }
    return trans('dashboard.time.days_ago', {'n': '${diff.inDays}'});
  }
}

class _LiveToggle extends StatelessWidget {
  const _LiveToggle({required this.isLive, required this.onTap});

  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: trans(
        isLive ? 'dashboard.live.on_hint' : 'dashboard.live.off_hint',
      ),
      child: WButton(
        onTap: onTap,
        states: isLive ? {'live'} : {},
        className: '''
          h-9 px-3 rounded-lg
          flex flex-row items-center gap-2
          border border-gray-200 dark:border-gray-700
          bg-white dark:bg-gray-800
          hover:bg-gray-50 dark:hover:bg-gray-700
          live:border-up-200 dark:live:border-up-800
          live:bg-up-50 dark:live:bg-up-900/30
        ''',
        child: WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WDiv(
              states: isLive ? {'live'} : {},
              className: '''
                w-2 h-2 rounded-full
                bg-gray-400 dark:bg-gray-500
                live:bg-up-500 dark:live:bg-up-400
                live:animate-pulse
              ''',
            ),
            WText(
              trans(isLive ? 'dashboard.live.on' : 'dashboard.live.off'),
              states: isLive ? {'live'} : {},
              className: '''
                text-xs font-semibold
                text-gray-600 dark:text-gray-300
                live:text-up-700 dark:live:text-up-300
              ''',
            ),
          ],
        ),
      ),
    );
  }
}
