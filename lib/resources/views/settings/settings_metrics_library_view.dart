import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/enums/metric_type.dart';
import '../components/common/app_back_button.dart';
import '../components/common/empty_state.dart';

/// Workspace-wide metrics library.
///
/// Aggregates every custom metric key defined across the workspace's
/// monitors and shows how widely each is used. Read-only mockup; editing
/// still happens on the owning monitor.
class SettingsMetricsLibraryView extends StatefulWidget {
  const SettingsMetricsLibraryView({super.key});

  @override
  State<SettingsMetricsLibraryView> createState() =>
      _SettingsMetricsLibraryViewState();
}

class _SettingsMetricsLibraryViewState
    extends State<SettingsMetricsLibraryView> {
  MetricType? _typeFilter;
  String? _groupFilter;

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    final groups = rows.map((r) => r.group).toSet().toList();
    final filtered = rows
        .where((r) => _typeFilter == null || r.type == _typeFilter)
        .where((r) => _groupFilter == null || r.group == _groupFilter)
        .toList();

    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/'),
          title: trans('settings.metrics_library.title'),
          subtitle: trans('settings.metrics_library.subtitle'),
        ),
        _filterBar(groups),
        if (filtered.isEmpty) _empty() else _table(filtered),
      ],
    );
  }

  Widget _filterBar(List<String> groups) {
    return WDiv(
      className: 'wrap items-center gap-2',
      children: [
        _chip(
          labelKey: 'settings.metrics_library.filter_all',
          active: _typeFilter == null && _groupFilter == null,
          onTap: () => setState(() {
            _typeFilter = null;
            _groupFilter = null;
          }),
        ),
        for (final t in MetricType.values)
          _chip(
            label: trans(t.labelKey),
            active: _typeFilter == t,
            onTap: () =>
                setState(() => _typeFilter = _typeFilter == t ? null : t),
          ),
        for (final g in groups)
          _chip(
            label: g,
            active: _groupFilter == g,
            onTap: () =>
                setState(() => _groupFilter = _groupFilter == g ? null : g),
          ),
      ],
    );
  }

  Widget _chip({
    String? labelKey,
    String? label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return WButton(
      onTap: onTap,
      states: active ? {'active'} : {},
      className: '''
        px-2.5 py-1.5 rounded-full
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:bg-gray-50 dark:hover:bg-gray-700
        active:bg-primary-50 dark:active:bg-primary-900/30
        active:border-primary-300 dark:active:border-primary-700
      ''',
      child: WText(
        labelKey != null ? trans(labelKey) : (label ?? ''),
        states: active ? {'active'} : {},
        className: '''
          text-xs font-semibold
          text-gray-600 dark:text-gray-300
          active:text-primary-700 dark:active:text-primary-300
        ''',
      ),
    );
  }

  Widget _table(List<_MetricRow> rows) {
    final shellClass = '''
      rounded-xl overflow-hidden
      bg-white dark:bg-gray-800
      border border-gray-200 dark:border-gray-700
    ''';
    final inner = WDiv(
      className: 'flex flex-col w-[760px] tablet:w-full',
      children: [_header(), for (final r in rows) _row(r)],
    );
    return WBreakpoint(
      base: (_) => WDiv(
        className: shellClass,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: inner,
        ),
      ),
      custom: {'tablet': (_) => WDiv(className: shellClass, child: inner)},
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-2
        bg-gray-50 dark:bg-gray-900
        border-b border-gray-200 dark:border-gray-700
        flex flex-row items-center gap-4
      ''',
      children: [
        _headerCell(
          'settings.metrics_library.columns.key',
          width: 'flex-1 min-w-[260px]',
        ),
        _headerCell(
          'settings.metrics_library.columns.type',
          width: 'w-[140px]',
        ),
        _headerCell(
          'settings.metrics_library.columns.group',
          width: 'w-[160px]',
        ),
        _headerCell(
          'settings.metrics_library.columns.usage',
          width: 'w-[120px]',
        ),
      ],
    );
  }

  Widget _headerCell(String labelKey, {required String width}) {
    return WDiv(
      className: width,
      child: WText(
        trans(labelKey),
        className: '''
          text-[10px] font-bold uppercase tracking-wider
          text-gray-500 dark:text-gray-400
        ''',
      ),
    );
  }

  Widget _row(_MetricRow r) {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-center gap-4
      ''',
      children: [
        WDiv(
          className: 'flex-1 min-w-[260px] flex flex-col gap-0.5',
          children: [
            WText(
              r.key,
              className: '''
                text-sm font-mono font-semibold
                text-gray-900 dark:text-white truncate
              ''',
            ),
            WText(
              r.label,
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400 truncate
              ''',
            ),
          ],
        ),
        WDiv(className: 'w-[140px]', child: _typeBadge(r.type, r.unit)),
        WDiv(
          className: 'w-[160px]',
          child: WText(
            r.group,
            className: '''
              text-xs
              text-gray-600 dark:text-gray-300
            ''',
          ),
        ),
        WDiv(
          className: 'w-[120px]',
          child: WText(
            trans('settings.metrics_library.used_by', {'count': '${r.usedBy}'}),
            className: '''
              text-xs font-semibold
              text-gray-700 dark:text-gray-200
            ''',
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(MetricType type, String? unit) {
    return WDiv(
      className: '''
        inline-flex px-2 py-0.5 rounded-full
        bg-gray-100 dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
      ''',
      child: WText(
        unit != null && unit.isNotEmpty ? '${type.name} · $unit' : type.name,
        className: '''
          text-[10px] font-mono font-bold uppercase tracking-wide
          text-gray-600 dark:text-gray-300
        ''',
      ),
    );
  }

  Widget _empty() {
    return const EmptyState(
      icon: Icons.analytics_outlined,
      titleKey: 'settings.metrics_library.empty_title',
      subtitleKey: 'settings.metrics_library.empty_subtitle',
      tone: 'gray',
    );
  }

  List<_MetricRow> _rows() {
    return const [
      _MetricRow(
        key: 'db_conn_ms',
        label: 'DB connection latency',
        type: MetricType.numeric,
        unit: 'ms',
        group: 'Database',
        usedBy: 3,
      ),
      _MetricRow(
        key: 'ssl_days_to_expiry',
        label: 'SSL certificate days to expiry',
        type: MetricType.numeric,
        unit: 'd',
        group: 'SSL',
        usedBy: 5,
      ),
      _MetricRow(
        key: 'queue_depth',
        label: 'Job queue depth',
        type: MetricType.numeric,
        unit: null,
        group: 'Background jobs',
        usedBy: 2,
      ),
      _MetricRow(
        key: 'queue_last_job_ms',
        label: 'Last job runtime',
        type: MetricType.numeric,
        unit: 'ms',
        group: 'Background jobs',
        usedBy: 2,
      ),
      _MetricRow(
        key: 'cache_hit_ratio',
        label: 'CDN cache hit ratio',
        type: MetricType.numeric,
        unit: '%',
        group: 'Performance',
        usedBy: 1,
      ),
      _MetricRow(
        key: 'build_version',
        label: 'Deployed build version',
        type: MetricType.string,
        unit: null,
        group: 'Release',
        usedBy: 4,
      ),
      _MetricRow(
        key: 'payment_gateway_status',
        label: 'Payment gateway status',
        type: MetricType.status,
        unit: null,
        group: 'Upstream',
        usedBy: 1,
      ),
    ];
  }
}

class _MetricRow {
  const _MetricRow({
    required this.key,
    required this.label,
    required this.type,
    required this.unit,
    required this.group,
    required this.usedBy,
  });

  final String key;
  final String label;
  final MetricType type;
  final String? unit;
  final String group;
  final int usedBy;
}
