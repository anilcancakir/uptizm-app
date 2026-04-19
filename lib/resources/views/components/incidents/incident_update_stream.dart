import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/incident.dart';
import 'incident_status_pill.dart';

/// Reverse-chronological list of operator-authored incident updates.
///
/// Mirrors the public status page's update card stack. Every row shows
/// the status transition (pill), the human display timestamp, and the
/// markdown body as plain text. `onEmpty` is rendered when the incident
/// has no updates yet so the admin never sees a blank column.
class IncidentUpdateStream extends StatelessWidget {
  const IncidentUpdateStream({super.key, required this.updates});

  final List<IncidentUpdate> updates;

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return WDiv(
        className: '''
          rounded-lg p-4 border
          bg-subtle dark:bg-subtle-dark
          border-subtle dark:border-subtle-dark
        ''',
        child: WText(
          trans('incident.update.empty'),
          className: '''
            text-sm
            text-muted dark:text-muted-dark
          ''',
        ),
      );
    }

    final ordered = [...updates]
      ..sort((a, b) => b.displayAt.compareTo(a.displayAt));

    return WDiv(
      className: 'flex flex-col gap-3',
      children: [for (final update in ordered) _row(update)],
    );
  }

  Widget _row(IncidentUpdate update) {
    return WDiv(
      className: '''
        rounded-lg p-4 border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        flex flex-col gap-2
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center justify-between gap-2',
          children: [
            IncidentStatusPill(status: update.status),
            WText(
              Carbon.parse(update.displayAt.toIso8601String()).diffForHumans(),
              className: '''
                text-xs
                text-muted dark:text-muted-dark
              ''',
            ),
          ],
        ),
        WText(
          update.body,
          className: '''
            text-sm leading-relaxed
            text-gray-800 dark:text-gray-100
          ''',
        ),
        if (update.authorLabel != null)
          WText(
            update.authorLabel!,
            className: '''
              text-xs
              text-muted dark:text-muted-dark
            ''',
          ),
      ],
    );
  }
}
