import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Row presenting a boolean setting: icon + title + subtitle + trailing switch.
///
/// Tapping anywhere on the row toggles the value.
class SettingToggleRow extends StatelessWidget {
  const SettingToggleRow({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: () => onChanged(!value),
      states: value ? {'on'} : {},
      className: '''
        w-full p-3 rounded-lg
        flex flex-row items-center gap-3
        bg-gray-50 dark:bg-gray-900/40
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        on:bg-primary-50 dark:on:bg-primary-900/20
        on:border-primary-200 dark:on:border-primary-800
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: value ? {'on'} : {},
            className: '''
              w-8 h-8 rounded-lg
              flex items-center justify-center
              bg-white dark:bg-gray-800
              on:bg-primary-500 dark:on:bg-primary-400
            ''',
            child: WIcon(
              icon,
              states: value ? {'on'} : {},
              className: '''
                text-sm
                text-gray-500 dark:text-gray-400
                on:text-white dark:on:text-gray-900
              ''',
            ),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5',
            children: [
              WText(
                trans(titleKey),
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                ''',
              ),
              WText(
                trans(subtitleKey),
                className: '''
                  text-xs
                  text-gray-500 dark:text-gray-400
                ''',
              ),
            ],
          ),
          _switch(),
        ],
      ),
    );
  }

  Widget _switch() {
    return WDiv(
      states: value ? {'on'} : {},
      className: '''
        w-10 h-6 rounded-full p-0.5
        bg-gray-300 dark:bg-gray-600
        on:bg-primary-500 dark:on:bg-primary-400
        flex flex-row items-center
        on:justify-end
      ''',
      child: WDiv(
        className: '''
          w-5 h-5 rounded-full
          bg-white dark:bg-white
        ''',
      ),
    );
  }
}
