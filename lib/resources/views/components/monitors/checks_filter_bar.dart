import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';

/// Filter bar above the Checks timeline.
///
/// Three quick filters: status (all / failing), region (All or specific), and
/// time range (24h / 7d / 30d). Rendered as rounded pills; tapping toggles.
class ChecksFilterBar extends StatelessWidget {
  const ChecksFilterBar({
    super.key,
    required this.statusFilter,
    required this.region,
    required this.range,
    required this.regions,
    required this.onStatusChanged,
    required this.onRegionChanged,
    required this.onRangeChanged,
  });

  /// `null` = all, or a specific status (down/degraded).
  final MonitorStatus? statusFilter;
  final String region;
  final String range;
  final List<String> regions;
  final ValueChanged<MonitorStatus?> onStatusChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-row items-center gap-2',
      children: [
        WDiv(
          className: 'flex-1 min-w-0 overflow-x-auto',
          child: WDiv(
            className: 'flex flex-row items-center gap-2',
            children: [
              _pill(
                labelKey: 'monitor.checks_filter.status.all',
                active: statusFilter == null,
                icon: Icons.dns_rounded,
                onTap: () => onStatusChanged(null),
              ),
              _pill(
                labelKey: 'monitor.checks_filter.status.failing',
                active: statusFilter == MonitorStatus.down ||
                    statusFilter == MonitorStatus.degraded,
                icon: Icons.warning_amber_rounded,
                tone: 'down',
                onTap: () => onStatusChanged(
                  statusFilter == null ? MonitorStatus.down : null,
                ),
              ),
              WDiv(
                className: 'w-px h-5 bg-gray-200 dark:bg-gray-700 mx-1',
              ),
              for (final r in regions)
                _regionPill(
                  region: r,
                  active: region == r,
                  onTap: () => onRegionChanged(r),
                ),
            ],
          ),
        ),
        WDiv(
          className: '''
            rounded-full p-0.5
            bg-gray-100 dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex flex-row items-center gap-0.5
          ''',
          children: [
            for (final r in const ['h24', 'd7', 'd30'])
              _rangeSegment(
                labelKey: 'monitor.range.$r',
                active: range == r,
                onTap: () => onRangeChanged(r),
              ),
          ],
        ),
      ],
    );
  }

  Widget _regionPill({
    required String region,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isAll = region == 'all';
    final label = isAll ? trans('monitor.checks_filter.region_all') : region;
    return WButton(
      onTap: onTap,
      states: active ? {'active'} : {},
      className: '''
        px-3 py-1.5 rounded-full
        border border-gray-200 dark:border-gray-700
        bg-white dark:bg-gray-800
        hover:bg-gray-50 dark:hover:bg-gray-700
        active:bg-primary-50 dark:active:bg-primary-900/30
        active:border-primary-300 dark:active:border-primary-700
        flex flex-row items-center gap-1.5
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-1.5',
        children: [
          if (isAll)
            WIcon(
              Icons.public_rounded,
              states: active ? {'active'} : {},
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400
                active:text-primary dark:active:text-primary-300
              ''',
            )
          else
            WText(
              _flagFor(region),
              className: 'text-sm leading-none',
            ),
          WText(
            label,
            states: active ? {'active'} : {},
            className: '''
              text-xs font-semibold
              text-gray-700 dark:text-gray-200
              active:text-primary-700 dark:active:text-primary-300
            ''',
          ),
        ],
      ),
    );
  }

  Widget _rangeSegment({
    required String labelKey,
    required bool active,
    required VoidCallback onTap,
  }) {
    return WButton(
      onTap: onTap,
      states: active ? {'active'} : {},
      className: '''
        px-3 py-1 rounded-full
        hover:bg-white/60 dark:hover:bg-gray-900/40
        active:bg-white dark:active:bg-gray-900
        active:shadow-sm
        flex flex-row items-center justify-center
      ''',
      child: WText(
        trans(labelKey),
        states: active ? {'active'} : {},
        className: '''
          text-xs font-semibold
          text-gray-500 dark:text-gray-400
          active:text-primary-700 dark:active:text-primary-300
        ''',
      ),
    );
  }

  String _flagFor(String region) {
    const map = {
      'eu-west-1': '🇮🇪',
      'eu-west-2': '🇬🇧',
      'eu-west-3': '🇫🇷',
      'eu-central-1': '🇩🇪',
      'eu-north-1': '🇸🇪',
      'eu-south-1': '🇮🇹',
      'us-east-1': '🇺🇸',
      'us-east-2': '🇺🇸',
      'us-west-1': '🇺🇸',
      'us-west-2': '🇺🇸',
      'ca-central-1': '🇨🇦',
      'sa-east-1': '🇧🇷',
      'ap-southeast-1': '🇸🇬',
      'ap-southeast-2': '🇦🇺',
      'ap-northeast-1': '🇯🇵',
      'ap-northeast-2': '🇰🇷',
      'ap-south-1': '🇮🇳',
      'me-south-1': '🇧🇭',
      'af-south-1': '🇿🇦',
    };
    return map[region] ?? '🌐';
  }

  Widget _pill({
    String? labelKey,
    String? rawLabel,
    required bool active,
    IconData? icon,
    String? tone,
    required VoidCallback onTap,
  }) {
    final label = labelKey != null ? trans(labelKey) : rawLabel ?? '';
    return WButton(
      onTap: onTap,
      states: {
        if (active) 'active',
        ?tone,
      },
      className: '''
        px-3 py-1.5 rounded-full
        border border-gray-200 dark:border-gray-700
        bg-white dark:bg-gray-800
        hover:bg-gray-50 dark:hover:bg-gray-700
        active:bg-primary-50 dark:active:bg-primary-900/30
        active:border-primary-300 dark:active:border-primary-700
        down:active:bg-down-50 dark:down:active:bg-down-900/30
        down:active:border-down-300 dark:down:active:border-down-700
        flex flex-row items-center gap-1.5
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-1.5',
        children: [
          if (icon != null)
            WIcon(
              icon,
              states: {
                if (active) 'active',
                ?tone,
              },
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400
                active:text-primary dark:active:text-primary-300
                down:active:text-down-600 dark:down:active:text-down-400
              ''',
            ),
          WText(
            label,
            states: {
              if (active) 'active',
              ?tone,
            },
            className: '''
              text-xs font-semibold
              text-gray-700 dark:text-gray-200
              active:text-primary-700 dark:active:text-primary-300
              down:active:text-down-700 dark:down:active:text-down-400
            ''',
          ),
        ],
      ),
    );
  }
}
