import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_status.dart';

/// Pill showing the incident lifecycle status.
///
/// Tones: detected = down, investigating = degraded, mitigated = info,
/// resolved = up.
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
        detected:bg-down-50 dark:detected:bg-down-900/30
        investigating:bg-degraded-50 dark:investigating:bg-degraded-900/30
        mitigated:bg-info-50 dark:mitigated:bg-info-900/30
        resolved:bg-up-50 dark:resolved:bg-up-900/30
      ''',
      children: [
        WDiv(
          states: {status.toneKey},
          className: '''
            w-1.5 h-1.5 rounded-full
            detected:bg-down-500 dark:detected:bg-down-400
            investigating:bg-degraded-500 dark:investigating:bg-degraded-400
            mitigated:bg-info-500 dark:mitigated:bg-info-400
            resolved:bg-up-500 dark:resolved:bg-up-400
          ''',
        ),
        WText(
          trans(status.labelKey),
          states: {status.toneKey},
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            detected:text-down-700 dark:detected:text-down-400
            investigating:text-degraded-700 dark:investigating:text-degraded-400
            mitigated:text-info-700 dark:mitigated:text-info-400
            resolved:text-up-700 dark:resolved:text-up-400
          ''',
        ),
      ],
    );
  }
}
