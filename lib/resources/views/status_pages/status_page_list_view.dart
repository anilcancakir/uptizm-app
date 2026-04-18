import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/status_pages/status_pages_controller.dart';
import '../../../app/models/status_page.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/primary_button.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_block.dart';
import '../components/status_pages/status_page_card.dart';

/// Lists every status page in the workspace as a responsive grid.
class StatusPageListView extends StatefulWidget {
  const StatusPageListView({super.key});

  @override
  State<StatusPageListView> createState() => _StatusPageListViewState();
}

class _StatusPageListViewState extends State<StatusPageListView> {
  StatusPagesController get _c => StatusPagesController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.load());
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 480;
            return AnimatedBuilder(
              animation: _c,
              builder: (_, _) => MagicStarterPageHeader(
                title: trans('status_page.list.title'),
                subtitle: trans('status_page.list.subtitle'),
                inlineActions: true,
                actions: [
                  RefreshIconButton(
                    onTap: _c.load,
                    isRefreshing: _c.rxStatus.isLoading,
                  ),
                  PrimaryButton(
                    labelKey: narrow
                        ? 'status_page.list.create_short'
                        : 'status_page.list.create',
                    icon: Icons.add_rounded,
                    onTap: () => MagicRoute.to('/status-pages/create'),
                  ),
                ],
              ),
            );
          },
        ),
        RefreshIndicator(
          onRefresh: _c.load,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              if (_c.rxStatus.isError) {
                return ErrorBanner(
                  message: _c.rxStatus.message,
                  onRetry: _c.load,
                );
              }
              final pages = _c.pages;
              if (_c.rxStatus.isLoading && pages.isEmpty) {
                return _skeletonGrid();
              }
              if (pages.isEmpty) return _empty();
              return _grid(pages);
            },
          ),
        ),
      ],
    );
  }

  Widget _skeletonGrid() {
    return WDiv(
      className: '''
        grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4
      ''',
      children: [
        for (var i = 0; i < 3; i++)
          WDiv(
            className: '''
              rounded-xl p-4
              bg-white dark:bg-gray-800
              border border-gray-200 dark:border-gray-700
              flex flex-col gap-3
            ''',
            children: const [
              SkeletonBlock(className: 'w-40 h-5'),
              SkeletonBlock(className: 'w-56 h-3.5'),
              SkeletonBlock(className: 'w-full h-24'),
            ],
          ),
      ],
    );
  }

  Widget _grid(List<StatusPage> pages) {
    return WDiv(
      className: '''
        grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4
      ''',
      children: [for (final p in pages) StatusPageCard(page: p)],
    );
  }

  Widget _empty() {
    return EmptyState(
      icon: Icons.public_rounded,
      titleKey: 'status_page.list.empty_title',
      subtitleKey: 'status_page.list.empty_subtitle',
      action: PrimaryButton(
        labelKey: 'status_page.list.create',
        icon: Icons.add_rounded,
        onTap: () => MagicRoute.to('/status-pages/create'),
      ),
    );
  }
}
