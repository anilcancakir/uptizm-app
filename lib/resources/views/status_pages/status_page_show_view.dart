import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/models/mock/status_page.dart';
import '../components/common/app_back_button.dart';
import '../components/common/color_swatch.dart';
import '../components/common/empty_state.dart';
import '../components/common/form_section_card.dart';
import '../components/common/secondary_button.dart';

/// Read-only status-page detail view. Mock data.
class StatusPageShowView extends StatelessWidget {
  const StatusPageShowView({super.key, required this.statusPageId});

  final String statusPageId;

  @override
  Widget build(BuildContext context) {
    final page = StatusPage.findOr404(statusPageId);
    final monitors = StatusPageMonitorOption.mockAll()
        .where((m) => page.monitorIds.contains(m.id))
        .toList();
    final isWide = MediaQuery.of(context).size.width >= 640;

    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/status-pages'),
          title: page.title,
          subtitle: page.subdomain,
          inlineActions: isWide,
          actions: [
            SecondaryButton(
              labelKey: 'status_page.show.open',
              icon: Icons.open_in_new_rounded,
              onTap: () =>
                  Magic.toast('https://${page.subdomain}'),
            ),
            SecondaryButton(
              labelKey: 'status_page.show.edit',
              icon: Icons.edit_rounded,
              onTap: () => Magic.toast(trans('settings.coming_soon')),
            ),
          ],
        ),
        _hero(page, monitors.length, isWide),
        _componentsSection(monitors),
        _incidentsSection(),
      ],
    );
  }

  Widget _hero(StatusPage page, int monitorCount, bool isWide) {
    return WDiv(
      className: isWide
          ? '''
            rounded-xl p-5
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex flex-row gap-5 items-center
          '''
          : '''
            rounded-xl p-5
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex flex-col gap-5 items-start
          ''',
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HexSwatch.parse(page.primaryColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: WText(
            page.initials,
            className: 'text-lg font-bold text-white',
          ),
        ),
        WDiv(
          className: isWide
              ? 'flex-1 flex flex-col gap-2 min-w-0'
              : 'w-full flex flex-col gap-2 min-w-0',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2 flex-wrap',
              children: [
                WText(
                  trans(
                    page.isPublic
                        ? 'status_page.list.public'
                        : 'status_page.list.private',
                  ),
                  className: '''
                    px-2 py-0.5 rounded-full
                    text-[10px] font-bold uppercase tracking-wide
                    bg-gray-100 dark:bg-gray-900
                    text-gray-700 dark:text-gray-200
                  ''',
                ),
                WText(
                  trans('status_page.list.monitor_count')
                      .replaceAll(':count', '$monitorCount'),
                  className: '''
                    px-2 py-0.5 rounded-full
                    text-[10px] font-bold uppercase tracking-wide
                    bg-gray-100 dark:bg-gray-900
                    text-gray-700 dark:text-gray-200
                  ''',
                ),
              ],
            ),
            WText(
              page.subdomain,
              className: '''
                text-sm font-mono
                text-gray-600 dark:text-gray-300
              ''',
            ),
            WText(
              page.primaryColor.toUpperCase(),
              className: '''
                text-xs font-mono
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _componentsSection(List<StatusPageMonitorOption> monitors) {
    return FormSectionCard(
      titleKey: 'status_page.show.components.title',
      subtitleKey: 'status_page.show.components.subtitle',
      icon: Icons.monitor_heart_outlined,
      child: monitors.isEmpty
          ? const EmptyState(
              icon: Icons.monitor_heart_outlined,
              titleKey: 'status_page.show.components.empty_title',
              subtitleKey: 'status_page.show.components.empty',
              tone: 'gray',
              variant: 'plain',
            )
          : WDiv(
              className: 'flex flex-col gap-3',
              children: [
                for (final m in monitors) _componentRow(m),
              ],
            ),
    );
  }

  Widget _componentRow(StatusPageMonitorOption m) {
    return WDiv(
      className: 'flex flex-row items-center gap-3',
      children: [
        WDiv(
          states: {m.statusTone},
          className: '''
            w-2 h-2 rounded-full
            up:bg-up-500 dark:up:bg-up-400
            down:bg-down-500 dark:down:bg-down-400
            degraded:bg-degraded-500 dark:degraded:bg-degraded-400
            paused:bg-paused-400 dark:paused:bg-paused-300
          ''',
        ),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            m.name,
            className: '''
              text-sm font-semibold
              text-gray-900 dark:text-white
              truncate
            ''',
          ),
        ),
        WDiv(
          className: 'flex flex-row items-center gap-0.5',
          children: [
            for (var i = 0; i < 20; i++) _segment(i, m.statusTone),
          ],
        ),
      ],
    );
  }

  Widget _segment(int index, String tone) {
    final missing = (index == 6 && tone == 'degraded') ||
        (index == 13 && tone == 'down');
    return WDiv(
      states: {missing ? 'down' : tone},
      className: '''
        w-1.5 h-5 rounded-sm
        up:bg-up-400 dark:up:bg-up-500
        down:bg-down-500 dark:down:bg-down-400
        degraded:bg-degraded-400 dark:degraded:bg-degraded-500
        paused:bg-paused-300 dark:paused:bg-paused-500
      ''',
    );
  }

  Widget _incidentsSection() {
    return FormSectionCard(
      titleKey: 'status_page.show.incidents_30d.title',
      subtitleKey: 'status_page.show.incidents_30d.subtitle',
      icon: Icons.report_problem_rounded,
      child: WDiv(
        className: 'flex flex-col gap-2',
        children: [
          _incidentLine(
            trans('status_page.show.incidents_30d.sample_1'),
            '3d ago',
          ),
          _incidentLine(
            trans('status_page.show.incidents_30d.sample_2'),
            '11d ago',
          ),
        ],
      ),
    );
  }

  Widget _incidentLine(String title, String when) {
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
        px-3 py-2 rounded-lg
        bg-gray-50 dark:bg-gray-900
      ''',
      children: [
        WDiv(
          className: 'w-2 h-2 rounded-full bg-up-500 dark:bg-up-400',
        ),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            title,
            className: '''
              text-sm
              text-gray-800 dark:text-gray-100
              truncate
            ''',
          ),
        ),
        WText(
          when,
          className: '''
            text-xs
            text-gray-500 dark:text-gray-400
          ''',
        ),
      ],
    );
  }
}
