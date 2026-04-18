import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';
import '../../../../app/models/monitor.dart';

/// Flat checkbox list of monitors that may be assigned to a status page.
class MonitorAssignList extends StatelessWidget {
  const MonitorAssignList({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<Monitor> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-lg
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        for (var i = 0; i < options.length; i++)
          _row(options[i], isLast: i == options.length - 1),
        _footer(),
      ],
    );
  }

  Widget _row(Monitor option, {required bool isLast}) {
    final isChecked = selected.contains(option.id);
    final tone = (option.lastStatus ?? MonitorStatus.paused).toneKey;
    return WButton(
      onTap: () => onToggle(option.id),
      states: {if (isChecked) 'checked', if (isLast) 'last'},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        checked:bg-primary-50/40 dark:checked:bg-primary-900/20
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: isChecked ? {'checked'} : {},
            className: '''
              w-5 h-5 rounded
              border-2
              border-gray-300 dark:border-gray-600
              checked:border-primary-500 dark:checked:border-primary-400
              checked:bg-primary-500 dark:checked:bg-primary-400
              flex items-center justify-center
            ''',
            child: isChecked
                ? WIcon(Icons.check_rounded, className: 'text-xs text-white')
                : const WDiv(className: 'w-0 h-0'),
          ),
          WDiv(
            states: {tone},
            className: '''
              w-2 h-2 rounded-full
              up:bg-up-500 dark:up:bg-up-400
              down:bg-down-500 dark:down:bg-down-400
              degraded:bg-degraded-500 dark:degraded:bg-degraded-400
              paused:bg-paused-400 dark:paused:bg-paused-300
            ''',
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                option.name ?? '',
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                  truncate
                ''',
              ),
              WText(
                option.url ?? '',
                className: '''
                  text-xs font-mono
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

  Widget _footer() {
    return WDiv(
      className: '''
        w-full px-4 py-3
        border-t border-gray-200 dark:border-gray-700
        bg-gray-50 dark:bg-gray-900
        rounded-b-lg
      ''',
      child: WText(
        trans(
          'status_page.create.assign.count',
        ).replaceAll(':count', '${selected.length}'),
        className: '''
          text-xs font-semibold
          text-gray-600 dark:text-gray-300
        ''',
      ),
    );
  }
}
