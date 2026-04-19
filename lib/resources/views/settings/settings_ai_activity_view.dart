import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/ai/ai_agent_run_controller.dart';
import '../../../app/models/ai_agent_run.dart';
import '../components/common/app_back_button.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';

/// Read-only audit log of every AI agent run. Rows expand to reveal the
/// structured output summary, the input prompt, and the raw response so
/// operators can debug prompts without leaving the app.
class SettingsAiActivityView extends StatefulWidget {
  const SettingsAiActivityView({super.key});

  @override
  State<SettingsAiActivityView> createState() => _SettingsAiActivityViewState();
}

class _SettingsAiActivityViewState extends State<SettingsAiActivityView> {
  AiAgentRunController get _c => AiAgentRunController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.load());
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) => MagicStarterPageHeader(
            leading: const AppBackButton(fallbackPath: '/settings/ai'),
            title: trans('ai.activity.title'),
            subtitle: trans('ai.activity.subtitle'),
            inlineActions: true,
            actions: [
              RefreshIconButton(
                onTap: _c.load,
                isRefreshing: _c.rxStatus.isLoading,
              ),
            ],
          ),
        ),
        RefreshIndicator(
          onRefresh: _c.load,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              if (_c.rxStatus.isError && _c.runs.isEmpty) {
                return ErrorBanner(
                  message: _c.rxStatus.message,
                  onRetry: _c.load,
                );
              }
              if (_c.rxStatus.isLoading && _c.runs.isEmpty) {
                return const SkeletonRowList();
              }
              if (_c.runs.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_rounded,
                  titleKey: 'ai.activity.empty_title',
                  subtitleKey: 'ai.activity.empty_subtitle',
                );
              }
              return _table(_c.runs);
            },
          ),
        ),
      ],
    );
  }

  Widget _table(List<AiAgentRun> runs) {
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        for (var i = 0; i < runs.length; i++)
          _ExpandableRow(
            key: ValueKey(runs[i].id),
            run: runs[i],
            isLast: i == runs.length - 1,
          ),
      ],
    );
  }
}

/// Single activity row + collapsible inspector. Keyed by `run.id` so
/// expansion state survives list reshuffles after a refresh.
class _ExpandableRow extends StatefulWidget {
  const _ExpandableRow({super.key, required this.run, required this.isLast});

  final AiAgentRun run;
  final bool isLast;

  @override
  State<_ExpandableRow> createState() => _ExpandableRowState();
}

class _ExpandableRowState extends State<_ExpandableRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        flex flex-col
      ''',
      children: [_summaryRow(), if (_open) _details()],
    );
  }

  Widget _summaryRow() {
    return WButton(
      onTap: () => setState(() => _open = !_open),
      className: '''
        w-full px-4 py-3
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          _statusDot(widget.run.status),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                widget.run.agentName,
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                  truncate
                ''',
              ),
              WText(
                '${widget.run.provider ?? '-'} · ${widget.run.model ?? '-'}',
                className: '''
                  text-xs font-mono
                  text-gray-500 dark:text-gray-400
                  truncate
                ''',
              ),
            ],
          ),
          _metric('${widget.run.durationMs ?? 0}ms'),
          _metric(
            widget.run.costUsd == null
                ? '-'
                : '\$${widget.run.costUsd!.toStringAsFixed(4)}',
          ),
          WIcon(
            _open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            className: 'text-base text-gray-500 dark:text-gray-400',
          ),
        ],
      ),
    );
  }

  Widget _details() {
    final run = widget.run;
    final structured = run.structuredOutput;
    final prompt = run.inputPrompt;
    final output = run.outputText;
    final nothingCaptured =
        (structured == null || structured.isEmpty) &&
        (prompt == null || prompt.isEmpty) &&
        (output == null || output.isEmpty);

    return WDiv(
      className: '''
        px-4 pb-4
        flex flex-col gap-3
        bg-gray-50/50 dark:bg-gray-900/40
      ''',
      children: [
        if (nothingCaptured)
          WText(
            trans('ai.activity.details.empty'),
            className: '''
              text-xs italic
              text-gray-500 dark:text-gray-400
            ''',
          )
        else ...[
          if (structured != null && structured.isNotEmpty)
            _detailBlock(
              titleKey: 'ai.activity.details.structured_output',
              body: _prettyJson(structured),
            ),
          if (prompt != null && prompt.isNotEmpty)
            _detailBlock(titleKey: 'ai.activity.details.prompt', body: prompt),
          if (output != null && output.isNotEmpty)
            _detailBlock(
              titleKey: 'ai.activity.details.response',
              body: output,
            ),
        ],
      ],
    );
  }

  Widget _detailBlock({required String titleKey, required String body}) {
    return WDiv(
      className: '''
        rounded-lg
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            px-3 py-2
            border-b border-gray-100 dark:border-gray-700
          ''',
          child: WText(
            trans(titleKey),
            className: '''
              text-[10px] font-bold uppercase tracking-wider
              text-gray-500 dark:text-gray-400
            ''',
          ),
        ),
        WDiv(
          className: '''
            p-3
            max-h-64 overflow-auto
          ''',
          child: WText(
            body,
            className: '''
              text-xs font-mono leading-relaxed
              text-gray-800 dark:text-gray-200
              whitespace-pre-wrap
            ''',
          ),
        ),
      ],
    );
  }

  String _prettyJson(Map<String, dynamic> map) {
    try {
      return const JsonEncoder.withIndent('  ').convert(map);
    } catch (_) {
      return map.toString();
    }
  }

  Widget _statusDot(String status) {
    final tone = switch (status) {
      'succeeded' => 'up',
      'failed' => 'down',
      _ => 'paused',
    };
    return WDiv(
      states: {tone},
      className: '''
        w-2 h-2 rounded-full
        up:bg-up-500 dark:up:bg-up-400
        down:bg-down-500 dark:down:bg-down-400
        paused:bg-paused-400 dark:paused:bg-paused-300
      ''',
    );
  }

  Widget _metric(String value) {
    return WText(
      value,
      className: '''
        text-xs font-mono
        text-gray-600 dark:text-gray-300
      ''',
    );
  }
}
