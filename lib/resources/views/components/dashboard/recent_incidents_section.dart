import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_severity.dart';
import '../../../../app/enums/incident_status.dart';
import '../common/empty_state.dart';
import '../incidents/incident_severity_dot.dart';
import '../incidents/incident_status_pill.dart';

/// Workspace-wide recent incidents summary on the dashboard.
///
/// Mock data for now. Rows link straight into the monitor's Incidents tab.
class RecentIncidentsSection extends StatelessWidget {
  const RecentIncidentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = _mockRows();
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            px-4 py-3
            border-b border-gray-200 dark:border-gray-700
            flex flex-row items-center justify-between gap-2
          ''',
          children: [
            WText(
              trans('dashboard.recent_incidents.title'),
              className: '''
                text-sm font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('dashboard.recent_incidents.window'),
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          ],
        ),
        if (rows.isEmpty)
          _empty()
        else
          WDiv(
            className: 'flex flex-col',
            children: [
              for (var i = 0; i < rows.length; i++)
                _row(rows[i], isLast: i == rows.length - 1),
            ],
          ),
      ],
    );
  }

  Widget _row(_IncidentRow r, {required bool isLast}) {
    return WButton(
      onTap: () =>
          MagicRoute.to('/monitors/${r.monitorId}?tab=incidents'),
      states: isLast ? {'last'} : {},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          IncidentSeverityDot(severity: r.severity, status: r.status),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                r.title,
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                  truncate
                ''',
              ),
              WText(
                r.monitorName,
                className: '''
                  text-xs
                  text-gray-500 dark:text-gray-400
                  truncate
                ''',
              ),
            ],
          ),
          WText(
            r.relativeTime,
            className: '''
              text-xs
              text-gray-500 dark:text-gray-400
              hidden sm:block
            ''',
          ),
          IncidentStatusPill(status: r.status),
        ],
      ),
    );
  }

  Widget _empty() {
    return const EmptyState(
      icon: Icons.shield_moon_rounded,
      titleKey: 'dashboard.recent_incidents.empty_title',
      subtitleKey: 'dashboard.recent_incidents.empty',
      tone: 'up',
      variant: 'plain',
    );
  }

  List<_IncidentRow> _mockRows() => const [
        _IncidentRow(
          monitorId: 'sample',
          monitorName: 'Production API',
          title: 'db.conn_ms crossed warn band (3 checks)',
          severity: IncidentSeverity.warn,
          status: IncidentStatus.investigating,
          relativeTime: '12m ago',
        ),
        _IncidentRow(
          monitorId: 'sample',
          monitorName: 'Checkout service',
          title: 'HTTP 503 from eu-west-1',
          severity: IncidentSeverity.critical,
          status: IncidentStatus.detected,
          relativeTime: '1h ago',
        ),
        _IncidentRow(
          monitorId: 'sample',
          monitorName: 'CDN origin',
          title: 'SSL certificate expires in 5 days',
          severity: IncidentSeverity.info,
          status: IncidentStatus.mitigated,
          relativeTime: '6h ago',
        ),
        _IncidentRow(
          monitorId: 'sample',
          monitorName: 'Auth service',
          title: 'Response time spike resolved',
          severity: IncidentSeverity.warn,
          status: IncidentStatus.resolved,
          relativeTime: 'yesterday',
        ),
        _IncidentRow(
          monitorId: 'sample',
          monitorName: 'Worker queue',
          title: 'queue_depth above 1k for 10 min',
          severity: IncidentSeverity.critical,
          status: IncidentStatus.resolved,
          relativeTime: '2 days ago',
        ),
      ];
}

class _IncidentRow {
  const _IncidentRow({
    required this.monitorId,
    required this.monitorName,
    required this.title,
    required this.severity,
    required this.status,
    required this.relativeTime,
  });

  final String monitorId;
  final String monitorName;
  final String title;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String relativeTime;
}
