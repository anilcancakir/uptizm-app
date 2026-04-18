import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Single chip option in a [ChipMultiSelect].
class ChipOption {
  const ChipOption({required this.value, required this.label, this.subtitle});

  final String value;
  final String label;
  final String? subtitle;
}

/// Wrap of toggle chips used as a multi-select picker (e.g. regions).
class ChipMultiSelect extends StatelessWidget {
  const ChipMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<ChipOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'wrap gap-2',
      children: [for (final o in options) _chip(o)],
    );
  }

  Widget _chip(ChipOption o) {
    final isOn = selected.contains(o.value);
    return WButton(
      onTap: () {
        final next = {...selected};
        if (isOn) {
          next.remove(o.value);
        } else {
          next.add(o.value);
        }
        onChanged(next);
      },
      states: isOn ? {'selected'} : {},
      className: '''
        px-3 py-2 rounded-full
        flex flex-row items-center gap-2
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        selected:bg-primary-50 dark:selected:bg-primary-900/30
        selected:border-primary-500 dark:selected:border-primary-400
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-2',
        children: [
          WDiv(
            states: isOn ? {'selected'} : {},
            className: '''
              w-4 h-4 rounded-full
              flex items-center justify-center
              border border-gray-300 dark:border-gray-600
              selected:bg-primary-500 dark:selected:bg-primary-400
              selected:border-primary-500 dark:selected:border-primary-400
            ''',
            child: isOn
                ? WIcon(
                    Icons.check_rounded,
                    className: 'text-[10px] text-white dark:text-white',
                  )
                : const WSpacer(),
          ),
          WText(
            o.label,
            states: isOn ? {'selected'} : {},
            className: '''
              text-xs font-semibold
              text-gray-700 dark:text-gray-200
              selected:text-primary-700 dark:selected:text-primary-300
            ''',
          ),
        ],
      ),
    );
  }
}
