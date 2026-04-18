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

/// Read-only audit log of every AI agent run.
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
          _row(runs[i], isLast: i == runs.length - 1),
      ],
    );
  }

  Widget _row(AiAgentRun run, {required bool isLast}) {
    return WDiv(
      states: isLast ? {'last'} : {},
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-900/60
        last:border-b-0 last:border-transparent
        flex flex-row items-center gap-3
      ''',
      children: [
        _statusDot(run.status),
        WDiv(
          className: 'flex-1 flex flex-col gap-0.5 min-w-0',
          children: [
            WText(
              run.agentName,
              className: '''
                text-sm font-semibold
                text-gray-900 dark:text-white
                truncate
              ''',
            ),
            WText(
              '${run.provider ?? '-'} · ${run.model ?? '-'}',
              className: '''
                text-xs font-mono
                text-gray-500 dark:text-gray-400
                truncate
              ''',
            ),
          ],
        ),
        _metric('${run.durationMs ?? 0}ms'),
        _metric(
          run.costUsd == null ? '-' : '\$${run.costUsd!.toStringAsFixed(4)}',
        ),
      ],
    );
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
