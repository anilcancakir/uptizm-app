import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/ai/ai_settings_controller.dart';
import '../../../app/controllers/monitors/monitor_controller.dart';
import '../../../app/enums/ai_mode.dart';
import '../../../app/enums/monitor_status.dart';
import '../../../app/models/monitor.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/monitor_status_dot.dart';
import '../components/common/primary_button.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';
import '../components/monitors/status_badge.dart';

/// Workspace monitor list, hydrated from `/monitors`.
class MonitorListView extends StatefulWidget {
  const MonitorListView({super.key});

  @override
  State<MonitorListView> createState() => _MonitorListViewState();
}

class _MonitorListViewState extends State<MonitorListView> {
  MonitorController get _c => MonitorController.instance;
  AiSettingsController get _ai => AiSettingsController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.loadList();
      if (_ai.settings == null) _ai.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 480;
            return ValueListenableBuilder<bool>(
              valueListenable: _c.listLoading,
              builder: (_, loading, _) => MagicStarterPageHeader(
                title: trans('monitor.list.title'),
                subtitle: trans('monitor.list.subtitle'),
                inlineActions: true,
                actions: [
                  RefreshIconButton(onTap: _c.loadList, isRefreshing: loading),
                  PrimaryButton(
                    labelKey: narrow
                        ? 'monitor.list.add_short'
                        : 'monitor.list.add',
                    icon: Icons.add_rounded,
                    onTap: () => MagicRoute.to('/monitors/create'),
                  ),
                ],
              ),
            );
          },
        ),
        RefreshIndicator(
          onRefresh: _c.loadList,
          child: ValueListenableBuilder<bool>(
            valueListenable: _c.listError,
            builder: (_, hasError, _) {
              if (hasError) {
                return ErrorBanner(onRetry: _c.loadList);
              }
              return ValueListenableBuilder<bool>(
                valueListenable: _c.listLoading,
                builder: (_, loading, _) {
                  return ValueListenableBuilder<List<Monitor>>(
                    valueListenable: _c.list,
                    builder: (_, monitors, _) {
                      if (loading && monitors.isEmpty) {
                        return const SkeletonRowList();
                      }
                      if (monitors.isEmpty) return _empty();
                      return _table(monitors);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return EmptyState(
      icon: Icons.monitor_heart_outlined,
      titleKey: 'monitor.list.empty_title',
      subtitleKey: 'monitor.list.empty_subtitle',
      action: PrimaryButton(
        labelKey: 'monitor.list.add',
        icon: Icons.add_rounded,
        onTap: () => MagicRoute.to('/monitors/create'),
      ),
    );
  }

  Widget _table(List<Monitor> monitors) {
    return WDiv(
      className: '''
        rounded-xl overflow-hidden
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [for (final m in monitors) _row(m)],
    );
  }

  Widget _row(Monitor monitor) {
    final status = monitor.lastStatus ?? MonitorStatus.paused;
    final responseMs = (monitor.getAttribute('last_response_ms') as num?)
        ?.toInt();
    final rawMode = monitor.getAttribute('ai_mode') as String?;
    final aiMode = rawMode == null
        ? _ai.settings?.aiMode ?? AiMode.off
        : AiMode.values.firstWhere(
            (m) => m.name == rawMode,
            orElse: () => AiMode.off,
          );
    final overrides = rawMode != null && rawMode != _ai.settings?.aiMode.name;
    return WButton(
      onTap: () => MagicRoute.to('/monitors/${monitor.id}'),
      className: '''
        w-full px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        hover:bg-gray-50 dark:hover:bg-gray-800/40
        flex flex-row items-center gap-4
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-4 w-full',
        children: [
          MonitorStatusDot(toneKey: status.toneKey, size: 'md'),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                monitor.name ?? '',
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white truncate
                ''',
              ),
              WText(
                monitor.url ?? '',
                className: '''
                  text-xs font-mono
                  text-gray-500 dark:text-gray-400 truncate
                ''',
              ),
            ],
          ),
          if (responseMs != null)
            WText(
              '$responseMs ms',
              className: '''
                text-xs font-mono
                text-gray-600 dark:text-gray-300
                hidden sm:flex
              ''',
            ),
          _AiModeBadge(mode: aiMode, overrides: overrides),
          WDiv(
            className: 'hidden md:flex',
            child: StatusBadge(status: status),
          ),
        ],
      ),
    );
  }
}

class _AiModeBadge extends StatelessWidget {
  const _AiModeBadge({required this.mode, required this.overrides});

  final AiMode mode;
  final bool overrides;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'relative flex flex-row items-center',
      children: [
        WDiv(
          states: {mode.toneKey},
          className: '''
            flex flex-row items-center gap-1
            px-2 py-1 rounded-full
            bg-gray-100 dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            off:bg-gray-100 dark:off:bg-gray-800
            suggest:bg-primary-50 dark:suggest:bg-primary-900/30
            suggest:border-primary-200 dark:suggest:border-primary-800
            auto:bg-ai-50 dark:auto:bg-ai-900/30
            auto:border-ai-200 dark:auto:border-ai-800
          ''',
          children: [
            WIcon(
              Icons.auto_awesome_rounded,
              states: {mode.toneKey},
              className: '''
                text-[10px]
                text-gray-400 dark:text-gray-500
                suggest:text-primary-600 dark:suggest:text-primary-300
                auto:text-ai-600 dark:auto:text-ai-300
              ''',
            ),
            WText(
              trans(mode.labelKey),
              states: {mode.toneKey},
              className: '''
                text-[10px] font-bold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
                suggest:text-primary-700 dark:suggest:text-primary-300
                auto:text-ai-700 dark:auto:text-ai-300
              ''',
            ),
          ],
        ),
        if (overrides)
          WDiv(
            className: '''
              absolute -top-0.5 -right-0.5
              w-2 h-2 rounded-full
              bg-degraded-500 dark:bg-degraded-400
              border border-white dark:border-gray-800
            ''',
          ),
      ],
    );
  }
}
