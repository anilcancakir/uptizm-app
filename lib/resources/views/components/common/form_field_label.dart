import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Compact label + optional hint row used above form controls.
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel({
    super.key,
    required this.labelKey,
    this.hintKey,
    this.required = false,
  });

  final String labelKey;
  final String? hintKey;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-0.5 mb-2',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-1',
          children: [
            WText(
              trans(labelKey),
              className: '''
                text-xs font-bold uppercase tracking-wide
                text-gray-700 dark:text-gray-200
              ''',
            ),
            if (required)
              WText(
                '*',
                className: '''
                  text-xs font-bold
                  text-down-500 dark:text-down-400
                ''',
              ),
          ],
        ),
        if (hintKey != null)
          WText(
            trans(hintKey!),
            className: '''
              text-xs
              text-gray-500 dark:text-gray-400
            ''',
          ),
      ],
    );
  }
}
