import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Secondary/neutral action button paired with [PrimaryButton].
///
/// Uses [MagicStarter.modalTheme.secondaryButtonClassName] so cancel/neutral
/// actions share the starter visual language.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
            WIcon(icon!, className: 'text-sm text-gray-700 dark:text-gray-200'),
          WText(trans(labelKey)),
        ],
      ),
    );
  }
}
