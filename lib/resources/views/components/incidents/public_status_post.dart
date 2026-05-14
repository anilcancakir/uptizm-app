import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/incident.dart';
import 'incident_impact_badge.dart';
import 'incident_status_pill.dart';

/// Customer-facing incident card modeled after status.claude.com.
///
/// Renders the headline, impact chip, one-paragraph description, and the
/// append-only `incident_updates` timeline so operators (and eventually
/// the public status page) see the same post the AI analyzer wrote when
/// the incident opened. Falls back to an empty-updates hint when the
/// stream has no rows yet.
class PublicStatusPost extends StatelessWidget {
  const PublicStatusPost({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl overflow-hidden
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [_header(), _body(), _updatesList()],
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-center gap-2
      ''',
      children: [
        WIcon(
          Icons.public_rounded,
          className: 'text-sm text-gray-500 dark:text-gray-400',
        ),
        WText(
          trans('incident.public_post.title'),
          className: '''
            flex-1
            text-xs font-bold uppercase tracking-wider
            text-gray-500 dark:text-gray-400
          ''',
        ),
        IncidentImpactBadge(impact: incident.impact),
      ],
    );
  }

  Widget _body() {
    final description = incident.description?.trim() ?? '';
    return WDiv(
      className: '''
        px-4 py-4
        flex flex-col gap-2
        border-b border-gray-100 dark:border-gray-800
      ''',
      children: [
        WText(
          incident.title,
          className: '''
            text-base font-bold
            text-gray-900 dark:text-white
          ''',
        ),
        if (description.isNotEmpty)
          WText(
            description,
            className: '''
              text-sm leading-relaxed
              text-gray-700 dark:text-gray-300
            ''',
          ),
      ],
    );
  }

  Widget _updatesList() {
    final updates = [...incident.updates]
      ..sort((a, b) => b.displayAt.compareTo(a.displayAt));
    if (updates.isEmpty) {
      return WDiv(
        className: 'px-4 py-4',
        child: WText(
          trans('incident.update.empty'),
          className: '''
            text-xs italic
            text-gray-500 dark:text-gray-400
          ''',
        ),
      );
    }
    return WDiv(
      className: 'flex flex-col',
      children: [
        for (var i = 0; i < updates.length; i++)
          _updateRow(updates[i], isLast: i == updates.length - 1),
      ],
    );
  }

  Widget _updateRow(IncidentUpdate update, {required bool isLast}) {
    return WDiv(
      className:
          '''
        px-4 py-3
        flex flex-col gap-1.5
        ${isLast ? '' : 'border-b border-gray-100 dark:border-gray-800'}
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-2 flex-wrap',
          children: [
            IncidentStatusPill(status: update.status),
            WText(
              _ago(update.displayAt),
              className: '''
                text-[10px]
                text-gray-400 dark:text-gray-500
              ''',
            ),
          ],
        ),
        WText(
          update.body,
          className: '''
            text-xs leading-relaxed
            text-gray-700 dark:text-gray-300
          ''',
        ),
      ],
    );
  }

  String _ago(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return trans('time.just_now');
    if (diff.inHours < 1) {
      return trans('time.minutes_ago', {'minutes': '${diff.inMinutes}'});
    }
    if (diff.inDays < 1) {
      return trans('time.hours_ago', {'hours': '${diff.inHours}'});
    }
    return trans('time.days_ago', {'days': '${diff.inDays}'});
  }
}
