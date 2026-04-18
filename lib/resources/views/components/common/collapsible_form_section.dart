import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Collapsible form section card.
///
/// Same chrome as [FormSectionCard] but with a toggle row that expands/
/// collapses the body. Starts collapsed by default; used to hide advanced
/// options that most users will leave untouched.
class CollapsibleFormSection extends StatefulWidget {
  const CollapsibleFormSection({
    super.key,
    required this.titleKey,
    required this.icon,
    required this.child,
    this.subtitleKey,
    this.initiallyOpen = false,
  });

  final String titleKey;
  final String? subtitleKey;
  final IconData icon;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<CollapsibleFormSection> createState() => _CollapsibleFormSectionState();
}

class _CollapsibleFormSectionState extends State<CollapsibleFormSection> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WButton(
          onTap: () => setState(() => _open = !_open),
          states: _open ? {'open'} : {},
          className: '''
            w-full flex flex-row items-start gap-3
            px-4 py-3
            open:border-b open:border-gray-100 dark:open:border-gray-800
            hover:bg-gray-50 dark:hover:bg-gray-800/60
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-3 w-full',
            children: [
              WDiv(
                className: '''
                  w-8 h-8 rounded-lg
                  bg-primary-50 dark:bg-primary-900/30
                  flex items-center justify-center
                ''',
                child: WIcon(
                  widget.icon,
                  className: '''
                    text-sm text-primary-600 dark:text-primary-400
                  ''',
                ),
              ),
              WDiv(
                className: 'flex-1 flex flex-col gap-0.5 min-w-0',
                children: [
                  WText(
                    trans(widget.titleKey),
                    className: '''
                      text-sm font-bold
                      text-gray-900 dark:text-white
                    ''',
                  ),
                  if (widget.subtitleKey != null)
                    WText(
                      trans(widget.subtitleKey!),
                      className: '''
                        text-xs
                        text-gray-500 dark:text-gray-400
                      ''',
                    ),
                ],
              ),
              WIcon(
                _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                className: 'text-base text-gray-500 dark:text-gray-400',
              ),
            ],
          ),
        ),
        if (_open) WDiv(className: 'p-4', child: widget.child),
      ],
    );
  }
}
