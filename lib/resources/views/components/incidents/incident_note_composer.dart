import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/controllers/incidents/incident_controller.dart';

/// Bottom-sheet "Post an update" composer for an incident.
///
/// Every submission writes a public incident update: a status transition
/// (or "Note only" to keep the current status) plus a body that flows
/// to subscribers and the status page. Opened from the drawer footer
/// (Acknowledge / Resolve preselect the matching intent) or the inline
/// "Add note" action (opens with intent=none).
///
/// The optional AI draft button calls the Haiku-powered drafter agent
/// and replaces the textarea with a status-page-voice draft. The user
/// can undo the replacement in one tap; the badge clears as soon as
/// the textarea is edited.
class IncidentNoteComposer extends StatefulWidget {
  const IncidentNoteComposer({
    super.key,
    required this.incidentId,
    required this.incidentTitle,
    this.initialIntent = 'none',
    this.onSubmit,
  });

  final String incidentId;
  final String incidentTitle;
  final String initialIntent;
  final void Function(String text, String statusIntent)? onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String incidentId,
    required String incidentTitle,
    String initialIntent = 'none',
    void Function(String text, String statusIntent)? onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidentNoteComposer(
        incidentId: incidentId,
        incidentTitle: incidentTitle,
        initialIntent: initialIntent,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<IncidentNoteComposer> createState() => _IncidentNoteComposerState();
}

class _IncidentNoteComposerState extends State<IncidentNoteComposer> {
  static const int _maxChars = 2000;
  final _controller = TextEditingController();
  late String _intent;
  bool _drafting = false;
  String? _preAiDraft;
  bool _showUndo = false;

