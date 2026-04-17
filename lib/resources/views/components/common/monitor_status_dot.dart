import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Small tone-aware dot reused across check rows, status pills, and badges.
///
/// `toneKey` drives the color via `states` (up/down/degraded/paused).
class MonitorStatusDot extends StatelessWidget {
  const MonitorStatusDot({
    super.key,
    required this.toneKey,
    this.size = 'sm',
  });

  final String toneKey;

  /// `'xs'` (6px) | `'sm'` (8px) | `'md'` (10px).
  final String size;

  @override
  Widget build(BuildContext context) {
    final dim = switch (size) {
      'xs' => 'w-1.5 h-1.5',
      'md' => 'w-2.5 h-2.5',
      _ => 'w-2 h-2',
    };
    return WDiv(
      states: {toneKey},
      className: '''
        $dim rounded-full
        bg-gray-400 dark:bg-gray-500
        up:bg-up-500 dark:up:bg-up-400
        down:bg-down-500 dark:down:bg-down-400
        degraded:bg-degraded-500 dark:degraded:bg-degraded-400
        paused:bg-paused-500 dark:paused:bg-paused-300
      ''',
    );
  }
}
