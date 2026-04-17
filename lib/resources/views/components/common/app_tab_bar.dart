import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Simple horizontal tab bar used on detail screens.
///
/// Visual selection is driven by the `active` state prefix; callers supply
/// an ordered list of [AppTabItem]s and the index of the selected tab.
class AppTabItem {
  const AppTabItem({
    required this.labelKey,
    required this.icon,
  });

  final String labelKey;
  final IconData icon;
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.scrollable = false,
  });

  final List<AppTabItem> items;
  final int selected;
  final ValueChanged<int> onChanged;

  /// When true, tabs render as a horizontally-scrollable pill row instead
  /// of an evenly-split segmented control. Use on narrow viewports where
  /// the segmented layout would squeeze or wrap.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: WDiv(
          className: '''
            flex flex-row gap-2 p-1 rounded-lg
            bg-gray-100 dark:bg-gray-800
          ''',
          children: [
            for (var i = 0; i < items.length; i++)
              _tab(i, items[i], fillWidth: false),
          ],
        ),
      );
    }
    return WDiv(
      className: '''
        flex flex-row gap-1 p-1 rounded-lg
        bg-gray-100 dark:bg-gray-800
      ''',
      children: [
        for (var i = 0; i < items.length; i++)
          WDiv(
            className: 'flex-1',
            child: _tab(i, items[i], fillWidth: true),
          ),
      ],
    );
  }

  Widget _tab(int index, AppTabItem item, {required bool fillWidth}) {
    final isActive = index == selected;
    return WButton(
      onTap: () => onChanged(index),
      states: isActive ? {'active'} : {},
      className: '''
        ${fillWidth ? 'w-full' : ''} px-3 py-2.5 rounded-md
        flex flex-row items-center justify-center gap-2
        text-gray-600 dark:text-gray-300
        hover:text-gray-900 dark:hover:text-white
        active:bg-white dark:active:bg-gray-700
        active:text-gray-900 dark:active:text-white
        active:shadow-sm
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-2',
        children: [
          WIcon(item.icon, className: 'text-sm'),
          WText(
            trans(item.labelKey),
            className: 'text-sm font-semibold',
          ),
        ],
      ),
    );
  }
}
