import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/incidents/incident_controller.dart';
import '../../../app/enums/incident_kind.dart';
import '../../../app/models/incident.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';
import '../components/incidents/incident_impact_badge.dart';
import '../components/incidents/incident_status_pill.dart';

/// Workspace incidents index.
///
/// Four client-side lanes filter the same [IncidentController] feed:
/// `active` (kind=incident + !terminal + published), `scheduled`
/// (kind=maintenance), `history` (terminal), `drafts` (!is_published).
/// The API is a single `/incidents` list; lane filtering happens in
/// memory so the operator can switch tabs without re-fetching.
class IncidentsIndexView extends MagicStatefulView<IncidentController> {
  const IncidentsIndexView({super.key});

  @override
  State<IncidentsIndexView> createState() => _IncidentsIndexViewState();
}

enum _Lane { active, scheduled, history, drafts }

class _IncidentsIndexViewState
    extends MagicStatefulViewState<IncidentController, IncidentsIndexView> {
  _Lane _lane = _Lane.active;

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
            title: trans('incident.list.title'),
            subtitle: trans('incident.list.subtitle'),
            inlineActions: true,
            actions: [
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
            (incidents) => _body(_filter(incidents)),
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
      _Lane.active =>
        all
            .where(
              (i) =>
                  i.kind == IncidentKind.incident &&
                  i.isPublished &&
                  !i.status.isTerminal,
            )
            .toList(),
      _Lane.scheduled =>
        all.where((i) => i.kind == IncidentKind.maintenance).toList(),
      _Lane.history => all.where((i) => i.status.isTerminal).toList(),
      _Lane.drafts => all.where((i) => !i.isPublished).toList(),
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
          trans('incident.lane.${lane.name}'),
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

  Widget _body(List<Incident> incidents) {
    if (incidents.isEmpty) return _empty();
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [for (final incident in incidents) _row(incident)],
    );
  }

  Widget _row(Incident incident) {
    return WButton(
      onTap: () => MagicRoute.to('/incidents/${incident.id}'),
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
              IncidentStatusPill(status: incident.status),
              IncidentImpactBadge(impact: incident.impact),
            ],
          ),
          WText(
            incident.title,
            className: '''
              text-sm font-semibold
              text-gray-900 dark:text-white
            ''',
          ),
          WText(
            Carbon.parse(incident.startedAt.toIso8601String()).diffForHumans(),
            className: '''
              text-xs
              text-muted dark:text-muted-dark
            ''',
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return EmptyState(
      titleKey: 'incident.empty.title',
      subtitleKey: 'incident.empty.subtitle',
      icon: Icons.check_circle_outline_rounded,
    );
  }
}
