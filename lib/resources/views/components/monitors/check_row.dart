import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';
import '../common/monitor_status_dot.dart';

/// Single row in the "Recent checks" list.
///
/// Renders status dot, HTTP status code, response time, region, and the
/// human-readable "x minutes ago" timestamp.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.status,
    required this.checkedAt,
    this.statusCode,
    this.responseMs,
    this.region,
    this.errorMessage,
  });

  final MonitorStatus status;
  final DateTime checkedAt;
  final int? statusCode;
  final int? responseMs;
  final String? region;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
        px-4 py-3
        border-b border-gray-100 dark:border-gray-800
      ''',
      children: [
        MonitorStatusDot(toneKey: status.toneKey),
        WDiv(
          className: 'flex-1 flex flex-col gap-0.5',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                if (statusCode != null)
                  WText(
                    '$statusCode',
                    className: '''
                      text-sm font-mono font-semibold
                      text-gray-900 dark:text-white
                    ''',
                  ),
                if (responseMs != null)
                  WText(
                    '${responseMs}ms',
                    className: '''
                      text-sm font-mono
                      text-gray-600 dark:text-gray-300
                    ''',
                  ),
                if (region != null)
                  WText(
                    region!,
                    className: '''
                      text-xs
                      text-gray-500 dark:text-gray-400
                    ''',
                  ),
              ],
            ),
            if (errorMessage != null)
              WText(
                errorMessage!,
                className: '''
                  text-xs
                  text-down-600 dark:text-down-400
                ''',
              ),
          ],
        ),
        WText(
          _ago(checkedAt),
          className: 'text-xs text-gray-400 dark:text-gray-500',
        ),
      ],
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
