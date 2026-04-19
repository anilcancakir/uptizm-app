import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_impact.dart';

/// Five-level impact badge rendered next to the incident title.
///
/// Collapses the impact levels onto the same `neutral / info / warn /
/// danger` tone buckets the status pill uses, keeping the visual
/// language consistent across the detail header.
class IncidentImpactBadge extends StatelessWidget {
  const IncidentImpactBadge({super.key, required this.impact});

  final IncidentImpact impact;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      states: {impact.toneKey},
      className: '''
        px-2 py-0.5 rounded-full border
        neutral:bg-subtle dark:neutral:bg-subtle-dark
        neutral:border-subtle dark:neutral:border-subtle-dark
        info:bg-info-50 dark:info:bg-info-900/30
        info:border-info-200 dark:info:border-info-800
        warn:bg-degraded-50 dark:warn:bg-degraded-900/30
        warn:border-degraded-200 dark:warn:border-degraded-800
        danger:bg-down-50 dark:danger:bg-down-900/30
        danger:border-down-200 dark:danger:border-down-800
      ''',
      children: [
        WText(
          trans(impact.labelKey),
          states: {impact.toneKey},
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            neutral:text-muted dark:neutral:text-muted-dark
            info:text-info-700 dark:info:text-info-400
            warn:text-degraded-700 dark:warn:text-degraded-400
            danger:text-down-700 dark:danger:text-down-400
          ''',
        ),
      ],
    );
  }
}
