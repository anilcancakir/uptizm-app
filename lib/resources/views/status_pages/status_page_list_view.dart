import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/models/mock/status_page.dart';
import '../components/common/empty_state.dart';
import '../components/common/primary_button.dart';
import '../components/status_pages/status_page_card.dart';

/// Lists every status page in the workspace as a responsive grid.
class StatusPageListView extends StatelessWidget {
  const StatusPageListView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = StatusPage.mockAll();
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          title: trans('status_page.list.title'),
          subtitle: trans('status_page.list.subtitle'),
          actions: [
            PrimaryButton(
              labelKey: 'status_page.list.create',
              icon: Icons.add_rounded,
              onTap: () => MagicRoute.to('/status-pages/create'),
            ),
          ],
        ),
        if (pages.isEmpty)
          _empty()
        else
          WDiv(
            className: '''
              grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4
            ''',
            children: [for (final p in pages) StatusPageCard(page: p)],
          ),
      ],
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
