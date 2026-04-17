import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Destructive action button that shares [SecondaryButton] dimensions so
/// Cancel / Delete / Save footers keep a uniform height and padding.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.labelKey,
    required this.onTap,
    this.icon,
  });

  final String labelKey;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: onTap,
      className: MagicStarter.modalTheme.secondaryButtonClassName,
      child: WDiv(
        className: 'flex flex-row items-center justify-center gap-2',
        children: [
          if (icon != null)
            WIcon(
              icon!,
              className: 'text-sm text-red-600 dark:text-red-400',
            ),
          WText(
            trans(labelKey),
            className: 'text-red-600 dark:text-red-400 font-semibold',
          ),
        ],
      ),
    );
  }
}
