import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/ai_mode.dart';
import '../../../../app/enums/monitor_status.dart';
import '../common/empty_state.dart';
import '../common/monitor_status_dot.dart';
import 'mini_response_bars.dart';

/// One monitor row model for the dashboard overview.
class DashboardMonitorItem {
  const DashboardMonitorItem({
    required this.id,
    required this.name,
    required this.status,
    required this.aiMode,
    required this.recentSamples,
    this.responseMs,
  });

  final String id;
  final String name;
  final MonitorStatus status;
  final AiMode aiMode;
  final List<MonitorStatus> recentSamples;
  final int? responseMs;
}

/// Dashboard section listing up to N monitors with sparkline + AI mode.
///
/// Mirrors the MonitorListView row shape but slimmer: status dot, name, a
/// 12-point mini sparkline, response ms, AI mode chip. Tap routes to the
/// monitor detail page.
class DashboardMonitorsSection extends StatelessWidget {
  const DashboardMonitorsSection({super.key, required this.monitors});

  final List<DashboardMonitorItem> monitors;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        _header(),
        if (monitors.isEmpty)
          EmptyState(
            icon: Icons.monitor_heart_outlined,
            titleKey: 'dashboard.monitors.empty_title',
            subtitleKey: 'dashboard.monitors.empty_subtitle',
            tone: 'paused',
            variant: 'plain',
            action: WButton(
              onTap: () => MagicRoute.to('/monitors/create'),
              className: '''
                px-4 py-3 rounded-lg
                bg-primary hover:bg-primary-700
                dark:bg-primary-500 dark:hover:bg-primary-400
              ''',
              child: WText(
                trans('dashboard.monitors.add_first'),
                className: 'text-sm font-semibold text-white',
              ),
            ),
          )
        else
          WDiv(
            className: 'flex flex-col',
            children: [
              for (var i = 0; i < monitors.length; i++)
                _row(monitors[i], isLast: i == monitors.length - 1),
            ],
          ),
      ],
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-gray-200 dark:border-gray-700
        flex flex-row items-center justify-between gap-2
      ''',
      children: [
        WDiv(
          className: 'flex flex-col gap-0.5 min-w-0 flex-1',
          children: [
            WText(
              trans('dashboard.monitors.title'),
              className: '''
                text-sm font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('dashboard.monitors.subtitle'),
              className: 'text-xs text-gray-500 dark:text-gray-400 truncate',
            ),
          ],
        ),
        WButton(
          onTap: () => MagicRoute.to('/monitors'),
          className: '''
            px-3 py-2 rounded-lg
            hover:bg-gray-100 dark:hover:bg-gray-900/40
          ''',
          child: WText(
            trans('dashboard.monitors.view_all'),
            className: '''
              text-xs font-semibold
              text-primary-600 dark:text-primary-300
            ''',
          ),
        ),
      ],
    );
  }

  Widget _row(DashboardMonitorItem m, {required bool isLast}) {
    return WButton(
      onTap: () => MagicRoute.to('/monitors/${m.id}'),
      states: isLast ? {'last'} : {},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          MonitorStatusDot(toneKey: m.status.toneKey, size: 'md'),
          WDiv(
            className: 'flex-1 min-w-0',
            child: WText(
              m.name,
              className: '''
                text-sm font-semibold
                text-gray-900 dark:text-white
                truncate
              ''',
            ),
          ),
          WDiv(
            className: 'hidden sm:block w-24',
            child: MiniResponseBars(samples: m.recentSamples),
          ),
          if (m.responseMs != null)
            WText(
              '${m.responseMs} ms',
              className: '''
                text-xs font-mono tabular-nums
                text-gray-600 dark:text-gray-300
                hidden md:block
                w-16 text-right
              ''',
            ),
          _AiModeChip(mode: m.aiMode),
        ],
      ),
    );
  }
}

class _AiModeChip extends StatelessWidget {
  const _AiModeChip({required this.mode});

  final AiMode mode;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      states: {mode.toneKey},
      className: '''
        px-2 py-1 rounded-full
        flex flex-row items-center gap-1
        bg-gray-100 dark:bg-gray-900
        off:bg-gray-100 dark:off:bg-gray-900
        suggest:bg-primary-50 dark:suggest:bg-primary-900/30
        auto:bg-ai-50 dark:auto:bg-ai-900/30
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
    );
  }
}
