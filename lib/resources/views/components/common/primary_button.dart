import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Primary call-to-action button with optional leading icon.
///
/// When [isLoading] is true, the icon slot swaps to a 16px spinner and
/// [onTap] is ignored. When [isDisabled] is true, [onTap] is ignored but no
/// spinner is shown. [onTap] may be null to render an inert button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
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
          '${MagicStarter.modalTheme.primaryButtonClassName} disabled:opacity-60',
      child: WDiv(
        className: 'flex flex-row items-center justify-center gap-2',
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (icon != null)
            WIcon(icon!, className: 'text-sm text-white'),
          WText(trans(labelKey)),
        ],
      ),
    );
  }
}
