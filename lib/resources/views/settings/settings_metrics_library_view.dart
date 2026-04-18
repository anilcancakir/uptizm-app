import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/metrics/metrics_library_controller.dart';
import '../../../app/enums/metric_type.dart';
import '../../../app/models/monitor_metric.dart';
import '../components/common/app_back_button.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';

/// Workspace-wide metrics library.
///
/// Flat, read-only list of every custom metric declared across the
/// team's monitors. Powered by [MetricsLibraryController]; editing still
/// happens on the owning monitor's metrics tab.
class SettingsMetricsLibraryView
    extends MagicStatefulView<MetricsLibraryController> {
  const SettingsMetricsLibraryView({super.key});

  @override
  State<SettingsMetricsLibraryView> createState() =>
      _SettingsMetricsLibraryViewState();
}

class _SettingsMetricsLibraryViewState
    extends
        MagicStatefulViewState<
          MetricsLibraryController,
          SettingsMetricsLibraryView
        > {
  MetricType? _typeFilter;
  String? _groupFilter;

  @override
  void onInit() {
    super.onInit();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (_, _) => MagicStarterPageHeader(
            leading: const AppBackButton(fallbackPath: '/'),
            title: trans('settings.metrics_library.title'),
            subtitle: trans('settings.metrics_library.subtitle'),
            inlineActions: true,
            actions: [
              RefreshIconButton(
                onTap: controller.load,
                isRefreshing: controller.rxStatus.isLoading,
              ),
            ],
          ),
        ),
        RefreshIndicator(
          onRefresh: controller.load,
          child: controller.renderState(
            (metrics) => _body(metrics),
            onLoading: const SkeletonRowList(),
            onEmpty: _empty(),
            onError: (msg) =>
                ErrorBanner(message: msg, onRetry: controller.load),
          ),
        ),
      ],
    );
  }

  Widget _body(List<MonitorMetric> metrics) {
    final groups = metrics
        .map((m) => m.groupName ?? '')
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    final filtered = metrics
        .where((m) => _typeFilter == null || m.type == _typeFilter)
        .where((m) => _groupFilter == null || m.groupName == _groupFilter)
        .toList();

    return WDiv(
      className: 'flex flex-col gap-4',
      children: [
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

  Widget _table(List<MonitorMetric> rows) {
    final shellClass = '''
      rounded-xl overflow-hidden
      bg-white dark:bg-gray-800
      border border-gray-200 dark:border-gray-700
    ''';
    return WDiv(
      className: shellClass,
      child: WDiv(
        className: 'flex flex-col w-full',
        children: [_header(), for (final r in rows) _row(r)],
      ),
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 py-2
        bg-gray-50 dark:bg-gray-900
        border-b border-gray-200 dark:border-gray-700
        flex flex-row items-center gap-3
      ''',
      children: [
        _headerCell(
          'settings.metrics_library.columns.key',
          width: 'flex-1 min-w-0',
        ),
        _headerCell(
          'settings.metrics_library.columns.type',
          width: 'w-[96px] flex-shrink-0',
        ),
        WBreakpoint(
          base: (_) => const SizedBox.shrink(),
          custom: {
            'tablet': (_) => _headerCell(
              'settings.metrics_library.columns.group',
              width: 'w-[140px] flex-shrink-0',
            ),
          },
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

  Widget _row(MonitorMetric r) {
    return WDiv(
      className: '''
        px-4 py-3
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-center gap-3
      ''',
      children: [
        WDiv(
          className: 'flex-1 min-w-0 flex flex-col gap-0.5',
          children: [
            WText(
              r.key ?? '',
              className: '''
                text-sm font-mono font-semibold
                text-gray-900 dark:text-white truncate
              ''',
            ),
            WText(
              r.label ?? '',
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400 truncate
              ''',
            ),
          ],
        ),
        WDiv(
          className: 'w-[96px] flex-shrink-0',
          child: _typeBadge(r.type ?? MetricType.numeric, r.unit),
        ),
        WBreakpoint(
          base: (_) => const SizedBox.shrink(),
          custom: {
            'tablet': (_) => WDiv(
              className: 'w-[140px] flex-shrink-0',
              child: WText(
                r.groupName ?? '—',
                className: '''
                  text-xs
                  text-gray-600 dark:text-gray-300
                ''',
              ),
            ),
          },
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
}
