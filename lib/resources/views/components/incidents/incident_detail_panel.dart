import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_status.dart';
import '../../../../app/models/incident.dart';
import 'ai_analysis_card.dart';
import 'incident_severity_dot.dart';
import 'incident_status_pill.dart';
import 'incident_timeline.dart';
import 'public_status_post.dart';

/// Right-side detail panel for an incident.
///
/// Re-used in two contexts: as a split-view panel on the Incidents tab
/// (desktop / tablet) and as a mobile bottom sheet.
class IncidentDetailPanel extends StatelessWidget {
  const IncidentDetailPanel({
    super.key,
    required this.incident,
    this.onClose,
    this.onAcknowledge,
    this.onResolve,
    this.onAddNote,
    this.onAcceptAi,
    this.onRejectAi,
  });

  final Incident incident;
  final VoidCallback? onClose;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onAddNote;
  final VoidCallback? onAcceptAi;
  final VoidCallback? onRejectAi;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-t-2xl
        bg-white dark:bg-gray-900
        border-t border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        _grabber(),
        _header(),
        WDiv(
          className: 'flex-1 overflow-y-auto',
          scrollPrimary: true,
          children: [
            WDiv(
              className: 'p-4 flex flex-col gap-4',
              children: [
                if (incident.aiAnalysis != null)
                  AiAnalysisCard(
                    analysis: incident.aiAnalysis!,
                    similar: incident.similarIncidents,
                    onAccept: onAcceptAi,
                    onReject: onRejectAi,
                  ),
                PublicStatusPost(incident: incident),
                _timelineCard(),
              ],
            ),
          ],
        ),
        _footer(),
      ],
    );
  }

  Widget _grabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: 'w-10 h-1 rounded-full bg-gray-300 dark:bg-gray-600',
      ),
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-gray-200 dark:border-gray-800
        flex flex-row items-start gap-3
      ''',
      children: [
        WDiv(
          className: 'pt-1',
          child: IncidentSeverityDot(severity: incident.severity),
        ),
        WDiv(
          className: 'flex-1 flex flex-col gap-1 min-w-0',
          children: [
            WText(
              incident.title,
              className: '''
                text-base font-bold
                text-gray-900 dark:text-white
              ''',
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
                  '• ${_formatDuration(incident.duration)}',
                  className: '''
                    text-xs
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
              ],
            ),
          ],
        ),
        if (onClose != null)
          WButton(
            onTap: onClose,
            className: '''
              w-8 h-8 rounded-lg
              bg-gray-100 dark:bg-gray-800
              hover:bg-gray-200 dark:hover:bg-gray-700
              flex items-center justify-center
            ''',
            child: WIcon(
              Icons.close_rounded,
              className: 'text-sm text-gray-600 dark:text-gray-300',
            ),
          ),
      ],
    );
  }

  Widget _timelineCard() {
    return WDiv(
      className: '''
        rounded-xl overflow-hidden
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            px-4 py-3
            border-b border-gray-100 dark:border-gray-800
            flex flex-row items-center gap-2
          ''',
          children: [
            WIcon(
              Icons.timeline_rounded,
              className: 'text-sm text-gray-500 dark:text-gray-400',
            ),
            WText(
              trans('incident.timeline.title'),
              className: '''
                flex-1
                text-xs font-bold uppercase tracking-wider
                text-gray-500 dark:text-gray-400
              ''',
            ),
            WButton(
              onTap: onAddNote,
              className: '''
                px-3 py-1.5 rounded-lg
                bg-primary-600 dark:bg-primary-500
                hover:bg-primary-700 dark:hover:bg-primary-400
                active:bg-primary-800 dark:active:bg-primary-300
                flex flex-row items-center gap-1.5
              ''',
              child: WDiv(
                className: 'flex flex-row items-center gap-1.5',
                children: [
                  WIcon(Icons.send_rounded, className: 'text-xs text-white'),
                  WText(
                    trans('incident.timeline.post_update'),
                    className: 'text-xs font-semibold text-white',
                  ),
                ],
              ),
            ),
          ],
        ),
        WDiv(
          className: 'p-4',
          child: IncidentTimeline(
            events: incident.events,
            detectedAt: incident.startedAt,
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    final isResolved = incident.status == IncidentStatus.resolved;
    final isDetected = incident.status == IncidentStatus.detected;
    return WDiv(
      className: '''
        px-4 py-3
        border-t border-gray-200 dark:border-gray-800
        bg-white dark:bg-gray-900
        flex flex-row items-center gap-2
      ''',
      children: [
        WDiv(
          className: 'flex-1',
          child: WText(
            incident.aiOwned
                ? trans('incident.footer.ai_owned')
                : trans('incident.footer.human_owned'),
            className: 'text-[10px] text-gray-500 dark:text-gray-400',
          ),
        ),
        // Primary: Acknowledge for detected, Resolve after ack. Hidden
        // once resolved so the drawer cannot reopen the lifecycle.
        if (!isResolved && isDetected)
          WButton(
            onTap: onAcknowledge,
            className: '''
              px-3 py-2 rounded-lg
              bg-primary-600 dark:bg-primary-500
              hover:bg-primary-700 dark:hover:bg-primary-400
              flex flex-row items-center gap-1.5
            ''',
            child: WDiv(
              className: 'flex flex-row items-center gap-1.5',
              children: [
                WIcon(
                  Icons.visibility_rounded,
                  className: 'text-sm text-white',
                ),
                WText(
                  trans('incident.actions.acknowledge'),
                  className: 'text-xs font-semibold text-white',
                ),
              ],
            ),
          ),
        if (!isResolved && !isDetected)
          WButton(
            onTap: onResolve,
            className: '''
              px-3 py-2 rounded-lg
              bg-up-500 dark:bg-up-600
              hover:bg-up-600 dark:hover:bg-up-700
              flex flex-row items-center gap-1.5
            ''',
            child: WDiv(
              className: 'flex flex-row items-center gap-1.5',
              children: [
                WIcon(Icons.check_rounded, className: 'text-sm text-white'),
                WText(
                  trans('incident.actions.resolve'),
                  className: 'text-xs font-semibold text-white',
                ),
              ],
            ),
          ),
        // Secondary: Close on the far right — always available, defuses
        // muscle-memory resolves on the primary action.
        WButton(
          onTap: onClose,
          className: '''
            px-3 py-2 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            flex flex-row items-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.close_rounded,
                className: 'text-sm text-gray-600 dark:text-gray-300',
              ),
              WText(
                trans('incident.actions.close'),
                className: '''
                  text-xs font-semibold
                  text-gray-700 dark:text-gray-200
                ''',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}
