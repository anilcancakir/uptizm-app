import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Inline error panel used when a controller's load() fails.
///
/// Renders a red-tinted banner with an optional retry button. [messageKey]
/// is an i18n key; if null, the generic copy is used.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, this.messageKey, this.message, this.onRetry});

  final String? messageKey;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final resolved = message ?? trans(messageKey ?? 'errors.generic_load');
    return WDiv(
      className: '''
        rounded-xl p-4
        bg-down-50 dark:bg-down-900/30
        border border-down-200 dark:border-down-800
        flex flex-row items-center gap-3
      ''',
      children: [
        WDiv(
          className: '''
            w-9 h-9 rounded-lg
            bg-down-100 dark:bg-down-900/50
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.error_outline_rounded,
            className: 'text-base text-down-600 dark:text-down-300',
          ),
        ),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            resolved,
            className: '''
              text-sm
              text-down-700 dark:text-down-200
            ''',
          ),
        ),
        if (onRetry != null)
          WButton(
            onTap: onRetry!,
            className: '''
              px-3 py-1.5 rounded-lg
              bg-white dark:bg-gray-900
              border border-down-200 dark:border-down-800
              hover:bg-down-50 dark:hover:bg-down-900/50
              flex flex-row items-center gap-1.5
            ''',
            child: WDiv(
              className: 'flex flex-row items-center gap-1.5',
              children: [
                WIcon(
                  Icons.refresh_rounded,
                  className: 'text-sm text-down-600 dark:text-down-300',
                ),
                WText(
                  trans('common.retry'),
                  className: '''
                    text-xs font-semibold
                    text-down-700 dark:text-down-200
                  ''',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
