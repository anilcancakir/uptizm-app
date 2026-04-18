import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/monitors/monitor_check_controller.dart';
import '../../../app/enums/monitor_status.dart';
import '../../../app/models/monitor_check.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/skeleton_row.dart';
import '../components/monitors/check_detail_sheet.dart';
import '../components/monitors/check_timeline_row.dart';
import '../components/monitors/checks_filter_bar.dart';

/// Checks tab body: filter bar on top, timeline of check logs below.
///
/// Consumes [MonitorCheckController] loaded by the parent show view.
/// Stats and region list derive from the live list; filters apply
/// client-side.
class MonitorChecksTab extends StatefulWidget {
  const MonitorChecksTab({super.key, required this.monitorId});

  final String monitorId;

  @override
  State<MonitorChecksTab> createState() => _MonitorChecksTabState();
}

class _MonitorChecksTabState extends State<MonitorChecksTab> {
  MonitorStatus? _status;
  String _region = 'all';
  String _range = 'h24';

  MonitorCheckController get _controller => MonitorCheckController.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final all = _controller.checks;
        final status = _controller.rxStatus;
        if (status.isLoading && all.isEmpty) return const SkeletonRowList();
        if (status.isError && all.isEmpty) {
          return ErrorBanner(
            message: status.message,
            onRetry: () => _controller.load(widget.monitorId),
          );
        }
        final checks = _filtered(all);
        final regions = ['all', ..._allRegions(all)];

        return WDiv(
          className: 'flex flex-col gap-4',
          children: [
            _statsRow(all),
            ChecksFilterBar(
              statusFilter: _status,
              region: _region,
              range: _range,
              regions: regions,
              onStatusChanged: (s) => setState(() => _status = s),
              onRegionChanged: (r) => setState(() => _region = r),
              onRangeChanged: (r) => setState(() => _range = r),
            ),
            if (all.isEmpty)
              _emptyState()
            else if (checks.isEmpty)
              _filteredEmptyState()
            else
              WDiv(
                className: '''
                  rounded-xl overflow-hidden
                  bg-white dark:bg-gray-800
                  border border-gray-200 dark:border-gray-700
                  flex flex-col
                ''',
                children: [
                  for (final c in checks)
                    CheckTimelineRow(
                      check: c,
                      onTap: () => CheckDetailSheet.show(context, c),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _statsRow(List<MonitorCheck> all) {
    final total = all.length;
    final failing = all.where((c) => c.status != MonitorStatus.up).length;
    final successPct = total == 0 ? 0.0 : ((total - failing) / total) * 100;
    final withMs = all.where((c) => c.responseMs != null).toList();
    final avgMs = withMs.isEmpty
        ? 0
        : (withMs.map((c) => c.responseMs!).fold<int>(0, (a, b) => a + b) /
                  withMs.length)
              .round();

    return WDiv(
      className: 'grid grid-cols-2 sm:grid-cols-4 gap-3',
      children: [
        _statCard(
          labelKey: 'monitor.stats.checks.total',
          value: '$total',
          icon: Icons.dns_rounded,
        ),
        _statCard(
          labelKey: 'monitor.stats.checks.success',
          value: '${successPct.toStringAsFixed(1)}%',
          icon: Icons.check_circle_outline_rounded,
          tone: 'up',
        ),
        _statCard(
          labelKey: 'monitor.stats.checks.avg',
          value: '$avgMs ms',
          icon: Icons.speed_rounded,
        ),
        _statCard(
          labelKey: 'monitor.stats.checks.failing',
          value: '$failing',
          icon: Icons.warning_amber_rounded,
          tone: failing > 0 ? 'down' : null,
        ),
      ],
    );
  }

  Widget _statCard({
    required String labelKey,
    required String value,
    required IconData icon,
    String? tone,
  }) {
    return WDiv(
      states: tone == null ? null : {tone},
      className: '''
        rounded-xl p-3
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        up:border-up-200 dark:up:border-up-800
        down:border-down-200 dark:down:border-down-800
        flex flex-col gap-1
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WIcon(
              icon,
              states: tone == null ? null : {tone},
              className: '''
                text-sm text-gray-500 dark:text-gray-400
                up:text-up-500 dark:up:text-up-400
                down:text-down-500 dark:down:text-down-400
              ''',
            ),
            WText(
              trans(labelKey),
              className: '''
                text-xs font-semibold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
        WText(
          value,
          className: '''
            text-xl font-bold font-mono truncate
            text-gray-900 dark:text-white
          ''',
        ),
      ],
    );
  }

  Widget _emptyState() {
    return const EmptyState(
      icon: Icons.dns_rounded,
      titleKey: 'monitor.checks_empty.title',
      subtitleKey: 'monitor.checks_empty.subtitle',
      tone: 'gray',
    );
  }

  Widget _filteredEmptyState() {
    return const EmptyState(
      icon: Icons.filter_alt_off_rounded,
      titleKey: 'monitor.checks_empty.title',
      subtitleKey: 'monitor.checks_empty.subtitle',
      tone: 'gray',
    );
  }

  List<MonitorCheck> _filtered(List<MonitorCheck> all) {
    return all.where((c) {
      if (_status != null) {
        if (_status == MonitorStatus.down && c.status == MonitorStatus.up) {
          return false;
        }
      }
      if (_region != 'all' && c.region != _region) return false;
      return true;
    }).toList();
  }

  List<String> _allRegions(List<MonitorCheck> all) {
    final set = <String>{};
    for (final c in all) {
      final r = c.region;
      if (r != null && r.isNotEmpty) set.add(r);
    }
    return set.toList()..sort();
  }
}
