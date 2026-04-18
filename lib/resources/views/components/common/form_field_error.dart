import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Inline error row rendered directly under a form field.
///
/// Hidden when [message] is null/empty so it occupies no vertical space in
/// the happy path. Tone matches the `down-*` severity palette used by the
/// monitor forms.
class FormFieldError extends StatelessWidget {
  const FormFieldError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return WDiv(
      className: 'flex flex-row items-center gap-1 mt-1.5',
      children: [
        WIcon(
          Icons.error_outline_rounded,
          className: 'text-xs text-down-600 dark:text-down-400',
        ),
        WText(text, className: 'text-xs text-down-600 dark:text-down-400'),
      ],
    );
  }
}
