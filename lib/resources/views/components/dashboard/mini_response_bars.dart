import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';

/// Tiny status-bar sparkline (12 bars) for the dashboard monitors list.
///
/// Each bar is colored by the sample's status. Bars stretch to fill the
/// parent width, so drop it in a bounded `WDiv` (e.g., `w-24`).
class MiniResponseBars extends StatelessWidget {
  const MiniResponseBars({super.key, required this.samples});

  final List<MonitorStatus> samples;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return WDiv(
        className: '''
          h-5 rounded-sm
          bg-gray-100 dark:bg-gray-900
        ''',
      );
    }
    return WDiv(
      className: 'flex flex-row gap-[2px] h-5 items-end',
      children: [
        for (final s in samples)
          WDiv(
            states: {s.toneKey},
            className: '''
              flex-1 rounded-sm
              h-3 up:h-3 degraded:h-4 down:h-5 paused:h-2
              bg-gray-300 dark:bg-gray-700
              up:bg-up-400 dark:up:bg-up-500
              degraded:bg-degraded-400 dark:degraded:bg-degraded-500
              down:bg-down-500 dark:down:bg-down-400
              paused:bg-paused-300 dark:paused:bg-paused-500
            ''',
          ),
      ],
    );
  }
}
