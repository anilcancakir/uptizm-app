import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/ai_mode.dart';
import '../../../../app/enums/ai_mode_source.dart';
import '../../../../app/models/monitor_ai_status.dart';
import '../ai/ai_mode_selector.dart';

/// Per-monitor AI autonomy card.
///
/// Shows the workspace default as a hint plus an Override toggle. When
/// [aiStatus] is present (served by the `MonitorResource.ai` sub-object)
/// the card also surfaces the effective mode badge, cooldown window,
/// latest run summary, and the current gate callout so the user can tell
/// at a glance whether AI is about to run and, if not, why.
class MonitorAiModeCard extends StatefulWidget {
  const MonitorAiModeCard({
    super.key,
    required this.workspaceDefault,
    this.initialOverride,
    this.aiStatus,
    this.incidentThreshold,
    this.onChanged,
  });

  final AiMode workspaceDefault;
  final AiMode? initialOverride;

  /// Backend-resolved AI pipeline state for this monitor. Optional so the
  /// card still renders the selector when the payload is missing (older
  /// monitor page caches or locally-constructed fixtures).
  final MonitorAiStatus? aiStatus;

  /// Consecutive-fail count required before AI evaluates the monitor. Used
  /// inside the `below_fail_threshold` callout so the user sees the real
  /// number. Defaults to 3 (the backend default) when omitted.
  final int? incidentThreshold;

