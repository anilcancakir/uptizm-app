import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/ai_mode.dart';

/// 3-segment selector for the monitor-level AI autonomy mode.
///
/// Off / Suggest / Auto. Each segment shows a tiny icon and label; the active
/// segment flips to the `ai` tone so users can see at a glance whether the
/// monitor is under AI control.
class AiModeSelector extends StatelessWidget {
  const AiModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AiMode selected;
  final ValueChanged<AiMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        flex flex-row p-1 rounded-lg gap-1
        bg-gray-100 dark:bg-gray-800
      ''',
      children: [for (final m in AiMode.values) _segment(m)],
    );
  }

  Widget _segment(AiMode mode) {
    final isActive = selected == mode;
    return WButton(
      onTap: () => onChanged(mode),
      states: isActive ? {'active', mode.name} : {},
      className: '''
        px-3 py-1.5 rounded-md
        flex flex-row items-center gap-1.5
        text-gray-600 dark:text-gray-300
        hover:text-gray-900 dark:hover:text-white
        active:bg-white dark:active:bg-gray-700
        active:shadow-sm
        auto:active:bg-ai-50 dark:auto:active:bg-ai-900/30
        suggest:active:bg-ai-50/50 dark:suggest:active:bg-ai-900/20
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-1.5',
        children: [
          WIcon(
            _icon(mode),
            states: isActive ? {'active', mode.name} : {},
            className: '''
              text-xs
              text-gray-500 dark:text-gray-400
              auto:active:text-ai-600 dark:auto:active:text-ai-300
              suggest:active:text-ai-500 dark:suggest:active:text-ai-400
              off:active:text-gray-700 dark:off:active:text-gray-200
            ''',
          ),
          WText(
            trans(mode.labelKey),
            states: isActive ? {'active', mode.name} : {},
            className: '''
              text-xs font-semibold
              text-gray-700 dark:text-gray-200
              auto:active:text-ai-700 dark:auto:active:text-ai-300
              suggest:active:text-ai-600 dark:suggest:active:text-ai-400
            ''',
          ),
        ],
      ),
    );
  }

  IconData _icon(AiMode m) {
    return switch (m) {
      AiMode.off => Icons.toggle_off_outlined,
      AiMode.suggest => Icons.lightbulb_outline_rounded,
      AiMode.auto => Icons.auto_awesome_rounded,
    };
  }
}
