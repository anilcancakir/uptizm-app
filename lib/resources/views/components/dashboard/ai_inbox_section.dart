import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/ai_confidence.dart';
import '../ai/ai_avatar.dart';
import '../ai/ai_confidence_badge.dart';
import '../common/empty_state.dart';

/// One AI suggestion row in the dashboard inbox.
class AiInboxItem {
  const AiInboxItem({
    required this.id,
    required this.monitorName,
    required this.tldr,
    required this.confidence,
    required this.relativeTime,
    this.metricKey,
  });

  final String id;
  final String monitorName;
  final String tldr;
  final AiConfidence confidence;
  final String relativeTime;
  final String? metricKey;
}

/// Dashboard card listing AI-authored suggestions awaiting review.
///
/// Only shown when the workspace's AI default is `suggest` or at least one
/// monitor overrides to `suggest`. Accept / skip are UI-only stubs here;
/// behavior gets wired up in a later pass.
class AiInboxSection extends StatelessWidget {
  const AiInboxSection({
    super.key,
    required this.suggestions,
    this.onAccept,
    this.onSkip,
  });

  final List<AiInboxItem> suggestions;
  final ValueChanged<String>? onAccept;
  final ValueChanged<String>? onSkip;

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
        if (suggestions.isEmpty)
          const EmptyState(
            icon: Icons.mark_email_read_outlined,
            titleKey: 'dashboard.ai_inbox.empty_title',
            subtitleKey: 'dashboard.ai_inbox.empty',
            tone: 'primary',
            variant: 'plain',
          )
        else
          WDiv(
            className: 'flex flex-col',
            children: [
              for (var i = 0; i < suggestions.length; i++)
                _row(suggestions[i], isLast: i == suggestions.length - 1),
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
        flex flex-row items-center gap-3
      ''',
      children: [
        const AiAvatar(size: 'sm'),
        WDiv(
          className: 'flex-1 flex flex-col gap-0.5 min-w-0',
          children: [
            WText(
              trans('dashboard.ai_inbox.title'),
              className: '''
                text-sm font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('dashboard.ai_inbox.subtitle'),
              className: 'text-xs text-gray-500 dark:text-gray-400 truncate',
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(AiInboxItem item, {required bool isLast}) {
    return WDiv(
      states: isLast ? {'last'} : {},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        flex flex-col gap-3
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-start gap-3',
          children: [
            WDiv(
              className: 'flex-1 flex flex-col gap-1 min-w-0',
              children: [
                WDiv(
                  className: 'flex flex-row items-center gap-2 min-w-0',
                  children: [
                    WDiv(
                      className: 'flex-1 min-w-0',
                      child: WText(
                        item.monitorName,
                        className: '''
                          text-sm font-semibold
                          text-gray-900 dark:text-white
                          truncate
                        ''',
                      ),
                    ),
                    AiConfidenceBadge(confidence: item.confidence),
                  ],
                ),
                WText(
                  item.tldr,
                  className: '''
                    text-sm
                    text-gray-600 dark:text-gray-300
                  ''',
                ),
                WDiv(
                  className: 'flex flex-row items-center gap-2',
                  children: [
                    if (item.metricKey != null)
                      WDiv(
                        className: '''
                          px-2 py-0.5 rounded-full
                          bg-gray-100 dark:bg-gray-900
                          border border-gray-200 dark:border-gray-700
                        ''',
                        child: WText(
                          item.metricKey!,
                          className: '''
                            text-[10px] font-mono
                            text-gray-600 dark:text-gray-300
                          ''',
                        ),
                      ),
                    WText(
                      item.relativeTime,
                      className: '''
                        text-xs
                        text-gray-500 dark:text-gray-400
                      ''',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-row items-center justify-end gap-2',
          children: [
            WButton(
              onTap: () => onSkip?.call(item.id),
              className: '''
                px-4 py-3 rounded-lg
                border border-gray-200 dark:border-gray-700
                hover:bg-gray-50 dark:hover:bg-gray-900/40
              ''',
              child: WText(
                trans('dashboard.ai_inbox.skip'),
                className: '''
                  text-sm font-semibold
                  text-gray-700 dark:text-gray-200
                ''',
              ),
            ),
            WButton(
              onTap: () => onAccept?.call(item.id),
              className: '''
                px-4 py-3 rounded-lg
                bg-ai-600 hover:bg-ai-700
                dark:bg-ai-500 dark:hover:bg-ai-400
                flex flex-row items-center gap-2
              ''',
              child: WDiv(
                className: 'flex flex-row items-center gap-2',
                children: [
                  WIcon(
                    Icons.check_rounded,
                    className: 'text-sm text-white dark:text-white',
                  ),
                  WText(
                    trans('dashboard.ai_inbox.accept'),
                    className: '''
                      text-sm font-semibold
                      text-white dark:text-white
                    ''',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
