import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';
import '../common/monitor_status_dot.dart';

/// Pill badge showing a monitor's current status with tone-aware colors.
///
/// Tone is driven by [MonitorStatus.toneKey] through the `states` param so
/// all variants share a single static className.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final MonitorStatus status;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      states: {status.toneKey},
      className: '''
        inline-flex flex-row items-center gap-1.5
        px-2.5 py-1 rounded-full
        up:bg-up-50 up:text-up-700 dark:up:bg-up-900/30 dark:up:text-up-300
        down:bg-down-50 down:text-down-700
        dark:down:bg-down-900/30 dark:down:text-down-300
        degraded:bg-degraded-50 degraded:text-degraded-700
        dark:degraded:bg-degraded-900/30 dark:degraded:text-degraded-300
        paused:bg-paused-100 paused:text-paused-700
        dark:paused:bg-paused-800/40 dark:paused:text-paused-300
      ''',
      children: [
        MonitorStatusDot(toneKey: status.toneKey, size: 'xs'),
        WText(trans(status.labelKey), className: 'text-xs font-semibold'),
      ],
    );
  }
}
