import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/incident.dart';
import '../ai/ai_avatar.dart';
import '../ai/ai_confidence_badge.dart';

/// Incident detail's "AI Analysis" section.
///
/// Renders: header (avatar + title + confidence), TL;DR paragraph, evidence
/// bullets, suggested actions, and (when present) similar past incidents.
/// Accept / Reject feedback buttons at the bottom let the user train the
/// model.
class AiAnalysisCard extends StatelessWidget {
  const AiAnalysisCard({
    super.key,
    required this.analysis,
    required this.similar,
    this.onAccept,
    this.onReject,
    this.onEvidenceTap,
    this.onSimilarTap,
  });

  final AiAnalysis analysis;
  final List<SimilarIncident> similar;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final ValueChanged<AiEvidence>? onEvidenceTap;
  final ValueChanged<SimilarIncident>? onSimilarTap;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-xl overflow-hidden
        border border-ai-200 dark:border-ai-800
        bg-ai-50/30 dark:bg-ai-950/30
        flex flex-col
      ''',
      children: [
        _header(),
        WDiv(
          className: 'p-4 flex flex-col gap-4',
          children: [
            _tldr(),
            if (analysis.evidence.isNotEmpty) _evidence(),
            if (analysis.suggestedActions.isNotEmpty) _actions(),
            if (similar.isNotEmpty) _similar(),
            _feedbackRow(),
          ],
        ),
      ],
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-ai-200 dark:border-ai-800
        bg-white/50 dark:bg-gray-900/50
        flex flex-row items-center gap-2
      ''',
      children: [
        const AiAvatar(size: 'sm'),
        WDiv(
          className: 'flex-1 flex flex-col',
          children: [
            WText(
              trans('ai.analysis.title'),
              className: '''
                text-xs font-bold uppercase tracking-wider
                text-ai-700 dark:text-ai-300
              ''',
            ),
            WText(
              trans(analysis.trigger.labelKey),
              className: '''
                text-[10px]
                text-ai-600/80 dark:text-ai-400/80
              ''',
            ),
          ],
        ),
        AiConfidenceBadge(confidence: analysis.confidence),
      ],
    );
  }

  Widget _tldr() {
    return WText(
      analysis.tldr,
      className: '''
        text-sm leading-relaxed
        text-gray-800 dark:text-gray-100
      ''',
    );
  }

  Widget _evidence() {
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        WText(
          trans('ai.analysis.evidence'),
          className: '''
            text-xs font-bold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WDiv(
          className: 'flex flex-col gap-1.5',
          children: [
            for (final e in analysis.evidence)
              WButton(
                onTap: onEvidenceTap == null ? null : () => onEvidenceTap!(e),
                className: '''
                  p-2.5 rounded-lg
                  bg-white dark:bg-gray-800
                  border border-gray-200 dark:border-gray-700
                  hover:border-ai-300 dark:hover:border-ai-700
                  flex flex-row items-start gap-2
                ''',
                child: WDiv(
                  className: 'flex flex-row items-start gap-2 w-full',
                  children: [
                    WIcon(
                      Icons.insights_rounded,
                      className: 'text-xs text-ai-500 dark:text-ai-400 mt-0.5',
                    ),
                    WDiv(
                      className: 'flex-1 flex flex-col gap-0.5 min-w-0',
                      children: [
                        WText(
                          e.label,
                          className: '''
                            text-xs font-semibold
                            text-gray-800 dark:text-gray-100
                          ''',
                        ),
                        WText(
                          e.detail,
                          className: '''
                            text-xs font-mono
                            text-gray-500 dark:text-gray-400
                          ''',
                        ),
                      ],
                    ),
                    if (e.metricKey != null)
                      WIcon(
                        Icons.chevron_right_rounded,
                        className: 'text-sm text-gray-400 dark:text-gray-500',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _actions() {
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        WText(
          trans('ai.analysis.suggested'),
          className: '''
            text-xs font-bold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WDiv(
          className: 'flex flex-col gap-1.5',
          children: [
            for (final a in analysis.suggestedActions)
              WDiv(
                className: '''
                  p-2.5 rounded-lg
                  bg-white dark:bg-gray-800
                  border border-gray-200 dark:border-gray-700
                  flex flex-row items-start gap-2
                ''',
                children: [
                  WIcon(
                    Icons.bolt_rounded,
                    className:
                        'text-xs text-degraded-500 dark:text-degraded-400 mt-0.5',
                  ),
                  WDiv(
                    className: 'flex-1 flex flex-col gap-0.5 min-w-0',
                    children: [
                      WText(
                        a.title,
                        className: '''
                          text-xs font-semibold
                          text-gray-800 dark:text-gray-100
                        ''',
                      ),
                      WText(
                        a.rationale,
                        className: '''
                          text-xs
                          text-gray-500 dark:text-gray-400
                        ''',
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _similar() {
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        WText(
          trans('ai.analysis.similar'),
          className: '''
            text-xs font-bold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WDiv(
          className: 'flex flex-col gap-1.5',
          children: [
            for (final s in similar)
              WButton(
                onTap: onSimilarTap == null ? null : () => onSimilarTap!(s),
                className: '''
                  p-2.5 rounded-lg
                  bg-white dark:bg-gray-800
                  border border-gray-200 dark:border-gray-700
                  hover:border-primary-300 dark:hover:border-primary-700
                  flex flex-row items-start gap-2
                ''',
                child: WDiv(
                  className: 'flex flex-row items-start gap-2 w-full',
                  children: [
                    WIcon(
                      Icons.history_rounded,
                      className:
                          'text-xs text-gray-400 dark:text-gray-500 mt-0.5',
                    ),
                    WDiv(
                      className: 'flex-1 flex flex-col gap-0.5 min-w-0',
                      children: [
                        WText(
                          s.title,
                          className: '''
                            text-xs font-semibold
                            text-gray-800 dark:text-gray-100
                          ''',
                        ),
                        WText(
                          s.resolutionNote,
                          className: '''
                            text-xs italic
                            text-gray-500 dark:text-gray-400
                          ''',
                        ),
                      ],
                    ),
                    WIcon(
                      Icons.chevron_right_rounded,
                      className: 'text-sm text-gray-400 dark:text-gray-500',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _feedbackRow() {
    return WDiv(
      className: '''
        pt-3
        border-t border-ai-200/50 dark:border-ai-800/50
        flex flex-row items-center gap-2
      ''',
      children: [
        WDiv(
          className: 'flex-1',
          child: WText(
            trans('ai.analysis.feedback_prompt'),
            className: 'text-xs text-gray-500 dark:text-gray-400',
          ),
        ),
        WButton(
          onTap: onReject,
          className: '''
            px-3 py-1.5 rounded-md
            border border-gray-200 dark:border-gray-700
            hover:bg-gray-100 dark:hover:bg-gray-800
            flex flex-row items-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.thumb_down_off_alt_rounded,
                className: 'text-xs text-gray-500 dark:text-gray-400',
              ),
              WText(
                trans('ai.analysis.reject'),
                className: '''
                  text-xs font-semibold
                  text-gray-700 dark:text-gray-200
                ''',
              ),
            ],
          ),
        ),
        WButton(
          onTap: onAccept,
          className: '''
            px-3 py-1.5 rounded-md
            bg-ai-500 dark:bg-ai-600
            hover:bg-ai-600 dark:hover:bg-ai-700
            flex flex-row items-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(Icons.thumb_up_rounded, className: 'text-xs text-white'),
              WText(
                trans('ai.analysis.accept'),
                className: 'text-xs font-semibold text-white',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
