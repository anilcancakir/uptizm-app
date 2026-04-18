import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Compact KPI card with icon, numeric value, optional trend delta.
///
/// Set [trendPositive] to paint the trend in up/down tones. Leave [trend]
/// `null` to hide the delta row entirely.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.trendPositive = true,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: onTap ?? () {},
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        flex flex-col gap-2
        items-stretch
      ''',
      child: WDiv(
        className: 'flex flex-col gap-2 w-full',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-2',
            children: [
              WIcon(
                icon,
                className:
                    'text-base text-gray-500 dark:text-gray-400 flex-shrink-0',
              ),
              WDiv(
                className: 'flex-1 min-w-0',
                child: WText(
                  label,
                  className: '''
                    text-xs font-semibold uppercase tracking-wide
                    text-gray-500 dark:text-gray-400
                    truncate
                  ''',
                ),
              ),
            ],
          ),
          WText(
            value,
            className: '''
            text-2xl font-bold truncate
            text-gray-900 dark:text-white
          ''',
          ),
          // Always reserve the trend row so cards stay the same height
          // whether a delta is available or not.
          WDiv(
            states: {trendPositive ? 'up' : 'down'},
            className: '''
              flex flex-row items-center gap-1 h-4
              up:text-up-600 down:text-down-600
              dark:up:text-up-400 dark:down:text-down-400
            ''',
            children: [
              if (trend != null) ...[
                WIcon(
                  trendPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  className: 'text-sm',
                ),
                WText(trend!, className: 'text-xs font-semibold'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
