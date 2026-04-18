import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_severity.dart';
import '../../../../app/enums/incident_status.dart';
import '../ai/ai_avatar.dart';
import '../common/empty_state.dart';
import '../incidents/incident_severity_dot.dart';
import '../incidents/incident_status_pill.dart';

/// One active incident row for the dashboard strip.
class ActiveIncidentItem {
  const ActiveIncidentItem({
    required this.monitorId,
    required this.monitorName,
    required this.title,
    required this.severity,
    required this.status,
    required this.relativeTime,
    this.aiOwned = false,
  });

  final String monitorId;
  final String monitorName;
  final String title;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String relativeTime;
  final bool aiOwned;
}

/// Dashboard card listing currently unresolved incidents across all monitors.
///
/// Each row deep-links to the monitor's Incidents tab. AI-owned incidents
/// show the small AI avatar so ownership is obvious at a glance.
class ActiveIncidentsStrip extends StatelessWidget {
  const ActiveIncidentsStrip({super.key, required this.incidents});

  final List<ActiveIncidentItem> incidents;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        _header(),
        if (incidents.isEmpty)
          const EmptyState(
            icon: Icons.shield_moon_rounded,
            titleKey: 'dashboard.active_incidents.empty_title',
            subtitleKey: 'dashboard.active_incidents.empty',
            tone: 'up',
            variant: 'plain',
          )
        else
          WDiv(
            className: 'flex flex-col',
            children: [
              for (var i = 0; i < incidents.length; i++)
                _row(incidents[i], isLast: i == incidents.length - 1),
            ],
          ),
      ],
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-gray-200 dark:border-gray-700
        flex flex-row items-center justify-between gap-2
      ''',
      children: [
        WDiv(
          className: 'flex flex-col gap-0.5 min-w-0 flex-1',
          children: [
            WText(
              trans('dashboard.active_incidents.title'),
              className: '''
                text-sm font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('dashboard.active_incidents.subtitle'),
              className: 'text-xs text-gray-500 dark:text-gray-400 truncate',
            ),
          ],
        ),
        WButton(
          onTap: () => MagicRoute.to('/monitors'),
          className: '''
            px-3 py-2 rounded-lg
            hover:bg-gray-100 dark:hover:bg-gray-900/40
          ''',
          child: WText(
            trans('dashboard.active_incidents.view_all'),
            className: '''
              text-xs font-semibold
              text-primary-600 dark:text-primary-300
            ''',
          ),
        ),
      ],
    );
  }

  Widget _row(ActiveIncidentItem item, {required bool isLast}) {
    return WButton(
      onTap: () => MagicRoute.to('/monitors/${item.monitorId}?tab=incidents'),
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
          IncidentSeverityDot(severity: item.severity, status: item.status),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WDiv(
                className: 'flex flex-row items-center gap-2 min-w-0',
                children: [
                  WDiv(
                    className: 'flex-1 min-w-0',
                    child: WText(
                      item.title,
                      className: '''
                        text-sm font-semibold
                        text-gray-900 dark:text-white
                        truncate
                      ''',
                    ),
                  ),
                  if (item.aiOwned) const AiAvatar(size: 'sm'),
                ],
              ),
              WText(
                item.monitorName,
                className: '''
                  text-xs
                  text-gray-500 dark:text-gray-400
                  truncate
                ''',
              ),
            ],
          ),
          WText(
            item.relativeTime,
            className: '''
              text-xs
              text-gray-500 dark:text-gray-400
              hidden sm:block
            ''',
          ),
          IncidentStatusPill(status: item.status),
        ],
      ),
    );
  }
}
