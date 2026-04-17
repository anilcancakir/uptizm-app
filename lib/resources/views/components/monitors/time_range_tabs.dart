import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Time-window options shown as segmented tabs above the response chart.
enum TimeRange {
  h24,
  d7,
  d30,
  d90;

  String get labelKey => 'monitor.range.$name';
}

/// Segmented pill tabs for picking a chart window.
///
/// Selection is driven by the `active` state key; no className interpolation.
class TimeRangeTabs extends StatelessWidget {
  const TimeRangeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        flex flex-row gap-1 p-1 rounded-lg
        bg-gray-100 dark:bg-gray-800
      ''',
      children: TimeRange.values.map(_tab).toList(),
    );
  }

  Widget _tab(TimeRange range) {
    final isActive = range == selected;

    return WButton(
      onTap: () => onChanged(range),
      states: isActive ? {'active'} : {},
      className: '''
        px-3 py-2 rounded-md
        text-xs font-semibold
        text-gray-600 dark:text-gray-300
        hover:text-gray-900 dark:hover:text-white
        active:bg-white dark:active:bg-gray-700
        active:text-gray-900 dark:active:text-white
        active:shadow-sm
      ''',
      child: WText(trans(range.labelKey)),
    );
  }
}
