import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/enums/monitor_status.dart';
import '../../../app/models/mock/check_log.dart';
import '../components/common/empty_state.dart';
import '../components/monitors/check_detail_sheet.dart';
import '../components/monitors/check_timeline_row.dart';
import '../components/monitors/checks_filter_bar.dart';

/// Checks tab body: filter bar on top, timeline of check logs below.
///
/// Mock data only; drives layout iteration until the API contract lands.
class MonitorChecksTab extends StatefulWidget {
  const MonitorChecksTab({super.key});

  @override
  State<MonitorChecksTab> createState() => _MonitorChecksTabState();
}

class _MonitorChecksTabState extends State<MonitorChecksTab> {
  MonitorStatus? _status;
  String _region = 'all';
  String _range = 'h24';

  @override
  Widget build(BuildContext context) {
    final checks = _filtered(_mockChecks());
    final regions = ['all', ..._allRegions(_mockChecks())];

    return WDiv(
      className: 'flex flex-col gap-4',
      children: [
        _statsRow(_mockChecks()),
        ChecksFilterBar(
          statusFilter: _status,
          region: _region,
          range: _range,
          regions: regions,
          onStatusChanged: (s) => setState(() => _status = s),
          onRegionChanged: (r) => setState(() => _region = r),
          onRangeChanged: (r) => setState(() => _range = r),
        ),
        if (checks.isEmpty)
          _emptyState()
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
  }

  Widget _statsRow(List<CheckLog> all) {
    final total = all.length;
    final failing =
        all.where((c) => c.status != MonitorStatus.up).length;
    final successPct =
        total == 0 ? 0.0 : ((total - failing) / total) * 100;
    final avgMs = total == 0
        ? 0
        : (all
                    .map((c) => c.responseMs ?? 0)
                    .fold<int>(0, (a, b) => a + b) /
                total)
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
            text-xl font-bold font-mono
            text-gray-900 dark:text-white
          ''',
        ),
      ],
    );
  }

  Widget _emptyState() {
    return const EmptyState(
      icon: Icons.filter_alt_off_rounded,
      titleKey: 'monitor.checks_empty.title',
      subtitleKey: 'monitor.checks_empty.subtitle',
      tone: 'gray',
    );
  }

  List<CheckLog> _filtered(List<CheckLog> all) {
    return all.where((c) {
      if (_status != null) {
        if (_status == MonitorStatus.down &&
            c.status == MonitorStatus.up) {
          return false;
        }
      }
      if (_region != 'all' && c.region != _region) return false;
      return true;
    }).toList();
  }

  List<String> _allRegions(List<CheckLog> all) {
    final set = <String>{};
    for (final c in all) {
      set.add(c.region);
    }
    return set.toList();
  }

  List<CheckLog> _mockChecks() {
    final now = DateTime.now();
    return [
      CheckLog(
        id: 'c1',
        checkedAt: now.subtract(const Duration(minutes: 2)),
        region: 'eu-west-1',
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 245,
        url: 'https://api.example.com/health',
        requestHeaders: const {
          'Accept': 'application/json',
          'User-Agent': 'Uptizm/1.0',
        },
        responseHeaders: const {
          'Content-Type': 'application/json',
          'X-Response-Time': '245ms',
          'X-Cache': 'HIT',
        },
        responseBodyPreview: '{"status": "ok", "version": "1.4.2"}',
        timing: const CheckTiming(
          dnsMs: 12, connectMs: 28, tlsMs: 45, ttfbMs: 142, downloadMs: 18,
        ),
      ),
      CheckLog(
        id: 'c2',
        checkedAt: now.subtract(const Duration(minutes: 5)),
        region: 'us-east-1',
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 312,
        url: 'https://api.example.com/health',
        timing: const CheckTiming(
          dnsMs: 8, connectMs: 42, tlsMs: 60, ttfbMs: 190, downloadMs: 12,
        ),
      ),
      CheckLog(
        id: 'c3',
        checkedAt: now.subtract(const Duration(minutes: 8)),
        region: 'ap-southeast-1',
        status: MonitorStatus.degraded,
        statusCode: 200,
        responseMs: 1245,
        url: 'https://api.example.com/health',
        timing: const CheckTiming(
          dnsMs: 14, connectMs: 98, tlsMs: 180, ttfbMs: 932, downloadMs: 21,
        ),
      ),
      CheckLog(
        id: 'c4',
        checkedAt: now.subtract(const Duration(minutes: 11)),
        region: 'eu-central-1',
        status: MonitorStatus.down,
        statusCode: 500,
        responseMs: null,
        errorMessage: 'Connection timeout after 30s',
        url: 'https://api.example.com/health',
        timing: const CheckTiming(
          dnsMs: 10, connectMs: 30000, tlsMs: 0, ttfbMs: 0, downloadMs: 0,
        ),
      ),
      CheckLog(
        id: 'c5',
        checkedAt: now.subtract(const Duration(minutes: 14)),
        region: 'eu-central-1',
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 198,
        url: 'https://api.example.com/health',
        timing: const CheckTiming(
          dnsMs: 9, connectMs: 22, tlsMs: 38, ttfbMs: 118, downloadMs: 11,
        ),
      ),
      CheckLog(
        id: 'c6',
        checkedAt: now.subtract(const Duration(minutes: 17)),
        region: 'eu-west-1',
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 232,
        url: 'https://api.example.com/health',
        timing: const CheckTiming(
          dnsMs: 11, connectMs: 26, tlsMs: 42, ttfbMs: 140, downloadMs: 13,
        ),
      ),
      CheckLog(
        id: 'c7',
        checkedAt: now.subtract(const Duration(minutes: 20)),
        region: 'us-east-1',
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 289,
        url: 'https://api.example.com/health',
      ),
      CheckLog(
        id: 'c8',
        checkedAt: now.subtract(const Duration(minutes: 23)),
        region: 'ap-southeast-1',
        status: MonitorStatus.up,
        statusCode: 200,
        responseMs: 534,
        url: 'https://api.example.com/health',
      ),
    ];
  }
}
