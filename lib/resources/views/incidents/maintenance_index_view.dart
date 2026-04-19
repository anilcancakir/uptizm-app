import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/incidents/maintenance_controller.dart';
import '../../../app/enums/incident_status.dart';
import '../../../app/models/incident.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';
import '../components/incidents/incident_status_pill.dart';

/// Scheduled-maintenance index.
///
/// Three lanes (`upcoming`, `in_progress`, `history`) filter the shared
/// `/maintenance` feed client-side so the operator can switch tabs
/// without re-fetching. Scheduled windows flow through the
/// `scheduled -> in_progress -> verifying -> completed` lifecycle on
/// the server; the lane buckets collapse those onto the three obvious
/// operator states.
class MaintenanceIndexView extends MagicStatefulView<MaintenanceController> {
  const MaintenanceIndexView({super.key});

  @override
  State<MaintenanceIndexView> createState() => _MaintenanceIndexViewState();
}

enum _Lane { upcoming, inProgress, history }

class _MaintenanceIndexViewState
    extends
        MagicStatefulViewState<MaintenanceController, MaintenanceIndexView> {
  _Lane _lane = _Lane.upcoming;

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
            title: trans('maintenance.list.title'),
            subtitle: trans('maintenance.list.subtitle'),
            inlineActions: true,
            actions: [
              WButton(
                onTap: () => MagicRoute.to('/maintenance/create'),
                className: '''
                  px-3 py-2 rounded-lg
                  bg-primary-600 dark:bg-primary-500
                  hover:bg-primary-700 dark:hover:bg-primary-400
                ''',
                child: WText(
                  trans('maintenance.schedule.submit'),
                  className: 'text-xs font-semibold text-white',
                ),
              ),
              RefreshIconButton(
                onTap: controller.load,
                isRefreshing: controller.rxStatus.isLoading,
              ),
            ],
          ),
        ),
        _laneTabs(),
        RefreshIndicator(
          onRefresh: controller.load,
          child: controller.renderState(
            (windows) => _body(_filter(windows)),
            onLoading: const SkeletonRowList(),
            onEmpty: _empty(),
            onError: (msg) =>
                ErrorBanner(message: msg, onRetry: controller.load),
          ),
        ),
      ],
    );
  }

  List<Incident> _filter(List<Incident> all) {
    return switch (_lane) {
      _Lane.upcoming =>
        all.where((w) => w.status == IncidentStatus.scheduled).toList(),
      _Lane.inProgress =>
        all
            .where(
              (w) =>
                  w.status == IncidentStatus.inProgress ||
                  w.status == IncidentStatus.verifying,
            )
            .toList(),
      _Lane.history =>
        all.where((w) => w.status == IncidentStatus.completed).toList(),
    };
  }

  Widget _laneTabs() {
    return WDiv(
      className: '''
        flex flex-row gap-1 p-1 rounded-lg
        bg-subtle dark:bg-subtle-dark
        border border-subtle dark:border-subtle-dark
      ''',
      children: [for (final lane in _Lane.values) _laneButton(lane)],
    );
  }

  Widget _laneButton(_Lane lane) {
    final isActive = _lane == lane;
    final key = switch (lane) {
      _Lane.upcoming => 'upcoming',
      _Lane.inProgress => 'in_progress',
      _Lane.history => 'history',
    };
    return WDiv(
      className: 'flex-1',
      child: WButton(
        onTap: () => setState(() => _lane = lane),
        states: isActive ? {'active'} : {},
        className: '''
          w-full px-3 py-2 rounded-md
          hover:bg-white/60 dark:hover:bg-gray-800/60
          active:bg-white dark:active:bg-gray-800
          active:shadow-sm
          flex flex-row items-center justify-center
        ''',
        child: WText(
          trans('maintenance.tab.$key'),
          states: isActive ? {'active'} : {},
          className: '''
            text-xs font-semibold
            text-muted dark:text-muted-dark
            active:text-gray-900 dark:active:text-white
          ''',
        ),
      ),
    );
  }

  Widget _body(List<Incident> windows) {
    if (windows.isEmpty) return _empty();
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [for (final w in windows) _row(w)],
    );
  }

  Widget _row(Incident window) {
    return WButton(
      onTap: () => MagicRoute.to('/maintenance/${window.id}'),
      className: '''
        px-4 py-3 rounded-lg border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        hover:border-primary-300 dark:hover:border-primary-600
        flex flex-col gap-2 items-stretch
      ''',
      child: WDiv(
        className: 'flex flex-col gap-2 w-full',
        children: [
          WDiv(
            className: 'flex flex-row items-center justify-between gap-2',
            children: [
              IncidentStatusPill(status: window.status),
              if (window.scheduledFor != null)
                WText(
                  Carbon.parse(
                    window.scheduledFor!.toIso8601String(),
                  ).diffForHumans(),
                  className: '''
                  text-xs
                  text-muted dark:text-muted-dark
                ''',
                ),
            ],
          ),
          WText(
            window.title,
            className: '''
            text-sm font-semibold
            text-gray-900 dark:text-white
          ''',
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return EmptyState(
      titleKey: 'maintenance.empty.title',
      subtitleKey: 'maintenance.empty.subtitle',
      icon: Icons.build_circle_outlined,
    );
  }
}
