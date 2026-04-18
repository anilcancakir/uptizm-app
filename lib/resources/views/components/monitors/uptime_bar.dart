import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';

/// Single day in the uptime strip.
class UptimeDay {
  const UptimeDay({required this.date, required this.status});

  final DateTime date;
  final MonitorStatus status;
}

/// Horizontal strip of day segments colored by daily monitor status.
///
/// Segments grow with `flex-1` so the strip always spans the parent width,
/// independent of the number of days passed in.
class UptimeBar extends StatelessWidget {
  const UptimeBar({super.key, required this.days, required this.uptimePercent});

  final List<UptimeDay> days;
  final double uptimePercent;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-row items-baseline justify-between',
          children: [
            WText(
              '${uptimePercent.toStringAsFixed(2)}%',
              className: '''
                text-xl font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('monitor.uptime.window', {'days': '${days.length}'}),
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-row gap-0.5 h-8 rounded-md overflow-hidden',
          children: days.map(_segment).toList(),
        ),
      ],
    );
  }

  Widget _segment(UptimeDay day) {
    return WDiv(
      states: {day.status.toneKey},
      className: '''
        flex-1 h-full
        up:bg-up-500 down:bg-down-500
        degraded:bg-degraded-500 paused:bg-paused-400
        dark:up:bg-up-400 dark:down:bg-down-400
        dark:degraded:bg-degraded-400 dark:paused:bg-paused-500
      ''',
    );
  }
}
