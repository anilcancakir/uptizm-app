import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Single row inside an iOS-style grouped settings list.
///
/// Set [comingSoon] to disable navigation and show a muted pill on the right.
class SettingsListRow extends StatelessWidget {
  const SettingsListRow({
    super.key,
    required this.icon,
    required this.iconTone,
    required this.titleKey,
    required this.subtitleKey,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.comingSoon = false,
  });

  final IconData icon;

  /// Tailwind color key used for the icon tile bg, e.g. `'primary'`,
  /// `'up'`, `'degraded'`, `'paused'`, `'down'`.
  final String iconTone;
  final String titleKey;
  final String subtitleKey;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final radius = switch ((isFirst, isLast)) {
      (true, true) => 'rounded-xl',
      (true, false) => 'rounded-t-xl',
      (false, true) => 'rounded-b-xl',
      _ => '',
    };
    final separator = isLast
        ? ''
        : 'border-b border-gray-100 dark:border-gray-900/60';
    return WButton(
      onTap: () {
        if (comingSoon) {
          Magic.toast(trans('settings.coming_soon'));
          return;
        }
        onTap();
      },
      states: comingSoon ? {'soon'} : {},
      className:
          '''
        w-full px-4 py-3
        bg-white dark:bg-gray-800
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        soon:opacity-70
        flex flex-row items-center gap-3
        $radius $separator
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            className:
                '''
              w-9 h-9 rounded-lg
              bg-$iconTone-50 dark:bg-$iconTone-900/40
              flex items-center justify-center
            ''',
            child: WIcon(
              icon,
              className: 'text-base text-$iconTone-600 dark:text-$iconTone-300',
            ),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
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
          if (comingSoon)
            WDiv(
              className: '''
                px-2 py-0.5 rounded-full
                bg-gray-100 dark:bg-gray-900
                border border-gray-200 dark:border-gray-700
              ''',
              child: WText(
                trans('settings.coming_soon'),
                className: '''
                  text-[10px] font-semibold uppercase tracking-wide
                  text-gray-500 dark:text-gray-400
                ''',
              ),
            )
          else
            WIcon(
              Icons.chevron_right_rounded,
              className: 'text-lg text-gray-400 dark:text-gray-500',
            ),
        ],
      ),
    );
  }
}
