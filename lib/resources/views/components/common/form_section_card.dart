import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Section wrapper used on form pages.
///
/// Renders a bordered card with a titled header row and a content slot.
/// Keeps form layouts uniform without re-declaring the container chrome.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.titleKey,
    required this.icon,
    required this.child,
    this.subtitleKey,
  });

  final String titleKey;
  final String? subtitleKey;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            flex flex-row items-start gap-3
            px-4 py-3
            border-b border-gray-100 dark:border-gray-800
          ''',
          children: [
            WDiv(
              className: '''
                w-8 h-8 rounded-lg
                bg-primary-50 dark:bg-primary-900/30
                flex items-center justify-center
              ''',
              child: WIcon(
                icon,
                className: 'text-sm text-primary-600 dark:text-primary-400',
              ),
            ),
            WDiv(
              className: 'flex-1 flex flex-col gap-0.5',
              children: [
                WText(
                  trans(titleKey),
                  className: '''
                    text-sm font-bold
                    text-gray-900 dark:text-white
                  ''',
                ),
                if (subtitleKey != null)
                  WText(
                    trans(subtitleKey!),
                    className: '''
                      text-xs
                      text-gray-500 dark:text-gray-400
                    ''',
                  ),
              ],
            ),
          ],
        ),
        WDiv(
          className: 'p-4',
          child: child,
        ),
      ],
    );
  }
}
