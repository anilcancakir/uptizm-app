import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Section wrapper for an iOS-style grouped settings list.
///
/// Renders a small uppercase label followed by a rounded card that holds
/// the [rows]. The rows themselves draw their own separators and corner
/// radii based on their `isFirst`/`isLast` flags.
class SettingsListSection extends StatelessWidget {
  const SettingsListSection({
    super.key,
    required this.titleKey,
    required this.rows,
  });

  final String titleKey;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        WText(
          trans(titleKey),
          className: '''
            text-xs font-bold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
            px-1
          ''',
        ),
        WDiv(
          className: '''
            rounded-xl
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            overflow-hidden
            flex flex-col
          ''',
          children: rows,
        ),
      ],
    );
  }
}
