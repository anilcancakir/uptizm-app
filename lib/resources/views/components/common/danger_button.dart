import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Destructive action button matching [SecondaryButton] dimensions.
///
/// Supports the same [isLoading] + [isDisabled] contract as [PrimaryButton]
/// so confirm-then-act flows can pin feedback inline.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.labelKey,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String labelKey;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final blocked = isLoading || isDisabled || onTap == null;
    return WButton(
      onTap: blocked ? () {} : onTap!,
      states: blocked ? {'disabled'} : {},
      className:
          '${MagicStarter.modalTheme.secondaryButtonClassName} disabled:opacity-60',
      child: WDiv(
        className: 'flex flex-row items-center justify-center gap-2',
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
              ),
            )
          else if (icon != null)
            WIcon(icon!, className: 'text-sm text-red-600 dark:text-red-400'),
          WText(
            trans(labelKey),
            className: 'text-red-600 dark:text-red-400 font-semibold',
          ),
        ],
      ),
    );
  }
}
