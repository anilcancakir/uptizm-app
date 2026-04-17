import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/mock/check_log.dart';
import '../common/monitor_status_dot.dart';

/// Single row in the Checks timeline.
///
/// Condensed, tappable variant: status dot + HTTP method/code + response time
/// + region badge + "x m ago" timestamp. Tapping opens the detail sheet.
class CheckTimelineRow extends StatelessWidget {
  const CheckTimelineRow({
    super.key,
    required this.check,
    this.onTap,
  });

  final CheckLog check;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = check.status.toneKey;
    return WButton(
      onTap: onTap,
      className: '''
        w-full px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        hover:bg-gray-50 dark:hover:bg-gray-800/40
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          MonitorStatusDot(toneKey: tone),
          WDiv(
            className: 'flex-1 flex flex-row items-center gap-2 min-w-0',
            children: [
              WText(
                check.method,
                className: '''
                  text-xs font-mono font-bold
                  text-gray-500 dark:text-gray-400
                ''',
              ),
              WText(
                '${check.statusCode ?? '--'}',
                className: '''
                  text-sm font-mono font-semibold
                  text-gray-900 dark:text-white
                ''',
              ),
              if (check.responseMs != null)
                WText(
                  '${check.responseMs} ms',
                  className: '''
                    text-xs font-mono
                    text-gray-600 dark:text-gray-300
                  ''',
                ),
              WDiv(
                className: '''
                  px-2 py-0.5 rounded-full
                  bg-gray-100 dark:bg-gray-800
                ''',
                child: WText(
                  check.region,
                  className: '''
                    text-[10px] font-bold font-mono uppercase
                    text-gray-600 dark:text-gray-300
                  ''',
                ),
              ),
              if (check.errorMessage != null)
                WDiv(
                  className: 'flex-1 min-w-0',
                  child: WText(
                    check.errorMessage!,
                    className: '''
                      text-xs truncate
                      text-down-600 dark:text-down-400
                    ''',
                  ),
                ),
            ],
          ),
          WText(
            _ago(check.checkedAt),
            className: 'text-xs text-gray-400 dark:text-gray-500',
          ),
        ],
      ),
    );
  }

  String _ago(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return trans('time.just_now');
    if (diff.inHours < 1) {
      return trans('time.minutes_ago', {'minutes': '${diff.inMinutes}'});
    }
    if (diff.inDays < 1) {
      return trans('time.hours_ago', {'hours': '${diff.inHours}'});
    }
    return trans('time.days_ago', {'days': '${diff.inDays}'});
  }
}
