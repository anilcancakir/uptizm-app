import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Card mocking a live test-fetch result for the metric parse rule.
///
/// Design-only: shows a hardcoded 200/latency/extracted-value result so the
/// user can see the anatomy of the preview. A re-run button is visible but
/// no-op in the mockup.
class LivePreviewCard extends StatelessWidget {
  const LivePreviewCard({
    super.key,
    required this.hasRule,
    required this.onRerun,
    this.statusCode = 200,
    this.latencyMs = 142,
    this.extractedValue = '42.7',
    this.typeLabel = 'numeric',
  });

  final bool hasRule;
  final VoidCallback onRerun;
  final int statusCode;
  final int latencyMs;
  final String extractedValue;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        p-4 rounded-xl
        bg-gray-50 dark:bg-gray-900/40
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-3
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center justify-between gap-2',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                WIcon(
                  Icons.bolt_rounded,
                  className: 'text-sm text-primary dark:text-primary-300',
                ),
                WText(
                  trans('monitor.metric_form.preview.title'),
                  className: '''
                    text-xs font-bold uppercase tracking-wide
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
              ],
            ),
            WButton(
              onTap: onRerun,
              className: '''
                px-2 py-1 rounded-md
                bg-white dark:bg-gray-800
                border border-gray-200 dark:border-gray-700
                hover:bg-gray-100 dark:hover:bg-gray-700
                flex flex-row items-center gap-1
              ''',
              child: WDiv(
                className: 'flex flex-row items-center gap-1',
                children: [
                  WIcon(
                    Icons.refresh_rounded,
                    className: 'text-[12px] text-gray-600 dark:text-gray-300',
                  ),
                  WText(
                    trans('monitor.metric_form.preview.rerun'),
                    className: '''
                      text-xs font-semibold
                      text-gray-600 dark:text-gray-300
                    ''',
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!hasRule) _emptyPreview() else _resultPreview(),
      ],
    );
  }

  Widget _emptyPreview() {
    return WDiv(
      className: 'flex flex-col items-start gap-1 py-2',
      children: [
        WText(
          trans('monitor.metric_form.preview.empty_title'),
          className: '''
            text-sm font-semibold
            text-gray-700 dark:text-gray-200
          ''',
        ),
        WText(
          trans('monitor.metric_form.preview.empty_subtitle'),
          className: 'text-xs text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _resultPreview() {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-3',
          children: [
            WDiv(
              className: '''
                w-2 h-2 rounded-full
                bg-up-500 dark:bg-up-400
              ''',
            ),
            WText(
              '$statusCode OK',
              className: '''
                text-sm font-mono font-semibold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              '·',
              className: 'text-sm text-gray-400 dark:text-gray-600',
            ),
            WText(
              '$latencyMs ms',
              className: '''
                text-sm font-mono
                text-gray-600 dark:text-gray-300
              ''',
            ),
          ],
        ),
        WDiv(
          className: '''
            p-3 rounded-lg
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex flex-col gap-2
          ''',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                WIcon(
                  Icons.arrow_forward_rounded,
                  className: 'text-xs text-gray-400 dark:text-gray-500',
                ),
                WText(
                  trans('monitor.metric_form.preview.extracted'),
                  className: '''
                    text-[10px] font-bold uppercase tracking-wide
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
              ],
            ),
            WText(
              extractedValue,
              className: '''
                text-2xl font-mono font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                WIcon(
                  Icons.check_circle_rounded,
                  className: 'text-xs text-up-500 dark:text-up-400',
                ),
                WText(
                  trans(
                    'monitor.metric_form.preview.type_valid',
                    {'type': typeLabel},
                  ),
                  className: '''
                    text-xs text-gray-600 dark:text-gray-300
                  ''',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
