import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Generic segmented control for single-choice selection among 2-4 items.
///
/// Selection is driven via [states]: the active tab gets the `active` prefix.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
    this.iconBuilder,
    this.scrollable = false,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelBuilder;
  final IconData? Function(T value)? iconBuilder;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: WDiv(
          className: '''
            flex flex-row gap-1 p-1 rounded-lg
            bg-gray-100 dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
          ''',
          children: [for (final o in options) _tab(o)],
        ),
      );
    }
    return WDiv(
      className: '''
        flex flex-row gap-1 p-1 rounded-lg
        bg-gray-100 dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
      ''',
      children: [for (final o in options) _tab(o)],
    );
  }

  Widget _tab(T option) {
    final isActive = option == selected;
    final icon = iconBuilder?.call(option);
    final label = labelBuilder?.call(option) ?? option.toString();

    return WDiv(
      className: scrollable ? '' : 'flex-1',
      child: WButton(
        onTap: () => onChanged(option),
        states: isActive ? {'active'} : {},
        className:
            '''
          ${scrollable ? '' : 'w-full'} px-2 py-2.5 rounded-md
          flex flex-row items-center justify-center gap-1.5
          text-gray-600 dark:text-gray-300
          hover:text-gray-900 dark:hover:text-white
          active:bg-white dark:active:bg-gray-700
          active:text-gray-900 dark:active:text-white
          active:shadow-sm
        ''',
        child: WDiv(
          className: 'flex flex-row items-center gap-1.5 min-w-0',
          children: [
            if (icon != null) WIcon(icon, className: 'text-sm'),
            scrollable
                ? WText(label, className: 'text-sm font-semibold')
                : WDiv(
                    className: 'flex-1 min-w-0',
                    child: WText(
                      label,
                      className: 'text-sm font-semibold truncate',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
