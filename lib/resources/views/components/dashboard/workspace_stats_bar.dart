import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Four workspace-wide KPIs: uptime %, active incidents, avg p95, AI actions.
///
/// Uses tone states to tint the icon slab: `up` (green), `down` (red),
/// `primary` (blue), `ai` (indigo). Touch target meets 44dp via p-4.
class WorkspaceStatsBar extends StatelessWidget {
  const WorkspaceStatsBar({
    super.key,
    required this.uptimePercent,
    required this.activeIncidents,
    required this.avgResponseMs,
    required this.aiActions24h,
    this.onUptimeTap,
    this.onIncidentsTap,
    this.onResponseTap,
    this.onAiTap,
  });

  final double uptimePercent;
  final int activeIncidents;
  final int avgResponseMs;
  final int aiActions24h;
  final VoidCallback? onUptimeTap;
  final VoidCallback? onIncidentsTap;
  final VoidCallback? onResponseTap;
  final VoidCallback? onAiTap;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'grid grid-cols-2 lg:grid-cols-4 gap-3',
      children: [
        _tile(
          icon: Icons.verified_rounded,
          labelKey: 'dashboard.workspace.uptime',
          value: '${uptimePercent.toStringAsFixed(2)}%',
          tone: _uptimeTone(uptimePercent),
          onTap: onUptimeTap,
        ),
        _tile(
          icon: Icons.error_outline_rounded,
          labelKey: 'dashboard.workspace.active_incidents',
          value: '$activeIncidents',
          tone: activeIncidents == 0 ? 'up' : 'down',
          onTap: onIncidentsTap,
        ),
        _tile(
          icon: Icons.speed_rounded,
          labelKey: 'dashboard.workspace.avg_response',
          value: '${avgResponseMs}ms',
          tone: _responseTone(avgResponseMs),
          onTap: onResponseTap,
        ),
        _tile(
          icon: Icons.auto_awesome_rounded,
          labelKey: 'dashboard.workspace.ai_actions',
          value: '$aiActions24h',
          tone: 'ai',
          onTap: onAiTap,
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String labelKey,
    required String value,
    required String tone,
    VoidCallback? onTap,
  }) {
    return WButton(
      onTap: onTap ?? () {},
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: {tone},
            className: '''
              w-10 h-10 rounded-lg
              flex items-center justify-center
              bg-gray-100 dark:bg-gray-900
              up:bg-up-50 dark:up:bg-up-900/30
              down:bg-down-50 dark:down:bg-down-900/30
              primary:bg-primary-50 dark:primary:bg-primary-900/30
              ai:bg-ai-50 dark:ai:bg-ai-900/30
            ''',
            child: WIcon(
              icon,
              states: {tone},
              className: '''
                text-lg
                text-gray-500 dark:text-gray-400
                up:text-up-600 dark:up:text-up-300
                down:text-down-600 dark:down:text-down-300
                primary:text-primary-600 dark:primary:text-primary-300
                ai:text-ai-600 dark:ai:text-ai-300
              ''',
            ),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                value,
                className: '''
                  text-xl font-bold
                  text-gray-900 dark:text-white
                  truncate
                ''',
              ),
              WText(
                trans(labelKey),
                className: '''
                  text-xs font-semibold uppercase tracking-wide
                  text-gray-500 dark:text-gray-400
                  truncate
                ''',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _uptimeTone(double p) {
    if (p >= 99.5) return 'up';
    if (p >= 98.0) return 'primary';
    return 'down';
  }

  String _responseTone(int ms) {
    if (ms <= 300) return 'up';
    if (ms <= 800) return 'primary';
    return 'down';
  }
}
