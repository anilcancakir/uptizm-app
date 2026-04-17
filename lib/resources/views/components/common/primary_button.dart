import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Primary call-to-action button with optional leading icon.
///
/// Uses [MagicStarter.modalTheme.primaryButtonClassName] so every page shares
/// the same action button visuals as the starter dialogs.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
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
      className: MagicStarter.modalTheme.primaryButtonClassName,
      child: WDiv(
        className: 'flex flex-row items-center justify-center gap-2',
        children: [
          if (icon != null) WIcon(icon!, className: 'text-sm text-white'),
          WText(trans(labelKey)),
        ],
      ),
    );
  }
}
