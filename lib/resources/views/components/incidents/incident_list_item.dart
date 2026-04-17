import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/signal_source.dart';
import '../../../../app/models/mock/incident.dart';
import '../ai/ai_avatar.dart';
import 'incident_severity_dot.dart';
import 'incident_status_pill.dart';

/// Row in the incidents list.
///
/// Shows severity dot, title, signal-source badge, status pill, duration,
/// AI badge (if AI-owned) and a subtle "selected" state for split-view.
class IncidentListItem extends StatelessWidget {
  const IncidentListItem({
    super.key,
    required this.incident,
    this.selected = false,
    this.onTap,
  });

  final Incident incident;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: onTap,
      states: selected ? {'selected'} : {},
      className: '''
        w-full px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        hover:bg-gray-50 dark:hover:bg-gray-800/50
        selected:bg-primary-50 dark:selected:bg-primary-900/20
        selected:border-l-4 selected:border-l-primary-500
        flex flex-row items-start gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-start gap-3 w-full',
        children: [
          WDiv(
            className: 'pt-1.5',
            child: IncidentSeverityDot(severity: incident.severity),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-1 min-w-0',
            children: [
              WDiv(
                className: 'flex flex-row items-center gap-2',
                children: [
                  WDiv(
                    className: 'flex-1 min-w-0',
                    child: WText(
                      incident.title,
                      className: '''
                        text-sm font-semibold truncate
                        text-gray-900 dark:text-white
                      ''',
                    ),
                  ),
                  _SignalSourceBadge(source: incident.signalSource),
                  if (incident.aiOwned) const AiAvatar(size: 'sm'),
                ],
              ),
              WDiv(
                className: 'flex flex-row items-center gap-2 flex-wrap',
                children: [
                  IncidentStatusPill(status: incident.status),
                  if (incident.metricLabel != null)
                    WText(
                      incident.metricLabel!,
                      className: '''
                        text-xs font-mono
                        text-gray-500 dark:text-gray-400
                      ''',
                    ),
                  WText(
                    '• ${_duration(incident.duration)}',
                    className: 'text-xs text-gray-400 dark:text-gray-500',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _duration(Duration d) {
    if (d.inMinutes < 1) return trans('time.just_now');
    if (d.inHours < 1) {
      return trans('time.minutes_ago', {'minutes': '${d.inMinutes}'});
    }
    if (d.inDays < 1) {
      return trans('time.hours_ago', {'hours': '${d.inHours}'});
    }
    return trans('time.days_ago', {'days': '${d.inDays}'});
  }
}

class _SignalSourceBadge extends StatelessWidget {
  const _SignalSourceBadge({required this.source});

  final SignalSource source;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: trans(source.tooltipKey),
      child: WDiv(
        states: {source.toneKey},
        className: '''
          w-6 h-6 rounded-md
          flex items-center justify-center
          bg-gray-100 dark:bg-gray-700
          threshold:bg-warn-50 dark:threshold:bg-warn-900/30
          ai:bg-ai-50 dark:ai:bg-ai-900/30
          manual:bg-gray-100 dark:manual:bg-gray-700
        ''',
        child: WIcon(
          _iconFor(source),
          states: {source.toneKey},
          className: '''
            text-xs
            text-gray-500 dark:text-gray-400
            threshold:text-warn-600 dark:threshold:text-warn-300
            ai:text-ai-600 dark:ai:text-ai-300
            manual:text-gray-600 dark:manual:text-gray-300
          ''',
        ),
      ),
    );
  }

  IconData _iconFor(SignalSource s) {
    return switch (s) {
      SignalSource.userThreshold => Icons.speed_rounded,
      SignalSource.aiAnomaly => Icons.auto_awesome_rounded,
      SignalSource.manual => Icons.pan_tool_alt_rounded,
    };
  }
}
