import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Region option rendered by [RegionMultiSelect].
class RegionOption {
  const RegionOption({
    required this.value,
    required this.code,
    required this.flag,
    required this.city,
    required this.country,
  });

  final String value;
  final String code;
  final String flag;
  final String city;
  final String country;
}

/// Responsive card grid for selecting probe regions.
///
/// Each card shows the flag, short region code, city and country, with a
/// circular check indicator in the top-right corner. Cards toggle between
/// idle and `selected` states via the `states` param so there is zero Dart
/// interpolation in the className.
class RegionMultiSelect extends StatelessWidget {
  const RegionMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<RegionOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3
      ''',
      children: [for (final o in options) _card(o)],
    );
  }

  Widget _card(RegionOption o) {
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
        relative w-full p-3 rounded-xl
        flex flex-row items-center gap-3
        bg-white dark:bg-gray-900/40
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        selected:bg-primary-50 dark:selected:bg-primary-900/20
        selected:border-primary-500 dark:selected:border-primary-400
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: isOn ? {'selected'} : {},
            className: '''
              w-10 h-10 rounded-lg
              flex items-center justify-center
              bg-gray-50 dark:bg-gray-800
              border border-gray-200 dark:border-gray-700
              selected:bg-white dark:selected:bg-gray-900
              selected:border-primary-200 dark:selected:border-primary-800
            ''',
            child: WText(o.flag, className: 'text-xl'),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WDiv(
                className: 'flex flex-row items-center gap-2 min-w-0',
                children: [
                  WDiv(
                    className: 'flex-1 min-w-0',
                    child: WText(
                      o.city,
                      className: '''
                        text-sm font-semibold
                        text-gray-900 dark:text-white truncate
                      ''',
                    ),
                  ),
                  WDiv(
                    states: isOn ? {'selected'} : {},
                    className: '''
                      shrink-0 px-1.5 py-0.5 rounded-md
                      bg-gray-100 dark:bg-gray-800
                      selected:bg-primary-100 dark:selected:bg-primary-900/40
                    ''',
                    child: WText(
                      o.code,
                      states: isOn ? {'selected'} : {},
                      className: '''
                        text-[10px] font-mono font-semibold
                        text-gray-500 dark:text-gray-400
                        selected:text-primary-700 dark:selected:text-primary-300
                      ''',
                    ),
                  ),
                ],
              ),
              WText(
                o.country,
                className: '''
                  text-xs text-gray-500 dark:text-gray-400 truncate
                ''',
              ),
            ],
          ),
          _indicator(isOn),
        ],
      ),
    );
  }

  Widget _indicator(bool isOn) {
    return WDiv(
      states: isOn ? {'selected'} : {},
      className: '''
        w-5 h-5 rounded-full
        flex items-center justify-center
        border-2 border-gray-300 dark:border-gray-600
        bg-white dark:bg-gray-800
        selected:bg-primary-500 dark:selected:bg-primary-400
        selected:border-primary-500 dark:selected:border-primary-400
      ''',
      child: isOn
          ? WIcon(
              Icons.check_rounded,
              className: 'text-[12px] text-white dark:text-gray-900',
            )
          : const WSpacer(),
    );
  }
}
