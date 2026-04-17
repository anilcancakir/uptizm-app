import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Small circular "Uptizm AI" avatar used in incident timelines.
///
/// Uses the `ai` tone (indigo) and an auto_awesome icon so AI-originated
/// events stand out visually from human actions.
class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, this.size = 'md'});

  /// `'sm'` (20px) or `'md'` (28px).
  final String size;

  @override
  Widget build(BuildContext context) {
    final states = size == 'sm' ? {'compact'} : <String>{};
    return WDiv(
      states: states,
      className: '''
        rounded-full
        bg-ai-500 dark:bg-ai-600
        flex items-center justify-center
        w-7 h-7 compact:w-5 compact:h-5
      ''',
      child: WIcon(
        Icons.auto_awesome_rounded,
        states: states,
        className: 'text-xs compact:text-[10px] text-white',
      ),
    );
  }
}
