import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/status_pages/status_pages_controller.dart';
import '../../../app/models/status_page.dart';
import '../components/common/app_back_button.dart';
import '../components/common/color_swatch.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/form_section_card.dart';
import '../components/common/primary_button.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/secondary_button.dart';
import '../components/common/skeleton_block.dart';

/// Status-page detail view. Hydrates from the API via
/// `StatusPagesController.loadOne`.
class StatusPageShowView extends StatefulWidget {
  const StatusPageShowView({super.key, required this.statusPageId});

  final String statusPageId;

  @override
  State<StatusPageShowView> createState() => _StatusPageShowViewState();
}

class _StatusPageShowViewState extends State<StatusPageShowView> {
  StatusPagesController get _c => StatusPagesController.instance;

  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _c.loadOne(widget.statusPageId),
    );
  }

  Future<void> _refresh() => _c.loadOne(widget.statusPageId);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final page = _c.detail;
          if (_c.rxStatus.isError && page == null) {
            return WDiv(
              className: 'p-4 lg:p-6',
              child: ErrorBanner(
                message: _c.rxStatus.message,
                onRetry: _refresh,
              ),
            );
          }
          if (_c.rxStatus.isLoading && page == null) {
            return _skeleton();
          }
          if (page == null) {
            return const WDiv(
              className: 'p-6',
              child: EmptyState(
                icon: Icons.public_rounded,
                titleKey: 'status_page.show.missing_title',
                subtitleKey: 'status_page.show.missing_subtitle',
              ),
            );
          }
          return _body(page);
        },
      ),
    );
  }

  Widget _skeleton() {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: const [
        SkeletonBlock(className: 'w-1/3 h-6'),
        SkeletonBlock(className: 'w-full h-32 rounded-xl'),
        SkeletonBlock(className: 'w-full h-40 rounded-xl'),
      ],
    );
  }

  Widget _body(StatusPage page) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/status-pages'),
          title: page.title,
          subtitle: page.subdomain,
          actions: [
            RefreshIconButton(
              onTap: _refresh,
              isRefreshing: _c.rxStatus.isLoading,
            ),
            SecondaryButton(
              labelKey: 'status_page.show.open',
              icon: Icons.open_in_new_rounded,
              onTap: () => Launch.url(page.publicUrl),
            ),
            SecondaryButton(
              labelKey: 'status_page.show.edit',
              icon: Icons.edit_rounded,
              onTap: () => MagicRoute.to('/status-pages/${page.id}/edit'),
            ),
            if (!page.isPublic && page.previewUrl != null)
              SecondaryButton(
                labelKey: 'status_page.show.open_preview',
                icon: Icons.visibility_outlined,
                onTap: () => Launch.url(page.previewUrl!),
              ),
            if (Gate.allows('status-pages.publish', page))
              PrimaryButton(
                labelKey: page.isPublic
                    ? 'status_page.show.unpublish'
                    : 'status_page.show.publish',
                icon: Icons.public_rounded,
                isLoading: _publishing,
                onTap: () => _onPublishToggle(page),
              ),
          ],
        ),
        if (!page.isPublic) _previewBanner(),
        _hero(page),
        _componentsSection(page.monitors),
        if (page.metrics.isNotEmpty) _metricsSection(page.metrics),
      ],
    );
  }

  Future<void> _onPublishToggle(StatusPage page) async {
    if (_publishing) return;
    setState(() => _publishing = true);
    final ok = page.isPublic
        ? await _c.unpublish(page.id)
        : await _c.publish(page.id);
    if (!mounted) return;
    setState(() => _publishing = false);
    if (!ok) {
      Magic.toast(
        trans(
          page.isPublic
              ? 'status_page.errors.generic_unpublish'
              : 'status_page.errors.generic_publish',
        ),
      );
      return;
    }
    Magic.toast(
      trans(
        page.isPublic
            ? 'status_page.show.unpublish_success'
            : 'status_page.show.published_toast',
      ),
    );
  }

  Widget _previewBanner() {
    return WDiv(
      className: '''
        rounded-lg px-4 py-3
        bg-amber-50 dark:bg-amber-900/20
        border border-amber-200 dark:border-amber-800
      ''',
      child: WText(
        trans('status_page.show.preview_mode_banner'),
        className: '''
          text-sm font-semibold
          text-amber-800 dark:text-amber-200
        ''',
      ),
    );
  }

  Widget _metricsSection(List<StatusPageMetric> metrics) {
    return FormSectionCard(
      titleKey: 'status_page.show.metrics.title',
      subtitleKey: 'status_page.show.metrics.subtitle',
      icon: Icons.insights_rounded,
      child: WDiv(
        className: 'flex flex-col gap-3',
        children: [for (final m in metrics) _metricRow(m)],
      ),
    );
  }

  Widget _metricRow(StatusPageMetric m) {
    final value = m.latestNumericValue != null
        ? '${m.latestNumericValue}${m.unit ?? ''}'
        : m.latestStringValue ?? '—';
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
      ''',
      children: [
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            m.displayLabel,
            className: '''
              text-sm font-semibold
              text-gray-900 dark:text-white
              truncate
            ''',
          ),
        ),
        WText(
          value,
          className: '''
            text-sm font-mono
            text-gray-700 dark:text-gray-200
          ''',
        ),
      ],
    );
  }

  Widget _hero(StatusPage page) {
    final monitorCount = page.monitors.length;
    return WDiv(
      className: '''
        rounded-xl p-5
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-5 items-start
        sm:flex-row sm:items-center
      ''',
      children: [
        HexSwatch(
          hex: page.primaryColor,
          dimension: 64,
          radius: 12,
          child: WText(
            page.initials,
            className: 'text-lg font-bold text-white',
          ),
        ),
        WDiv(
          className: 'w-full sm:flex-1 flex flex-col gap-2 min-w-0',
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
                  trans(
                    'status_page.list.monitor_count',
                  ).replaceAll(':count', '$monitorCount'),
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

  Widget _componentsSection(List<StatusPageMonitor> monitors) {
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
              children: [for (final m in monitors) _componentRow(m)],
            ),
    );
  }

  Widget _componentRow(StatusPageMonitor m) {
    final tone = m.lastStatus.toneKey;
    return WDiv(
      className: 'flex flex-row items-center gap-3',
      children: [
        WDiv(
          states: {tone},
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
            m.label,
            className: '''
              text-sm font-semibold
              text-gray-900 dark:text-white
              truncate
            ''',
          ),
        ),
      ],
    );
  }
}
