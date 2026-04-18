import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import 'skeleton_block.dart';

/// Pre-composed row skeleton mirroring `[dot | two text lines | trailing]`.
///
/// Used by list views (monitor_list, status_pages, activity) so the first
/// paint matches the eventual layout height and users don't see empty flash.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key, this.showTrailing = true});

  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        w-full px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-center gap-4
      ''',
      children: [
        const SkeletonBlock(className: 'w-3 h-3 rounded-full'),
        WDiv(
          className: 'flex-1 flex flex-col gap-1.5 min-w-0',
          children: const [
            SkeletonBlock(className: 'w-40 h-3.5'),
            SkeletonBlock(className: 'w-64 h-3'),
          ],
        ),
        if (showTrailing) const SkeletonBlock(className: 'w-16 h-5'),
      ],
    );
  }
}

/// Convenience: render [count] stacked [SkeletonRow]s inside the shared
/// card shell used by list views.
class SkeletonRowList extends StatelessWidget {
  const SkeletonRowList({super.key, this.count = 4, this.showTrailing = true});

  final int count;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl overflow-hidden
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        for (var i = 0; i < count; i++) SkeletonRow(showTrailing: showTrailing),
      ],
    );
  }
}
