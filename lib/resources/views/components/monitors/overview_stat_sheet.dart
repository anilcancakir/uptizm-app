import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/controllers/monitors/monitor_series_controller.dart';
import '../../../../app/controllers/monitors/monitor_summary_controller.dart';
import '../../../../app/models/response_time_sample.dart';
import 'response_sparkline.dart';

/// Drill-down sheet for an Overview KPI card. `uptime` variant shows the
/// check band strip plus current vs. previous uptime ratio; `response`
/// shows a response-time sparkline plus min / max / avg over the current
/// range. Both variants reuse the controllers already hydrated by the
/// show screen, so the sheet itself does no fetching.
enum OverviewStatVariant { uptime, response }

/// Bottom-sheet expansion of the monitor-show Uptime / Response stat cards.
/// Read-only; use [OverviewStatSheet.show] to present it.
class OverviewStatSheet extends StatelessWidget {
  const OverviewStatSheet({super.key, required this.variant});

  final OverviewStatVariant variant;

  static Future<void> show(
    BuildContext context, {
    required OverviewStatVariant variant,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OverviewStatSheet(variant: variant),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return WDiv(
          className: '''
            rounded-t-2xl
            bg-white dark:bg-gray-900
            border-t border-gray-200 dark:border-gray-700
            flex flex-col h-full
          ''',
          children: [
            _grabber(),
            _header(),
            WDiv(
              className:
                  'flex-1 overflow-y-auto p-4 lg:p-6 flex flex-col gap-4',
              scrollPrimary: true,
              children: [_body()],
            ),
          ],
        );
      },
    );
  }

  Widget _body() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        MonitorSeriesController.instance,
        MonitorSummaryController.instance,
      ]),
      builder: (_, _) {
        final samples = MonitorSeriesController.instance.samples;
        final summary = MonitorSummaryController.instance.summary;
        return variant == OverviewStatVariant.uptime
            ? _uptimeBody(
                samples,
                summary?.uptimeRatio,
                summary?.previousUptimeRatio,
              )
            : _responseBody(
                samples,
                summary?.avgResponseMs,
                summary?.previousAvgResponseMs,
              );
      },
    );
  }

  Widget _uptimeBody(
    List<ResponseTimeSample> samples,
    double? current,
    double? previous,
  ) {
    final up = samples.where((s) => s.status.name == 'up').length;
    final down = samples.where((s) => s.status.name == 'down').length;
    final degraded = samples.where((s) => s.status.name == 'degraded').length;
    return WDiv(
      className: 'flex flex-col gap-4',
      children: [
        _bigValue(
          current == null ? '—' : '${(current * 100).toStringAsFixed(2)}%',
          _deltaText(current, previous, asPercentPoints: true),
          _isGoodDelta(current, previous, higherIsBetter: true),
        ),
        if (samples.isNotEmpty) _bandStrip(samples),
        _statRow([
          ('monitor.overview_sheet.previous', _fmtRatio(previous)),
          ('monitor.overview_sheet.up', up.toString()),
          ('monitor.overview_sheet.down', down.toString()),
          ('monitor.overview_sheet.degraded', degraded.toString()),
        ]),
      ],
    );
  }

  Widget _responseBody(
    List<ResponseTimeSample> samples,
    int? current,
    int? previous,
  ) {
    final ms = [for (final s in samples) s.responseMs];
    final min = ms.isEmpty ? null : ms.reduce((a, b) => a < b ? a : b);
    final max = ms.isEmpty ? null : ms.reduce((a, b) => a > b ? a : b);
    final avg = ms.isEmpty
        ? null
        : (ms.reduce((a, b) => a + b) / ms.length).round();
    final currentNum = current?.toDouble();
    final previousNum = previous?.toDouble();
    return WDiv(
      className: 'flex flex-col gap-4',
      children: [
        _bigValue(
          current == null ? '—' : '${current}ms',
          _deltaText(currentNum, previousNum, asPercentPoints: false),
          _isGoodDelta(currentNum, previousNum, higherIsBetter: false),
        ),
        if (samples.isNotEmpty)
          ResponseSparkline(
            heightPx: 140,
            samples: [
              for (final s in samples)
                ResponseSample(
                  timestamp: s.checkedAt,
                  responseMs: s.responseMs,
                  status: s.status,
                ),
            ],
          ),
        _statRow([
          (
            'monitor.overview_sheet.previous',
            previous == null ? '—' : '${previous}ms',
          ),
          ('monitor.overview_sheet.min', min == null ? '—' : '${min}ms'),
          ('monitor.overview_sheet.max', max == null ? '—' : '${max}ms'),
          ('monitor.overview_sheet.avg', avg == null ? '—' : '${avg}ms'),
        ]),
      ],
    );
  }

  Widget _bandStrip(List<ResponseTimeSample> samples) {
    return WDiv(
      className: 'flex flex-row gap-0.5 h-8 items-stretch',
      children: [
        for (final s in samples)
          WDiv(
            states: {s.status.name},
            className: '''
              flex-1 rounded-sm
              bg-gray-300 dark:bg-gray-700
              up:bg-up-500 dark:up:bg-up-400
              down:bg-down-500 dark:down:bg-down-400
              degraded:bg-degraded-500 dark:degraded:bg-degraded-400
              paused:bg-paused-400 dark:paused:bg-paused-500
            ''',
          ),
      ],
    );
  }

  Widget _bigValue(String value, String? delta, bool? isGood) {
    return WDiv(
      className: 'flex flex-row items-baseline gap-3',
      children: [
        WText(
          value,
          className: '''
            text-3xl font-bold
            text-gray-900 dark:text-white
          ''',
        ),
        if (delta != null)
          WDiv(
            states: {
              if (isGood == true)
                'good'
              else if (isGood == false)
                'bad'
              else
                'flat',
            },
            className: '''
              flex flex-row items-center gap-1
              px-2 py-0.5 rounded-full
              bg-gray-100 dark:bg-gray-800
              good:bg-up-50 dark:good:bg-up-900/30
              bad:bg-down-50 dark:bad:bg-down-900/30
              good:text-up-600 dark:good:text-up-400
              bad:text-down-600 dark:bad:text-down-400
              flat:text-gray-500 dark:flat:text-gray-400
            ''',
            children: [WText(delta, className: 'text-xs font-semibold')],
          ),
      ],
    );
  }

  Widget _statRow(List<(String, String)> entries) {
    return WDiv(
      className: '''
        grid grid-cols-2 sm:grid-cols-4 gap-3
        rounded-lg p-3
        bg-gray-50 dark:bg-gray-800/60
      ''',
      children: [
        for (final e in entries)
          WDiv(
            className: 'flex flex-col gap-1',
            children: [
              WText(
                trans(e.$1),
                className: '''
                  text-[10px] font-semibold uppercase tracking-wide
                  text-gray-500 dark:text-gray-400
                ''',
              ),
              WText(
                e.$2,
                className: '''
                  text-sm font-mono font-semibold
                  text-gray-900 dark:text-white
                ''',
              ),
            ],
          ),
      ],
    );
  }

  String _fmtRatio(double? r) =>
      r == null ? '—' : '${(r * 100).toStringAsFixed(2)}%';

  String? _deltaText(
    double? current,
    double? previous, {
    required bool asPercentPoints,
  }) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (asPercentPoints) {
      final pct = diff * 100;
      if (pct.abs() < 0.01) return '0.0pp';
      return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}pp';
    }
    if (previous == 0) return null;
    final pct = (diff / previous.abs()) * 100;
    if (pct.abs() < 0.1) return '0%';
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
  }

  bool? _isGoodDelta(
    double? current,
    double? previous, {
    required bool higherIsBetter,
  }) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (diff.abs() < 1e-9) return null;
    final increased = diff > 0;
    return higherIsBetter ? increased : !increased;
  }

  Widget _header() {
    final titleKey = variant == OverviewStatVariant.uptime
        ? 'monitor.overview_sheet.uptime_title'
        : 'monitor.overview_sheet.response_title';
    return WDiv(
      className: '''
        px-4 lg:px-6 pb-3
        flex flex-row items-center gap-3
        border-b border-gray-200 dark:border-gray-800
      ''',
      children: [
        WText(
          trans(titleKey),
          className: '''
            flex-1 text-lg font-bold
            text-gray-900 dark:text-white truncate
          ''',
        ),
        WButton(
          onTap: () => MagicRoute.back(),
          className: '''
            w-9 h-9 rounded-lg
            bg-gray-100 dark:bg-gray-800
            hover:bg-gray-200 dark:hover:bg-gray-700
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.close_rounded,
            className: 'text-base text-gray-600 dark:text-gray-300',
          ),
        ),
      ],
    );
  }

  Widget _grabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: '''
          w-10 h-1 rounded-full
          bg-gray-300 dark:bg-gray-700
        ''',
      ),
    );
  }
}
