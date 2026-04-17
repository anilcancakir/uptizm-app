import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/ai_confidence.dart';

/// Coloured High / Medium / Low confidence pill.
class AiConfidenceBadge extends StatelessWidget {
  const AiConfidenceBadge({super.key, required this.confidence});

  final AiConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final tone = confidence.toneKey;
    return WDiv(
      states: {tone},
      className: '''
        px-2 py-0.5 rounded-full
        flex flex-row items-center gap-1
        high:bg-up-50 dark:high:bg-up-900/30
        medium:bg-degraded-50 dark:medium:bg-degraded-900/30
        low:bg-paused-100 dark:low:bg-paused-800
        border
        high:border-up-200 dark:high:border-up-800
        medium:border-degraded-200 dark:medium:border-degraded-800
        low:border-paused-200 dark:low:border-paused-700
      ''',
      children: [
        WDiv(
          states: {tone},
          className: '''
            w-1.5 h-1.5 rounded-full
            high:bg-up-500 dark:high:bg-up-400
            medium:bg-degraded-500 dark:medium:bg-degraded-400
            low:bg-paused-500 dark:low:bg-paused-300
          ''',
        ),
        WText(
          trans(confidence.labelKey),
          states: {tone},
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            high:text-up-700 dark:high:text-up-400
            medium:text-degraded-700 dark:medium:text-degraded-400
            low:text-paused-600 dark:low:text-paused-300
          ''',
        ),
      ],
    );
  }
}