  /// Fires whenever the effective mode changes (inherit → override on/off, or
  /// override value changes). `null` means "inherit workspace default". Kept
  /// optional so the component stays usable without persistence.
  final ValueChanged<AiMode?>? onChanged;

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
                onChanged: (v) {
                  setState(() => _mode = v);
                  widget.onChanged?.call(v);
                },
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
            ?_statusSection(),
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
      onTap: () {
        setState(() => _override = !_override);
        widget.onChanged?.call(_override ? _mode : null);
      },
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
            child: WDiv(
              className: 'w-5 h-5 rounded-full bg-white dark:bg-white',
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the backend-resolved status block (effective mode source,
  /// cooldown, last run summary, gate callout). Returns null when no
  /// `aiStatus` is attached so the card stays compact.
  Widget? _statusSection() {
    final status = widget.aiStatus;
    if (status == null) return null;

    return WDiv(
      className: '''
        rounded-lg p-3
        bg-gray-50 dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-3
      ''',
      children: [
        _statusMetaRow(status),
        ?_lastRunRow(status),
        _gateCallout(status),
      ],
    );
  }

  Widget _statusMetaRow(MonitorAiStatus status) {
    final minutes = (status.cooldownSeconds / 60).ceil();
    final cooldownLabel = status.cooldownSeconds < 60
        ? trans('monitor.ai.status.cooldown_seconds', {
            'seconds': '${status.cooldownSeconds}',
          })
        : trans('monitor.ai.status.cooldown_minutes', {'minutes': '$minutes'});
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
        flex-wrap
      ''',
      children: [
        _metaChip(
          icon: Icons.tune_rounded,
          label: trans('monitor.ai.status.effective_label'),
          value: trans(status.effectiveMode?.labelKey ?? AiMode.off.labelKey),
          hint: trans(_modeSourceKey(status.modeSource)),
        ),
        _metaChip(
          icon: Icons.timer_outlined,
          label: trans('monitor.ai.status.cooldown_label'),
          value: cooldownLabel,
        ),
      ],
    );
  }

  String _modeSourceKey(AiModeSource source) {
    return switch (source) {
      AiModeSource.monitorOverride =>
        'monitor.ai.status.source.monitor_override',
      AiModeSource.workspaceDefault =>
        'monitor.ai.status.source.workspace_default',
      AiModeSource.none => 'monitor.ai.status.source.none',
    };
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required String value,
    String? hint,
  }) {
    return WDiv(
      className: 'flex flex-row items-center gap-2 min-w-0',
      children: [
        WIcon(icon, className: 'text-sm text-gray-500 dark:text-gray-400'),
        WDiv(
          className: 'flex flex-col min-w-0',
          children: [
            WText(
              label,
              className: '''
                text-[10px] font-semibold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
              ''',
            ),
            WText(
              value,
              className: '''
                text-xs font-semibold
                text-gray-900 dark:text-white
              ''',
            ),
            ?(hint == null
                ? null
                : WText(
                    hint,
                    className: '''
                      text-[10px]
                      text-gray-500 dark:text-gray-400
                    ''',
                  )),
          ],
        ),
      ],
    );
  }

  Widget? _lastRunRow(MonitorAiStatus status) {
    final run = status.lastRun;
    if (run == null) {
      return WText(
        trans('monitor.ai.status.last_run_none'),
        className: '''
          text-xs
          text-gray-500 dark:text-gray-400
        ''',
      );
    }

    final tokensIn = run.tokensInput ?? 0;
    final tokensOut = run.tokensOutput ?? 0;
    final cost = (run.costUsd ?? 0).toStringAsFixed(4);
    final duration = _formatDuration(run.durationMs);
    final meta = trans('monitor.ai.status.last_run_meta', {
      'tokens_in': '$tokensIn',
      'tokens_out': '$tokensOut',
      'cost': cost,
      'duration': duration,
    });
    final summaryLine = run.anomalyDetected == true
        ? trans('monitor.ai.status.last_run_anomaly', {
            'key': run.structuredMetricKey ?? '—',
          })
        : trans('monitor.ai.status.last_run_clean');

    final when = run.completedAt ?? run.startedAt;
    final relative = when == null
        ? null
        : Carbon.fromDateTime(when).diffForHumans();

    return WDiv(
      className: 'w-full flex flex-col gap-0.5',
      children: [
        WDiv(
          className: 'flex flex-row items-baseline gap-2',
          children: [
            WText(
              trans('monitor.ai.status.last_run_title'),
              className: '''
                text-[10px] font-semibold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
              ''',
            ),
            ?(relative == null
                ? null
                : WText(
                    trans('monitor.ai.status.last_run_when', {
                      'relative': relative,
                    }),
                    className: '''
                      text-[10px]
                      text-gray-500 dark:text-gray-400
                    ''',
                  )),
          ],
        ),
        WText(
          meta,
          className: '''
            text-xs
            text-gray-700 dark:text-gray-200
          ''',
        ),
        WText(
          summaryLine,
          className: '''
            text-xs font-semibold
            text-gray-900 dark:text-white
          ''',
        ),
      ],
    );
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '—';
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  Widget _gateCallout(MonitorAiStatus status) {
    final reason = status.currentGate.reason;
    final runnable = status.currentGate.run;
    final args = <String, dynamic>{
      'time': _formatTime(status.nextEligibleAt),
      'min': '${widget.incidentThreshold ?? 3}',
    };
    return WDiv(
      states: {runnable ? 'ok' : 'blocked'},
      className: '''
        rounded-lg p-3
        flex flex-row items-start gap-2
        bg-gray-100 dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        ok:bg-up-50 dark:ok:bg-up-900/20
        ok:border-up-200 dark:ok:border-up-800
        blocked:bg-ai-50 dark:blocked:bg-ai-900/20
        blocked:border-ai-200 dark:blocked:border-ai-800
      ''',
      children: [
        WIcon(
          runnable
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          states: {runnable ? 'ok' : 'blocked'},
          className: '''
            text-sm
            text-gray-500 dark:text-gray-400
            ok:text-up-600 dark:ok:text-up-300
            blocked:text-ai-600 dark:blocked:text-ai-300
          ''',
        ),
        WDiv(
          className: 'flex-1 flex flex-col gap-0.5 min-w-0',
          children: [
            WText(
              trans(reason.labelKey),
              states: {runnable ? 'ok' : 'blocked'},
              className: '''
                text-xs font-semibold
                text-gray-900 dark:text-white
                ok:text-up-800 dark:ok:text-up-200
                blocked:text-ai-800 dark:blocked:text-ai-200
              ''',
            ),
            WText(
              trans(reason.hintKey, args),
              className: '''
                text-xs leading-relaxed
                text-gray-600 dark:text-gray-300
              ''',
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime? at) {
    if (at == null) return '—';
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
