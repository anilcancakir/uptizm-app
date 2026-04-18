import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/incident.dart';
import '../ai/ai_avatar.dart';

/// Vertical timeline of events on an incident.
///
/// Renders a left rail with an avatar / dot for each event, plus a line
/// connecting them. AI actions use the `Uptizm AI` avatar; humans get a
/// gray initials chip.
class IncidentTimeline extends StatelessWidget {
  const IncidentTimeline({super.key, required this.events, this.detectedAt});

  final List<IncidentEvent> events;
  final DateTime? detectedAt;

  @override
  Widget build(BuildContext context) {
    final list = events.isEmpty && detectedAt != null
        ? [
            IncidentEvent(
              at: detectedAt!,
              actor: 'system',
              type: 'detected',
              message: trans('incident.timeline.detected'),
            ),
          ]
        : events;
    return WDiv(
      className: 'flex flex-col',
      children: [
        for (var i = 0; i < list.length; i++)
          _row(list[i], isLast: i == list.length - 1),
      ],
    );
  }

  Widget _row(IncidentEvent event, {required bool isLast}) {
    final isAi = event.actor == 'ai';
    final isSystem = event.actor == 'system';
    return IntrinsicHeight(
      child: WDiv(
        className: 'flex flex-row items-stretch gap-3',
        children: [
          WDiv(
            className: 'flex flex-col items-center',
            children: [
              _avatar(isAi: isAi, isSystem: isSystem, event: event),
              if (!isLast)
                WDiv(
                  className: '''
                    w-px flex-1
                    bg-gray-200 dark:bg-gray-700
                    mt-1
                  ''',
                ),
            ],
          ),
          WDiv(
            className: 'flex-1 pb-4 flex flex-col gap-0.5',
            children: [
              WDiv(
                className: 'flex flex-row items-center gap-2 flex-wrap',
                children: [
                  WText(
                    event.actorLabel ??
                        (isAi
                            ? trans('ai.actor_name')
                            : trans('incident.timeline.system')),
                    states: isAi ? {'ai'} : {},
                    className: '''
                      text-xs font-semibold
                      text-gray-800 dark:text-gray-100
                      ai:text-ai-700 dark:ai:text-ai-300
                    ''',
                  ),
                  WText(
                    _ago(event.at),
                    className: 'text-[10px] text-gray-400 dark:text-gray-500',
                  ),
                ],
              ),
              WText(
                event.message,
                className: '''
                  text-xs leading-relaxed
                  text-gray-700 dark:text-gray-300
                ''',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar({
    required bool isAi,
    required bool isSystem,
    required IncidentEvent event,
  }) {
    if (isAi) return const AiAvatar(size: 'sm');
    if (isSystem) {
      return WDiv(
        className: '''
          w-5 h-5 rounded-full
          bg-gray-100 dark:bg-gray-800
          border border-gray-200 dark:border-gray-700
          flex items-center justify-center
        ''',
        child: WIcon(
          Icons.settings_rounded,
          className: 'text-[10px] text-gray-500 dark:text-gray-400',
        ),
      );
    }
    final initial = (event.actorLabel ?? '?').trim().isEmpty
        ? '?'
        : (event.actorLabel ?? '?').trim()[0].toUpperCase();
    return WDiv(
      className: '''
        w-5 h-5 rounded-full
        bg-primary-100 dark:bg-primary-900/40
        flex items-center justify-center
      ''',
      child: WText(
        initial,
        className: '''
          text-[10px] font-bold
          text-primary-700 dark:text-primary-300
        ''',
      ),
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
