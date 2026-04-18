import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Reusable empty-state block for list/grid/tab surfaces.
///
/// Renders a tinted icon circle, title, optional subtitle, and an optional
/// action button. [tone] is a Tailwind color key (`primary`, `up`, `down`,
/// `degraded`, `paused`, `gray`).
///
/// [variant] controls the wrapping:
/// - `'card'` (default): wraps in a bordered rounded card, use inside page
///   surfaces that don't already provide a card.
/// - `'plain'`: no border/bg, for use inside an existing card.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.titleKey,
    this.subtitleKey,
    this.tone = 'primary',
    this.variant = 'card',
    this.action,
  });

  final IconData icon;
  final String titleKey;
  final String? subtitleKey;
  final String tone;
  final String variant;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final wrapper = variant == 'plain'
        ? 'w-full p-6 flex flex-col items-center text-center gap-3'
        : '''
          w-full rounded-xl p-8
          bg-white dark:bg-gray-800
          border border-gray-200 dark:border-gray-700
          flex flex-col items-center text-center gap-3
        ''';
    return WDiv(
      className: wrapper,
      children: [
        WDiv(
          className:
              '''
            w-12 h-12 rounded-full
            bg-$tone-50 dark:bg-$tone-900/30
            flex items-center justify-center
          ''',
          child: WIcon(
            icon,
            className: 'text-xl text-$tone-600 dark:text-$tone-300',
          ),
        ),
        WText(
          trans(titleKey),
          className: '''
            text-base font-semibold
            text-gray-900 dark:text-white
          ''',
        ),
        if (subtitleKey != null)
          WText(
            trans(subtitleKey!),
            className: '''
              text-sm max-w-md
              text-gray-500 dark:text-gray-400
            ''',
          ),
        if (action != null) WDiv(className: 'pt-2', child: action),
      ],
    );
  }
}
