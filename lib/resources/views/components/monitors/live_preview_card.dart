import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/metric_preview_result.dart';

/// Live-preview card that renders the outcome of the server-side dry-run
/// performed against the monitor's URL with the form's draft extraction
/// rule.
///
/// Pure display widget: the parent form sheet drives `isLoading`,
/// `result`, and `errorMessage`; the card only dispatches re-run intent
/// back up via [onRerun].
class LivePreviewCard extends StatelessWidget {
  const LivePreviewCard({
    super.key,
    required this.hasRule,
    required this.onRerun,
    required this.typeLabel,
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  final bool hasRule;
  final VoidCallback onRerun;
  final String typeLabel;
  final bool isLoading;
  final MetricPreviewResult? result;
  final String? errorMessage;

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
            _rerunButton(),
          ],
        ),
        _content(),
      ],
    );
  }

  Widget _rerunButton() {
    return WButton(
      onTap: isLoading || !hasRule ? null : onRerun,
      states: (isLoading || !hasRule) ? {'disabled'} : {},
      className: '''
        px-2 py-1 rounded-md
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:bg-gray-100 dark:hover:bg-gray-700
        disabled:opacity-50
        flex flex-row items-center gap-1
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-1',
        children: [
          WIcon(
            isLoading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
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
    );
  }

  Widget _content() {
    if (!hasRule) return _emptyPreview();
    if (isLoading) return _loadingPreview();
    if (errorMessage != null) return _errorPreview(errorMessage!);
    final r = result;
    if (r == null) return _idlePreview();
    if (r.error != null) return _resultPreview(r, extractionError: r.error);
    return _resultPreview(r);
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

  Widget _idlePreview() {
    return WDiv(
      className: 'flex flex-col items-start gap-1 py-2',
      children: [
        WText(
          trans('monitor.metric_form.preview.idle_title'),
          className: '''
            text-sm font-semibold
            text-gray-700 dark:text-gray-200
          ''',
        ),
        WText(
          trans('monitor.metric_form.preview.idle_subtitle'),
          className: 'text-xs text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _loadingPreview() {
    return WDiv(
      className: 'flex flex-row items-center gap-2 py-3',
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        WText(
          trans('monitor.metric_form.preview.loading'),
          className: 'text-xs text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _errorPreview(String message) {
    return WDiv(
      className: '''
        p-3 rounded-lg
        bg-down-50 dark:bg-down-900/20
        border border-down-200 dark:border-down-800
        flex flex-row items-start gap-2
      ''',
      children: [
        WIcon(
          Icons.error_outline_rounded,
          className: 'text-sm text-down-600 dark:text-down-400',
        ),
        WText(
          message,
          className: '''
            flex-1 text-xs
            text-down-700 dark:text-down-200
          ''',
        ),
      ],
    );
  }

  Widget _resultPreview(MetricPreviewResult r, {String? extractionError}) {
    final status = r.statusCode;
    final isUp = status != null && status >= 200 && status < 400;
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-3',
          children: [
            WDiv(
              className: isUp
                  ? 'w-2 h-2 rounded-full bg-up-500 dark:bg-up-400'
                  : 'w-2 h-2 rounded-full bg-down-500 dark:bg-down-400',
            ),
            WText(
              status != null ? '$status' : '—',
              className: '''
                text-sm font-mono font-semibold
                text-gray-900 dark:text-white
              ''',
            ),
            WText('·', className: 'text-sm text-gray-400 dark:text-gray-600'),
            WText(
              '${r.latencyMs} ms',
              className: '''
                text-sm font-mono
                text-gray-600 dark:text-gray-300
              ''',
            ),
          ],
        ),
        if (extractionError != null)
          _errorPreview(extractionError)
        else
          _extractedBlock(r),
      ],
    );
  }

  Widget _extractedBlock(MetricPreviewResult r) {
    return WDiv(
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
          r.extractedValue ?? '—',
          className: '''
            text-2xl font-mono font-bold
            text-gray-900 dark:text-white
          ''',
        ),
        WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WIcon(
              r.typeValid
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              className: r.typeValid
                  ? 'text-xs text-up-500 dark:text-up-400'
                  : 'text-xs text-warn-500 dark:text-warn-400',
            ),
            WText(
              r.typeValid
                  ? trans('monitor.metric_form.preview.type_valid', {
                      'type': typeLabel,
                    })
                  : trans('monitor.metric_form.preview.type_invalid', {
                      'type': typeLabel,
                    }),
              className: '''
                text-xs text-gray-600 dark:text-gray-300
              ''',
            ),
          ],
        ),
      ],
    );
  }
}
