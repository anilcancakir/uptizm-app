import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_type.dart';
import '../../../../app/models/mock/monitor_metric.dart';
import 'metric_form_sheet.dart';
import 'metric_overflow_menu.dart';
import 'metric_sparkline.dart';
import 'time_range_tabs.dart';

/// Bottom sheet presenting a drill-down view for a single response metric.
///
/// Mock-only: time range tabs, hero value, a large sparkline for numeric
/// metrics, and a placeholder recent-values list.
class MetricDetailSheet extends StatefulWidget {
  const MetricDetailSheet({super.key, required this.metric});

  final MonitorMetric metric;

  static Future<void> show(BuildContext context, MonitorMetric metric) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MetricDetailSheet(metric: metric),
    );
  }

  @override
  State<MetricDetailSheet> createState() => _MetricDetailSheetState();
}

class _MetricDetailSheetState extends State<MetricDetailSheet> {
  TimeRange _range = TimeRange.d7;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
            _buildGrabber(),
            _buildHeader(),
            WDiv(
              className: 'flex-1 overflow-y-auto',
              scrollPrimary: true,
              children: [
                WDiv(
                  className: 'p-4 flex flex-col gap-6',
                  children: [
                    _buildRangeRow(),
                    _buildChartCard(),
                    _buildRecentValues(),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: '''
          w-10 h-1 rounded-full
          bg-gray-300 dark:bg-gray-600
        ''',
      ),
    );
  }

  Widget _buildHeader() {
    final m = widget.metric;
    return WDiv(
      className: '''
        px-4 pb-4
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-start gap-3
      ''',
      children: [
        WDiv(
          className: 'flex-1 flex flex-col gap-1 min-w-0',
          children: [
            WText(
              m.label,
              className: '''
                text-xl font-bold
                text-gray-900 dark:text-white truncate
              ''',
            ),
            if (m.path != null)
              WText(
                m.path!,
                className: '''
                  text-xs font-mono
                  text-gray-500 dark:text-gray-400 truncate
                ''',
              ),
          ],
        ),
        MetricOverflowMenu(
          onEdit: () {
            MagicRoute.back();
            MetricFormSheet.show(
              context,
              mode: 'edit',
              existingGroups: const [],
              initial: MetricFormInitial(
                label: m.label,
                key: m.key,
                group: m.group,
                path: m.path ?? '',
                unit: m.unit ?? '',
              ),
            );
          },
          onDuplicate: () {
            MagicRoute.back();
            MetricFormSheet.show(
              context,
              mode: 'duplicate',
              existingGroups: const [],
              initial: MetricFormInitial(
                label: '${m.label} (copy)',
                group: m.group,
                path: m.path ?? '',
                unit: m.unit ?? '',
              ),
            );
          },
          onDelete: () async {
            final confirmed = await Magic.confirm(
              title: trans('monitor.metric_menu.delete_title'),
              message: trans(
                'monitor.metric_menu.delete_message',
                {'label': m.label},
              ),
              confirmText: trans('monitor.metric_menu.delete'),
              cancelText: trans('common.cancel'),
              isDangerous: true,
            );
            if (confirmed) {
              MagicRoute.back();
              Magic.toast(trans('monitor.metric_menu.deleted_toast'));
            }
          },
        ),
      ],
    );
  }

  Widget _buildRangeRow() {
    return WDiv(
      className: 'flex flex-row items-center gap-3',
      children: [
        WDiv(
          className: 'flex-1',
          child: WText(
            trans('monitor.section.performance'),
            className: '''
              text-xs font-bold uppercase tracking-wider
              text-gray-500 dark:text-gray-400
            ''',
          ),
        ),
        TimeRangeTabs(
          selected: _range,
          onChanged: (r) => setState(() => _range = r),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    final m = widget.metric;
    return WDiv(
      className: '''
        rounded-xl p-4
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-4
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-baseline gap-1',
          children: [
            WText(
              _heroValue(m),
              className: '''
                text-3xl font-bold font-mono
                text-gray-900 dark:text-white
              ''',
            ),
            if (m.unit != null)
              WText(
                m.unit!,
                className: '''
                  text-sm font-semibold
                  text-gray-500 dark:text-gray-400
                ''',
              ),
          ],
        ),
        WDiv(
          className: 'h-32',
          child: MetricSparkline(
            samples: m.samples,
            toneKey: m.band?.toneKey ?? '',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentValues() {
    final samples = widget.metric.samples.reversed.take(8).toList();
    return WDiv(
      className: '''
        rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col
      ''',
      children: [
        WDiv(
          className: '''
            px-4 py-3
            border-b border-gray-100 dark:border-gray-800
          ''',
          child: WText(
            trans('monitor.section.recent_checks'),
            className: '''
              text-xs font-bold uppercase tracking-wider
              text-gray-500 dark:text-gray-400
            ''',
          ),
        ),
        for (var i = 0; i < samples.length; i++)
          WDiv(
            className: '''
              px-4 py-3
              flex flex-row items-center
              border-b border-gray-100 dark:border-gray-800
              last:border-b-0
            ''',
            children: [
              WDiv(
                className: 'flex-1',
                child: WText(
                  '${i * 3 + 2} m ago',
                  className: '''
                    text-xs
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
              ),
              WText(
                samples[i].toStringAsFixed(0) +
                    (widget.metric.unit == null ? '' : ' ${widget.metric.unit}'),
                className: '''
                  text-sm font-mono font-semibold
                  text-gray-800 dark:text-gray-100
                ''',
              ),
            ],
          ),
      ],
    );
  }

  String _heroValue(MonitorMetric m) {
    if (m.type == MetricType.numeric) {
      return m.numericValue?.toStringAsFixed(0) ?? '--';
    }
    return m.stringValue ?? m.statusValue?.name.toUpperCase() ?? '--';
  }
}
