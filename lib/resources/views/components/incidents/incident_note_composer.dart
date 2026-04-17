import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Bottom-sheet note composer for an incident timeline.
///
/// Mock-only: accepts free-form text and optional status-change intent
/// (none / acknowledge / mitigated / resolved). Submits nothing; just toasts.
class IncidentNoteComposer extends StatefulWidget {
  const IncidentNoteComposer({
    super.key,
    required this.incidentTitle,
    this.onSubmit,
  });

  final String incidentTitle;
  final void Function(String text, String statusIntent)? onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String incidentTitle,
    void Function(String text, String statusIntent)? onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidentNoteComposer(
        incidentTitle: incidentTitle,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<IncidentNoteComposer> createState() => _IncidentNoteComposerState();
}

class _IncidentNoteComposerState extends State<IncidentNoteComposer> {
  final _controller = TextEditingController();
  String _intent = 'none';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _intents = [
    ('none', 'incident.note.intent.none', Icons.chat_bubble_outline_rounded),
    ('acknowledge', 'incident.note.intent.acknowledge', Icons.visibility_rounded),
    ('mitigated', 'incident.note.intent.mitigated', Icons.health_and_safety_outlined),
    ('resolved', 'incident.note.intent.resolved', Icons.check_circle_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return WDiv(
          className: '''
            rounded-t-2xl
            bg-white dark:bg-gray-900
            border-t border-gray-200 dark:border-gray-700
            flex flex-col
          ''',
          children: [
            _grabber(),
            _header(),
            WDiv(
              className: 'flex-1 overflow-y-auto',
              scrollPrimary: true,
              children: [
                WDiv(
                  className: 'p-4 flex flex-col gap-4',
                  children: [
                    _intentRow(),
                    _textField(),
                    _hint(),
                  ],
                ),
              ],
            ),
            _footer(),
          ],
        );
      },
    );
  }

  Widget _grabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: 'w-10 h-1 rounded-full bg-gray-300 dark:bg-gray-600',
      ),
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 pb-4
        border-b border-gray-100 dark:border-gray-800
        flex flex-col gap-1
      ''',
      children: [
        WText(
          trans('incident.note.title'),
          className: '''
            text-lg font-bold
            text-gray-900 dark:text-white
          ''',
        ),
        WText(
          widget.incidentTitle,
          className: '''
            text-xs
            text-gray-500 dark:text-gray-400 truncate
          ''',
        ),
      ],
    );
  }

  Widget _intentRow() {
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        WText(
          trans('incident.note.intent_label'),
          className: '''
            text-xs font-bold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WDiv(
          className: '''
            flex flex-row gap-1 p-1 rounded-lg
            bg-gray-100 dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
          ''',
          children: [
            for (final i in _intents) _intentPill(i.$1, i.$2, i.$3),
          ],
        ),
      ],
    );
  }

  Widget _intentPill(String value, String labelKey, IconData icon) {
    final isActive = _intent == value;
    return WDiv(
      className: 'flex-1',
      child: WButton(
        onTap: () => setState(() => _intent = value),
        states: isActive ? {'active'} : {},
        className: '''
          w-full px-2 py-2 rounded-md
          hover:bg-gray-200/60 dark:hover:bg-gray-700/60
          active:bg-white dark:active:bg-gray-800
          active:shadow-sm
          flex flex-row items-center justify-center gap-1.5
        ''',
        child: WDiv(
          className: 'flex flex-row items-center gap-1.5',
          children: [
            WIcon(
              icon,
              states: isActive ? {'active'} : {},
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400
                active:text-primary-600 dark:active:text-primary-300
              ''',
            ),
            WText(
              trans(labelKey),
              states: isActive ? {'active'} : {},
              className: '''
                text-xs font-semibold
                text-gray-600 dark:text-gray-300
                active:text-gray-900 dark:active:text-white
              ''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField() {
    return WDiv(
      className: 'flex flex-col gap-1.5',
      children: [
        WText(
          trans('incident.note.message_label'),
          className: '''
            text-xs font-bold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WDiv(
          className: '''
            rounded-lg
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
          ''',
          child: TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: trans('incident.note.placeholder'),
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _hint() {
    return WDiv(
      className: '''
        rounded-lg p-3
        bg-ai-50/60 dark:bg-ai-900/20
        border border-ai-200/60 dark:border-ai-800/40
        flex flex-row items-start gap-2
      ''',
      children: [
        WIcon(
          Icons.auto_awesome_rounded,
          className: 'text-sm text-ai-600 dark:text-ai-300',
        ),
        WDiv(
          className: 'flex-1',
          child: WText(
            trans('incident.note.ai_hint'),
            className: '''
              text-xs leading-relaxed
              text-gray-700 dark:text-gray-200
            ''',
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return WDiv(
      className: '''
        w-full px-4 py-3
        border-t border-gray-200 dark:border-gray-800
        flex flex-row items-center justify-end gap-2
      ''',
      children: [
        WButton(
          onTap: () => MagicRoute.back(),
          className: '''
            px-4 py-2.5 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            flex flex-row items-center justify-center
          ''',
          child: WText(
            trans('common.cancel'),
            className: '''
              text-sm font-semibold
              text-gray-700 dark:text-gray-200
            ''',
          ),
        ),
        WButton(
          onTap: _submit,
          className: '''
            px-4 py-2.5 rounded-lg
            bg-primary-600 dark:bg-primary-500
            hover:bg-primary-700 dark:hover:bg-primary-400
            flex flex-row items-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.send_rounded,
                className: 'text-sm text-white',
              ),
              WText(
                trans('incident.note.submit'),
                className: 'text-sm font-semibold text-white',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Magic.toast(trans('incident.note.empty_toast'));
      return;
    }
    widget.onSubmit?.call(text, _intent);
    MagicRoute.back();
    Magic.toast(trans('incident.note.saved_toast'));
  }
}
