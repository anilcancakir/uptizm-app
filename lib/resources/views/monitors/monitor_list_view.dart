import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/enums/ai_mode.dart';
import '../../../app/enums/monitor_status.dart';
import '../components/common/empty_state.dart';
import '../components/common/monitor_status_dot.dart';
import '../components/common/primary_button.dart';
import '../components/monitors/status_badge.dart';

/// Mock monitor-list screen.
///
/// Shows the workspace's monitors with status, last response, AI mode badge,
/// and an override dot when the monitor overrides the workspace default.
class MonitorListView extends StatelessWidget {
  const MonitorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final monitors = _mock();
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          title: trans('monitor.list.title'),
          subtitle: trans('monitor.list.subtitle'),
          inlineActions: true,
          actions: [
            PrimaryButton(
              labelKey: 'monitor.list.add',
              icon: Icons.add_rounded,
              onTap: () => MagicRoute.to('/monitors/create'),
            ),
          ],
        ),
        if (monitors.isEmpty)
          EmptyState(
            icon: Icons.monitor_heart_outlined,
            titleKey: 'monitor.list.empty_title',
            subtitleKey: 'monitor.list.empty_subtitle',
            action: PrimaryButton(
              labelKey: 'monitor.list.add',
              icon: Icons.add_rounded,
              onTap: () => MagicRoute.to('/monitors/create'),
            ),
          )
        else
          WDiv(
            className: '''
              rounded-xl overflow-hidden
              bg-white dark:bg-gray-800
              border border-gray-200 dark:border-gray-700
              flex flex-col
            ''',
            children: [
              for (final m in monitors) _MonitorRow(monitor: m),
            ],
          ),
      ],
    );
  }

  List<_Monitor> _mock() {
    return const [
      _Monitor(
        id: 'sample',
        name: 'Production API',
        url: 'https://api.example.com/health',
        status: MonitorStatus.up,
        responseMs: 245,
        aiMode: AiMode.suggest,
        overridesWorkspaceDefault: false,
      ),
      _Monitor(
        id: 'web',
        name: 'Marketing site',
        url: 'https://www.example.com',
        status: MonitorStatus.up,
        responseMs: 112,
        aiMode: AiMode.auto,
        overridesWorkspaceDefault: true,
      ),
      _Monitor(
        id: 'db',
        name: 'Primary DB health',
        url: 'https://api.example.com/db/ping',
        status: MonitorStatus.degraded,
        responseMs: 812,
        aiMode: AiMode.auto,
        overridesWorkspaceDefault: false,
      ),
      _Monitor(
        id: 'legacy',
        name: 'Legacy billing',
        url: 'https://billing-legacy.example.com/ok',
        status: MonitorStatus.down,
        responseMs: null,
        aiMode: AiMode.off,
        overridesWorkspaceDefault: true,
      ),
      _Monitor(
        id: 'staging',
        name: 'Staging API',
        url: 'https://staging.example.com/health',
        status: MonitorStatus.paused,
        responseMs: null,
        aiMode: AiMode.off,
        overridesWorkspaceDefault: false,
      ),
    ];
  }
}

class _Monitor {
  const _Monitor({
    required this.id,
    required this.name,
    required this.url,
    required this.status,
    required this.responseMs,
    required this.aiMode,
    required this.overridesWorkspaceDefault,
  });

  final String id;
  final String name;
  final String url;
  final MonitorStatus status;
  final int? responseMs;
  final AiMode aiMode;
  final bool overridesWorkspaceDefault;
}

class _MonitorRow extends StatelessWidget {
  const _MonitorRow({required this.monitor});

  final _Monitor monitor;

  @override
  Widget build(BuildContext context) {
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
          MonitorStatusDot(toneKey: monitor.status.toneKey, size: 'md'),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                monitor.name,
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white truncate
                ''',
              ),
              WText(
                monitor.url,
                className: '''
                  text-xs font-mono
                  text-gray-500 dark:text-gray-400 truncate
                ''',
              ),
            ],
          ),
          if (monitor.responseMs != null)
            WText(
              '${monitor.responseMs} ms',
              className: '''
                text-xs font-mono
                text-gray-600 dark:text-gray-300
                hidden sm:flex
              ''',
            ),
          _AiModeBadge(
            mode: monitor.aiMode,
            overrides: monitor.overridesWorkspaceDefault,
          ),
          WDiv(
            className: 'hidden md:flex',
            child: StatusBadge(status: monitor.status),
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
