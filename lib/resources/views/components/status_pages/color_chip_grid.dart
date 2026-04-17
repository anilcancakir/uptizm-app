import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../common/color_swatch.dart';

/// Preset color chips + hex display for the status-page primary color.
class ColorChipGrid extends StatelessWidget {
  const ColorChipGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const presets = <String>[
    '#2563EB',
    '#7C3AED',
    '#EC4899',
    '#EF4444',
    '#F59E0B',
    '#10B981',
    '#06B6D4',
    '#111827',
  ];

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'wrap items-center gap-2',
          children: [
            for (final hex in presets) _chip(hex),
          ],
        ),
        WDiv(
          className: '''
            flex flex-row items-center gap-2
            rounded-lg p-2
            bg-gray-50 dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
          ''',
          children: [
            HexSwatch(hex: selected, size: 'sm', shape: 'square'),
            WText(
              selected.toUpperCase(),
              className: '''
                text-sm font-mono
                text-gray-700 dark:text-gray-200
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String hex) {
    final isSelected = hex.toUpperCase() == selected.toUpperCase();
    return WButton(
      onTap: () => onChanged(hex),
      states: isSelected ? {'active'} : {},
      className: '''
        w-9 h-9 rounded-full
        border-2
        border-transparent
        active:border-primary-500 dark:active:border-primary-400
        flex items-center justify-center
      ''',
      child: HexSwatch(hex: hex, size: 'md'),
    );
  }
}
