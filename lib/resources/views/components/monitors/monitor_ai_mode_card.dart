import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/ai_mode.dart';
import '../ai/ai_mode_selector.dart';

/// Per-monitor AI autonomy card.
///
/// Shows the workspace default as a hint, plus an Override toggle. When the
/// toggle is off the monitor inherits `workspaceDefault`; when on, the
/// selector becomes active and the chosen mode sticks.
class MonitorAiModeCard extends StatefulWidget {
  const MonitorAiModeCard({
    super.key,
    required this.workspaceDefault,
    this.initialOverride,
  });

  final AiMode workspaceDefault;
  final AiMode? initialOverride;

  @override
  State<MonitorAiModeCard> createState() => _MonitorAiModeCardState();
}

class _MonitorAiModeCardState extends State<MonitorAiModeCard> {
  late bool _override = widget.initialOverride != null;
  late AiMode _mode = widget.initialOverride ?? widget.workspaceDefault;

  @override
  Widget build(BuildContext context) {
    final effective = _override ? _mode : widget.workspaceDefault;
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        _header(effective),
        WDiv(
          className: 'p-4 flex flex-col gap-3',
          children: [
            _inheritRow(),
            if (_override) ...[
              AiModeSelector(
                selected: _mode,
                onChanged: (v) => setState(() => _mode = v),
              ),
              WText(
                trans(_mode.descriptionKey),
                className: '''
                  text-xs leading-relaxed
                  text-gray-600 dark:text-gray-300
                ''',
              ),
            ] else
              WDiv(
                className: '''
                  rounded-lg p-3
                  bg-gray-50 dark:bg-gray-900
                  border border-gray-200 dark:border-gray-700
                  flex flex-row items-start gap-2
                ''',
                children: [
                  WIcon(
                    Icons.link_rounded,
                    className: 'text-sm text-gray-500 dark:text-gray-400',
                  ),
                  WDiv(
                    className: 'flex-1 flex flex-col gap-0.5',
                    children: [
                      WText(
                        trans('monitor.ai.inherit_line', {
                          'mode': trans(widget.workspaceDefault.labelKey),
                        }),
                        className: '''
                          text-xs font-semibold
                          text-gray-700 dark:text-gray-200
                        ''',
                      ),
                      WText(
                        trans(widget.workspaceDefault.descriptionKey),
                        className: '''
                          text-xs
                          text-gray-500 dark:text-gray-400
                        ''',
                      ),
                    ],
                  ),
                  WButton(
                    onTap: () => MagicRoute.to('/settings/ai'),
                    className: '''
                      px-2 py-1 rounded-md
                      hover:bg-gray-100 dark:hover:bg-gray-800
                    ''',
                    child: WText(
                      trans('monitor.ai.open_settings'),
                      className: '''
                        text-xs font-semibold
                        text-primary-600 dark:text-primary-300
                      ''',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _header(AiMode effective) {
    return WDiv(
      states: {effective.name},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-center gap-3
      ''',
      children: [
        WDiv(
          states: {effective.name},
          className: '''
            w-9 h-9 rounded-lg
            flex items-center justify-center
            bg-gray-100 dark:bg-gray-900
            suggest:bg-ai-50 dark:suggest:bg-ai-900/30
            auto:bg-ai-100 dark:auto:bg-ai-900/40
          ''',
          child: WIcon(
            _iconFor(effective),
            states: {effective.name},
            className: '''
              text-base
              text-gray-500 dark:text-gray-400
              suggest:text-ai-600 dark:suggest:text-ai-300
              auto:text-ai-700 dark:auto:text-ai-200
            ''',
          ),
        ),
        WDiv(
          className: 'flex-1 flex flex-col gap-0.5 min-w-0',
          children: [
            WText(
              trans('monitor.ai.title'),
              className: '''
                text-sm font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('monitor.ai.subtitle'),
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
        WDiv(
          states: {effective.name},
          className: '''
            px-2 py-1 rounded-full
            bg-gray-100 dark:bg-gray-900
            suggest:bg-ai-50 dark:suggest:bg-ai-900/30
            auto:bg-ai-100 dark:auto:bg-ai-900/40
          ''',
          child: WText(
            trans(effective.labelKey),
            states: {effective.name},
            className: '''
              text-[10px] font-bold uppercase tracking-wide
              text-gray-600 dark:text-gray-300
              suggest:text-ai-700 dark:suggest:text-ai-300
              auto:text-ai-800 dark:auto:text-ai-200
            ''',
          ),
        ),
      ],
    );
  }

  IconData _iconFor(AiMode m) {
    return switch (m) {
      AiMode.off => Icons.toggle_off_outlined,
      AiMode.suggest => Icons.lightbulb_outline_rounded,
      AiMode.auto => Icons.auto_awesome_rounded,
    };
  }

  Widget _inheritRow() {
    return WButton(
      onTap: () => setState(() => _override = !_override),
      states: _override ? {'on'} : {},
      className: '''
        w-full p-3 rounded-lg
        flex flex-row items-center gap-3
        bg-gray-50 dark:bg-gray-900/40
        border border-gray-200 dark:border-gray-700
        hover:border-gray-300 dark:hover:border-gray-600
        on:bg-primary-50 dark:on:bg-primary-900/20
        on:border-primary-200 dark:on:border-primary-800
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                trans('monitor.ai.override_title'),
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                ''',
              ),
              WText(
                trans('monitor.ai.override_subtitle'),
                className: '''
                  text-xs
                  text-gray-500 dark:text-gray-400
                ''',
              ),
            ],
          ),
          WDiv(
            states: _override ? {'on'} : {},
            className: '''
              w-10 h-6 rounded-full p-0.5
              bg-gray-300 dark:bg-gray-600
              on:bg-primary-500 dark:on:bg-primary-400
              flex flex-row items-center
              on:justify-end
            ''',
            child: WDiv(className: 'w-5 h-5 rounded-full bg-white dark:bg-white'),
          ),
        ],
      ),
    );
  }
}
