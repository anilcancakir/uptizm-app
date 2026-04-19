import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_status.dart';
import '../../../../app/models/monitor_check.dart';

/// Bottom sheet showing a single check's request, response and timing
/// breakdown. Sourced from GET /monitors/{id}/checks.
class CheckDetailSheet extends StatelessWidget {
  const CheckDetailSheet({super.key, required this.check});

  final MonitorCheck check;

  static Future<void> show(BuildContext context, MonitorCheck check) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckDetailSheet(check: check),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
            _grabber(),
            _header(),
            WDiv(
              className: 'flex-1 overflow-y-auto',
              scrollPrimary: true,
              children: [
                WDiv(
                  className: 'p-4 flex flex-col gap-4',
                  children: [_timingCard(), _requestCard(), _responseCard()],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _grabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: 'w-10 h-1 rounded-full bg-gray-300 dark:bg-gray-600',
      ),
    );
  }

  Widget _header() {
    final status = check.status;
    final tone = status?.toneKey ?? 'paused';
    final method = (check.method ?? 'GET').toUpperCase();
    return WDiv(
      className: '''
        px-4 pb-4
        border-b border-gray-100 dark:border-gray-800
        flex flex-row items-start gap-3
      ''',
      children: [
        WDiv(
          states: {tone},
          className: '''
            w-9 h-9 rounded-lg
            flex items-center justify-center
            up:bg-up-50 dark:up:bg-up-900/30
            down:bg-down-50 dark:down:bg-down-900/30
            degraded:bg-degraded-50 dark:degraded:bg-degraded-900/30
            paused:bg-paused-100 dark:paused:bg-paused-800
          ''',
          child: WIcon(
            _headerIcon(status),
            states: {tone},
            className: '''
              text-base
              up:text-up-600 dark:up:text-up-400
              down:text-down-600 dark:down:text-down-400
              degraded:text-degraded-600 dark:degraded:text-degraded-400
              paused:text-paused-500 dark:paused:text-paused-300
            ''',
          ),
        ),
        WDiv(
          className: 'flex-1 flex flex-col gap-1 min-w-0',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2 flex-wrap',
              children: [
                WText(
                  '$method ${check.statusCode ?? '--'}',
                  className: '''
                    text-base font-bold font-mono
                    text-gray-900 dark:text-white
                  ''',
                ),
                if (check.region != null)
                  WDiv(
                    className: '''
                      px-2 py-0.5 rounded-full
                      bg-gray-100 dark:bg-gray-800
                    ''',
                    child: WText(
                      check.region!,
                      className: '''
                        text-[10px] font-bold font-mono uppercase
                        text-gray-600 dark:text-gray-300
                      ''',
                    ),
                  ),
                if (check.responseMs != null)
                  WText(
                    '${check.responseMs} ms',
                    className: '''
                      text-xs font-mono
                      text-gray-500 dark:text-gray-400
                    ''',
                  ),
              ],
            ),
            if (check.url != null)
              WText(
                check.url!,
                className: '''
                  text-xs font-mono truncate
                  text-gray-500 dark:text-gray-400
                ''',
              ),
            if (check.errorMessage != null)
              WText(
                check.errorMessage!,
                className: '''
                  text-xs
                  text-down-600 dark:text-down-400
                ''',
              ),
          ],
        ),
      ],
    );
  }

  IconData _headerIcon(MonitorStatus? s) {
    return switch (s) {
      MonitorStatus.up => Icons.check_rounded,
      MonitorStatus.down => Icons.close_rounded,
      MonitorStatus.degraded => Icons.warning_amber_rounded,
      MonitorStatus.paused => Icons.pause_rounded,
      null => Icons.help_outline_rounded,
    };
  }

  Widget _timingCard() {
    final t = check.timing;
    final total = t.totalMs == 0 ? 1 : t.totalMs;
    const segmentClass = '''
      dns:bg-info-300 dark:dns:bg-info-400
      connect:bg-info-400 dark:connect:bg-info-500
      tls:bg-primary-300 dark:tls:bg-primary-400
      ttfb:bg-primary-500 dark:ttfb:bg-primary-600
      download:bg-primary-700 dark:download:bg-primary-500
    ''';
    final segments = <(String, int, String)>[
      ('monitor.check_detail.timing.dns', t.dnsMs, 'dns'),
      ('monitor.check_detail.timing.connect', t.connectMs, 'connect'),
      ('monitor.check_detail.timing.tls', t.tlsMs, 'tls'),
      ('monitor.check_detail.timing.ttfb', t.ttfbMs, 'ttfb'),
      ('monitor.check_detail.timing.download', t.downloadMs, 'download'),
    ];

    return _card(
      titleKey: 'monitor.check_detail.timing.title',
      icon: Icons.speed_rounded,
      child: WDiv(
        className: 'flex flex-col gap-3',
        children: [
          WDiv(
            className: '''
              h-2 rounded-full overflow-hidden
              bg-gray-100 dark:bg-gray-800
              flex flex-row
            ''',
            children: [
              for (final s in segments)
                if (s.$2 > 0)
                  WDiv(
                    states: {s.$3},
                    className:
                        'flex-${((s.$2 / total) * 1000).round().clamp(1, 1000)} $segmentClass',
                  ),
            ],
          ),
          WDiv(
            className: 'flex flex-row flex-wrap gap-x-4 gap-y-1',
            children: [
              for (final s in segments)
                WDiv(
                  className: 'flex flex-row items-center gap-1.5',
                  children: [
                    WDiv(
                      states: {s.$3},
                      className: 'w-2 h-2 rounded-full $segmentClass',
                    ),
                    WText(
                      trans(s.$1),
                      className: 'text-xs text-gray-600 dark:text-gray-300',
                    ),
                    WText(
                      '${s.$2}ms',
                      className: '''
                        text-xs font-mono font-semibold
                        text-gray-900 dark:text-white
                      ''',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestCard() {
    final method = (check.method ?? 'GET').toUpperCase();
    return _card(
      titleKey: 'monitor.check_detail.request.title',
      icon: Icons.outbound_rounded,
      child: WDiv(
        className: 'flex flex-col gap-2',
        children: [
          _kv('Method', method),
          if (check.url != null) _kv('URL', check.url!),
          if (check.requestHeaders.isNotEmpty)
            _headerBlock(check.requestHeaders),
        ],
      ),
    );
  }

  Widget _responseCard() {
    return _card(
      titleKey: 'monitor.check_detail.response.title',
      icon: Icons.inbox_rounded,
      child: WDiv(
        className: 'flex flex-col gap-2',
        children: [
          _kv('Status', '${check.statusCode ?? '--'}'),
          if (check.responseMs != null)
            _kv('Duration', '${check.responseMs} ms'),
          if (check.responseHeaders.isNotEmpty)
            _headerBlock(check.responseHeaders),
          if (check.responseBodyPreview != null)
            _bodyBlock(check.responseBodyPreview!),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return WDiv(
      className: 'flex flex-row items-start gap-3',
      children: [
        WDiv(
          className: 'w-20',
          child: WText(
            k,
            className: '''
              text-xs font-semibold uppercase tracking-wide
              text-gray-500 dark:text-gray-400
            ''',
          ),
        ),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            v,
            selectable: true,
            className: '''
              text-xs font-mono
              text-gray-800 dark:text-gray-100
            ''',
          ),
        ),
      ],
    );
  }

  Widget _headerBlock(Map<String, String> headers) {
    return WDiv(
      className: '''
        rounded-lg p-3
        bg-gray-50 dark:bg-gray-800/50
        border border-gray-100 dark:border-gray-800
        flex flex-col gap-1
      ''',
      children: [
        for (final e in headers.entries)
          WDiv(
            className: 'flex flex-row gap-2',
            children: [
              WText(
                '${e.key}:',
                selectable: true,
                className: '''
                  text-xs font-mono font-semibold
                  text-gray-600 dark:text-gray-300
                ''',
              ),
              WDiv(
                className: 'flex-1 min-w-0',
                child: WText(
                  e.value,
                  selectable: true,
                  className: '''
                    text-xs font-mono
                    text-gray-800 dark:text-gray-100
                  ''',
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _bodyBlock(String body) {
    return WDiv(
      className: '''
        rounded-lg p-3
        bg-gray-900 dark:bg-black
        flex flex-col
      ''',
      child: WText(
        body,
        selectable: true,
        className: 'text-xs font-mono text-gray-100',
      ),
    );
  }

  Widget _card({
    required String titleKey,
    required IconData icon,
    required Widget child,
  }) {
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
            flex flex-row items-center gap-2
          ''',
          children: [
            WIcon(icon, className: 'text-sm text-gray-500 dark:text-gray-400'),
            WText(
              trans(titleKey),
              className: '''
                text-xs font-bold uppercase tracking-wider
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
        WDiv(className: 'p-4', child: child),
      ],
    );
  }
}
