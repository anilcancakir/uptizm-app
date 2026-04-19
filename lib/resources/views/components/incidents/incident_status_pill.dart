import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_status.dart';

/// Pill showing the incident lifecycle status.
///
/// Tones collapse the ten lifecycle states into four semantic buckets
/// (`success`, `info`, `warn`, `danger`) via `IncidentStatus.toneKey`, so
/// new statuses gain colors for free.
class IncidentStatusPill extends StatelessWidget {
  const IncidentStatusPill({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      states: {status.toneKey},
      className: '''
        px-2 py-0.5 rounded-full
        flex flex-row items-center gap-1
        success:bg-up-50 dark:success:bg-up-900/30
        info:bg-info-50 dark:info:bg-info-900/30
        warn:bg-degraded-50 dark:warn:bg-degraded-900/30
        danger:bg-down-50 dark:danger:bg-down-900/30
      ''',
      children: [
        WDiv(
          states: {status.toneKey},
          className: '''
            w-1.5 h-1.5 rounded-full
            success:bg-up-500 dark:success:bg-up-400
            info:bg-info-500 dark:info:bg-info-400
            warn:bg-degraded-500 dark:warn:bg-degraded-400
            danger:bg-down-500 dark:danger:bg-down-400
          ''',
        ),
        WText(
          trans(status.labelKey),
          states: {status.toneKey},
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            success:text-up-700 dark:success:text-up-400
            info:text-info-700 dark:info:text-info-400
            warn:text-degraded-700 dark:warn:text-degraded-400
            danger:text-down-700 dark:danger:text-down-400
          ''',
        ),
      ],
    );
  }
}
