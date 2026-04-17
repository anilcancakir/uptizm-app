import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/models/mock/status_page.dart';
import '../common/color_swatch.dart';

/// Card shown on the status-page list grid. Click navigates to the show view.
class StatusPageCard extends StatelessWidget {
  const StatusPageCard({super.key, required this.page});

  final StatusPage page;

  @override
  Widget build(BuildContext context) {
    return WButton(
      onTap: () => MagicRoute.to('/status-pages/${page.id}'),
      className: '''
        w-full p-4 rounded-xl
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:border-primary-400 dark:hover:border-primary-500
        flex flex-col gap-4
      ''',
      child: WDiv(
        className: 'flex flex-col gap-4 w-full',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-3 w-full',
            children: [
              _logo(),
              WDiv(
                className: 'flex-1 flex flex-col gap-0.5 min-w-0',
                children: [
                  WText(
                    page.title,
                    className: '''
                      text-base font-bold
                      text-gray-900 dark:text-white
                      truncate
                    ''',
                  ),
                  WText(
                    page.subdomain,
                    className: '''
                      text-xs font-mono
                      text-gray-500 dark:text-gray-400
                      truncate
                    ''',
                  ),
                ],
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-row items-center gap-2 flex-wrap',
            children: [
              _pill(
                label: trans(
                  'status_page.list.monitor_count',
                ).replaceAll(':count', '${page.monitorIds.length}'),
                toneClass:
                    'bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-200',
              ),
              _pill(
                label: trans(
                  page.isPublic
                      ? 'status_page.list.public'
                      : 'status_page.list.private',
                ),
                toneClass: page.isPublic
                    ? 'bg-up-50 dark:bg-up-900/30 text-up-700 dark:text-up-400'
                    : 'bg-paused-100 dark:bg-paused-800/40 text-paused-700 dark:text-paused-200',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return HexSwatch(
      hex: page.primaryColor,
      dimension: 48,
      radius: 8,
      child: WText(page.initials, className: 'text-sm font-bold text-white'),
    );
  }

  Widget _pill({required String label, required String toneClass}) {
    return WDiv(
      className:
          '''
        px-2 py-0.5 rounded-full
        $toneClass
      ''',
      child: WText(
        label,
        className: 'text-[10px] font-bold uppercase tracking-wide',
      ),
    );
  }
}
