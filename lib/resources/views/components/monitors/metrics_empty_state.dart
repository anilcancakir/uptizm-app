import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_source.dart';
import '../../../../app/enums/metric_type.dart';
import '../common/primary_button.dart';
import 'metric_form_sheet.dart';

/// Preset suggestion shown when a monitor has no custom metrics yet.
class _Preset {
  const _Preset({
    required this.labelKey,
    required this.descriptionKey,
    required this.icon,
    required this.initial,
  });

  final String labelKey;
  final String descriptionKey;
  final IconData icon;
  final MetricFormInitial initial;
}

/// Empty state shown on the Metrics tab when no custom metrics exist.
///
/// Presents hand-picked preset cards that open the Add sheet pre-filled, plus
/// a fallback "Add custom metric" CTA at the bottom.
class MetricsEmptyState extends StatelessWidget {
  const MetricsEmptyState({super.key, required this.monitorId});

  final String monitorId;

  static final List<_Preset> _presets = [
    const _Preset(
      labelKey: 'monitor.metrics_empty.preset.response_time.label',
      descriptionKey: 'monitor.metrics_empty.preset.response_time.description',
      icon: Icons.timer_outlined,
      initial: MetricFormInitial(
        label: 'Response time',
        key: 'response_time',
        group: 'HTTP',
        source: MetricSource.header,
        path: 'X-Response-Time',
        type: MetricType.numeric,
        unit: 'ms',
        warn: '500',
        critical: '1000',
      ),
    ),
    const _Preset(
      labelKey: 'monitor.metrics_empty.preset.http_status.label',
      descriptionKey: 'monitor.metrics_empty.preset.http_status.description',
      icon: Icons.pin_rounded,
      initial: MetricFormInitial(
        label: 'HTTP status',
        key: 'http_status',
        group: 'HTTP',
        source: MetricSource.httpStatus,
        path: '',
        type: MetricType.numeric,
      ),
    ),
    const _Preset(
      labelKey: 'monitor.metrics_empty.preset.cache_hit.label',
      descriptionKey: 'monitor.metrics_empty.preset.cache_hit.description',
      icon: Icons.bolt_rounded,
      initial: MetricFormInitial(
        label: 'Cache hit',
        key: 'cache_hit',
        group: 'HTTP',
        source: MetricSource.header,
        path: 'X-Cache',
        type: MetricType.string,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        p-4 lg:p-6 rounded-2xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-5
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-3',
          children: [
            WDiv(
              className: '''
                w-11 h-11 rounded-xl
                bg-primary-50 dark:bg-primary-900/30
                flex items-center justify-center
              ''',
              child: WIcon(
                Icons.analytics_outlined,
                className: 'text-xl text-primary dark:text-primary-300',
              ),
            ),
            WDiv(
              className: 'flex-1 flex flex-col gap-0.5',
              children: [
                WText(
                  trans('monitor.metrics_empty.title'),
                  className: '''
                    text-base font-semibold
                    text-gray-900 dark:text-white
                  ''',
                ),
                WText(
                  trans('monitor.metrics_empty.subtitle'),
                  className: 'text-xs text-gray-500 dark:text-gray-400',
                ),
              ],
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-col gap-2',
          children: [
            WText(
              trans('monitor.metrics_empty.presets_heading'),
              className: '''
                text-xs font-bold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
              ''',
            ),
            WDiv(
              className: '''
                grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3
              ''',
              children: [for (final p in _presets) _presetCard(context, p)],
            ),
          ],
        ),
        WDiv(
          className: '''
            flex flex-row items-center gap-3
            pt-3 border-t border-gray-100 dark:border-gray-800
          ''',
          children: [
            WDiv(
              className: 'flex-1',
              child: WText(
                trans('monitor.metrics_empty.or_custom'),
                className: 'text-sm text-gray-500 dark:text-gray-400',
              ),
            ),
            PrimaryButton(
              labelKey: 'monitor.metrics_empty.add_custom',
              icon: Icons.add_rounded,
              onTap: () => MetricFormSheet.show(
                context,
                mode: 'create',
                monitorId: monitorId,
                existingGroups: const [],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetCard(BuildContext context, _Preset preset) {
    return WButton(
      onTap: () => MetricFormSheet.show(
        context,
        mode: 'create',
        monitorId: monitorId,
        existingGroups: const [],
        initial: preset.initial,
      ),
      className: '''
        p-3 rounded-xl
        bg-gray-50 dark:bg-gray-900/40
        border border-gray-200 dark:border-gray-700
        hover:border-primary-300 dark:hover:border-primary-700
        hover:bg-white dark:hover:bg-gray-900
        flex flex-row items-start gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-start gap-3 w-full',
        children: [
          WDiv(
            className: '''
              w-8 h-8 rounded-lg
              bg-white dark:bg-gray-800
              border border-gray-200 dark:border-gray-700
              flex items-center justify-center
            ''',
            child: WIcon(
              preset.icon,
              className: 'text-sm text-gray-600 dark:text-gray-300',
            ),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WDiv(
                className: 'flex flex-row items-center justify-between gap-2',
                children: [
                  WText(
                    trans(preset.labelKey),
                    className: '''
                      text-sm font-semibold
                      text-gray-900 dark:text-white truncate
                    ''',
                  ),
                  WIcon(
                    Icons.add_rounded,
                    className: 'text-sm text-primary dark:text-primary-300',
                  ),
                ],
              ),
              WText(
                trans(preset.descriptionKey),
                className: '''
                  text-xs text-gray-500 dark:text-gray-400
                ''',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
