import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_severity.dart';
import '../../../../app/enums/incident_status.dart';

/// Coloured dot indicating incident severity.
///
/// Uses existing Wind tones: `critical` → down/red, `warn` → degraded/amber,
/// `info` → info/blue. If [status] is supplied and inactive (resolved), the
/// dot dims so severity + status no longer compete for attention.
class IncidentSeverityDot extends StatelessWidget {
  const IncidentSeverityDot({
    super.key,
    required this.severity,
    this.status,
    this.size = 'md',
  });

  final IncidentSeverity severity;
  final IncidentStatus? status;

  /// `'sm'` (6px) or `'md'` (10px).
  final String size;

  @override
  Widget build(BuildContext context) {
    final dim = size == 'sm' ? 'w-1.5 h-1.5' : 'w-2.5 h-2.5';
    final dimmed = status != null && !status!.isActive;
    return WDiv(
      states: {
        severity.toneKey,
        if (dimmed) 'dimmed',
      },
      className: '''
        $dim rounded-full
        critical:bg-down-500 dark:critical:bg-down-400
        warn:bg-degraded-500 dark:warn:bg-degraded-400
        info:bg-info-500 dark:info:bg-info-400
        dimmed:opacity-40
      ''',
    );
  }
}
