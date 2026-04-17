import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Icon button used as the [leading] widget on page headers.
///
/// Defaults to routing back to [fallbackPath] when no [onTap] is supplied,
/// which keeps deep-linked pages from popping to a blank screen.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onTap,
    this.fallbackPath = '/',
  });

  final VoidCallback? onTap;
  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: onTap ?? () => MagicRoute.to(fallbackPath),
      className: '''
        w-10 h-10 rounded-lg
        flex items-center justify-center
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:bg-gray-50 dark:hover:bg-gray-700
      ''',
      child: WIcon(
        Icons.arrow_back_rounded,
        className: 'text-lg text-gray-700 dark:text-gray-200',
      ),
    );
  }
}