  @override
  void initState() {
    super.initState();
    _intent = _intents.any((i) => i.$1 == widget.initialIntent)
        ? widget.initialIntent
        : 'none';
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  /// The "Drafted with AI" badge only holds until the operator starts
  /// editing the draft. We clear it as soon as the text diverges from
  /// the AI-produced body so the label never misrepresents authorship.
  String? _aiBodySnapshot;
  void _onControllerChange() {
    if (_showUndo &&
        _aiBodySnapshot != null &&
        _controller.text != _aiBodySnapshot) {
      setState(() {
        _showUndo = false;
      });
    }
  }

  Future<void> _requestAiDraft() async {
    if (_drafting) return;
    setState(() {
      _drafting = true;
    });
    final snapshot = _controller.text;
    final draft = await IncidentController.instance.draftUpdate(
      id: widget.incidentId,
      intent: _intent,
      userDraft: snapshot,
    );
    if (!mounted) return;
    setState(() {
      _drafting = false;
      if (draft != null && draft.isNotEmpty) {
        _preAiDraft = snapshot;
        _aiBodySnapshot = draft;
        _controller.text = draft;
        _showUndo = true;
      }
    });
  }

  void _undoAiDraft() {
    if (_preAiDraft == null) return;
    setState(() {
      _controller.text = _preAiDraft ?? '';
      _preAiDraft = null;
      _aiBodySnapshot = null;
      _showUndo = false;
    });
  }

  static const _intents = [
    ('none', 'incident.update.intent.none', Icons.chat_bubble_outline_rounded),
    (
      'investigating',
      'incident.update.intent.investigating',
      Icons.search_rounded,
    ),
    ('identified', 'incident.update.intent.identified', Icons.flag_outlined),
    (
      'monitoring',
      'incident.update.intent.monitoring',
      Icons.visibility_rounded,
    ),
    (
      'resolved',
      'incident.update.intent.resolved',
      Icons.check_circle_outline_rounded,
    ),
  ];

  bool get _isNoteOnly => _intent == 'none';
  bool get _isResolve => _intent == 'resolved';

  String get _placeholderKey {
    if (_isNoteOnly) return 'incident.update.placeholder_note_only';
    if (_isResolve) return 'incident.update.placeholder_resolved';
    return 'incident.update.placeholder';
  }

  String get _subtitle {
    if (_isNoteOnly) return trans('incident.update.subtitle_note_only');
    return trans('incident.update.subtitle_status', {
      'status': trans('incident.update.status_name.$_intent'),
    });
  }

  String get _submitLabel => _isResolve
      ? trans('incident.update.submit_resolve')
      : trans('incident.update.submit');

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, _) {
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
                  className: 'px-4 py-4 flex flex-col gap-4',
                  children: [_intentRow(), _textField()],
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
          trans('incident.update.title'),
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
        WText(
          _subtitle,
          className: '''
            text-xs leading-relaxed
            text-gray-600 dark:text-gray-300
            mt-1
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
          trans('incident.update.status_label'),
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
          children: [for (final i in _intents) _intentPill(i.$1, i.$2, i.$3)],
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
      className: 'flex flex-col gap-2',
      children: [
        WDiv(
          className: '''
            flex flex-row items-center justify-between gap-2
          ''',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                WText(
                  trans('incident.update.message_label'),
                  className: '''
                    text-xs font-bold uppercase tracking-wide
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
                _aiControl(),
              ],
            ),
            ListenableBuilder(
              listenable: _controller,
              builder: (_, _) {
                final len = _controller.text.trim().length;
                return WText(
                  '$len / $_maxChars',
                  className: '''
                    text-[10px] font-mono
                    text-gray-400 dark:text-gray-500
                  ''',
                );
              },
            ),
          ],
        ),
        WInput(
          controller: _controller,
          type: InputType.multiline,
          minLines: 5,
          maxLines: 10,
          placeholder: trans(_placeholderKey),
          placeholderClassName: '''
            text-sm leading-relaxed
            text-gray-400 dark:text-gray-500
          ''',
          className: '''
            rounded-xl py-3 text-sm leading-relaxed font-sans
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
            text-gray-900 dark:text-gray-100
          ''',
        ),
      ],
    );
  }

  /// AI draft control — three states:
  /// - idle (default): compact pill that invokes the drafter agent.
  /// - drafting: spinner + disabled pill.
  /// - drafted (post-replacement): "Drafted with AI" badge + Undo link
  ///   that restores the operator's original text. Clears once the
  ///   textarea is edited past the AI body.
  Widget _aiControl() {
    if (_drafting) {
      return WDiv(
        className: '''
          px-2.5 py-1 rounded-md
          bg-ai-50 dark:bg-ai-900/30
          border border-ai-200/60 dark:border-ai-800/40
          flex flex-row items-center gap-1.5
        ''',
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          WText(
            trans('incident.update.ai_drafting'),
            className: '''
              text-[11px] font-semibold
              text-ai-700 dark:text-ai-200
            ''',
          ),
        ],
      );
    }

    if (_showUndo) {
      return WDiv(
        className: 'flex flex-row items-center gap-1.5',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-1',
            children: [
              WIcon(
                Icons.auto_awesome_rounded,
                className: 'text-[11px] text-ai-600 dark:text-ai-300',
              ),
              WText(
                trans('incident.update.ai_draft_badge'),
                className: '''
                  text-[11px] font-semibold
                  text-ai-700 dark:text-ai-200
                ''',
              ),
            ],
          ),
          WText('·', className: 'text-[11px] text-gray-400 dark:text-gray-500'),
          WButton(
            onTap: _undoAiDraft,
            className: 'px-1 py-0.5 rounded',
            child: WText(
              trans('incident.update.ai_undo'),
              className: '''
                text-[11px] font-semibold
                text-primary-600 dark:text-primary-300
                hover:underline
              ''',
            ),
          ),
        ],
      );
    }

    return WButton(
      onTap: _requestAiDraft,
      className: '''
        px-2.5 py-1 rounded-md
        bg-ai-50 dark:bg-ai-900/30
        hover:bg-ai-100 dark:hover:bg-ai-900/40
        border border-ai-200/60 dark:border-ai-800/40
        flex flex-row items-center gap-1.5
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-1.5',
        children: [
          WIcon(
            Icons.auto_awesome_rounded,
            className: 'text-[11px] text-ai-600 dark:text-ai-300',
          ),
          WText(
            trans('incident.update.ai_draft'),
            className: '''
              text-[11px] font-semibold
              text-ai-700 dark:text-ai-200
            ''',
          ),
        ],
      ),
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
              WIcon(Icons.send_rounded, className: 'text-sm text-white'),
              WText(
                _submitLabel,
                className: 'text-sm font-semibold text-white',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_drafting) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Magic.toast(trans('incident.update.empty_toast'));
      return;
    }
    widget.onSubmit?.call(text, _intent);
    MagicRoute.back();
    Magic.toast(trans('incident.update.saved_toast'));
  }
}
