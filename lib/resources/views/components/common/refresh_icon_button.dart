import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Header-action refresh button. Shows an inline spinner while [isRefreshing]
/// is true and no-ops further taps to prevent double-fetches.
class RefreshIconButton extends StatelessWidget {
  const RefreshIconButton({
    super.key,
    required this.onTap,
    this.isRefreshing = false,
  });

  final VoidCallback onTap;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: trans('common.refresh'),
      child: WButton(
        onTap: isRefreshing ? () {} : onTap,
        states: isRefreshing ? {'busy'} : {},
        className: '''
          h-9 w-9 rounded-lg
          flex items-center justify-center
          border border-gray-200 dark:border-gray-700
          bg-white dark:bg-gray-800
          hover:bg-gray-50 dark:hover:bg-gray-700
          busy:opacity-60
        ''',
        child: isRefreshing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : WIcon(
                Icons.refresh_rounded,
                className: 'text-base text-gray-600 dark:text-gray-300',
              ),
      ),
    );
  }
}
