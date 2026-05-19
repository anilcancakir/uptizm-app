import 'dart:async';

import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/incidents/incident_controller.dart';
import '../../../app/enums/incident_status.dart';
import '../../../app/models/incident.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';
import '../components/incidents/incident_detail_panel.dart';
import '../components/incidents/incident_list_item.dart';
import '../components/incidents/incident_note_composer.dart';
import '../monitors/monitor_incidents_tab_filter.dart'
    show IncidentTab, incidentMatchesTab;

/// Workspace-wide incidents list page (`/incidents`).
///
/// Re-uses [IncidentController] without a monitor filter so the same
/// controller backs both this page and the per-monitor Incidents tab.
class IncidentsIndexView extends StatefulWidget {
  const IncidentsIndexView({super.key});

  @override
  State<IncidentsIndexView> createState() => _IncidentsIndexViewState();
}

class _IncidentsIndexViewState extends State<IncidentsIndexView> {
  IncidentTab _tab = IncidentTab.triggered;
  bool _aiOnly = false;
  // BUG #5 fix: the controller starts at `rxStatus.empty()` by default. If
  // we let the first build paint before fetchList sets rxStatus.loading(),
  // the user sees an empty state flash. Track whether the first fetch has
  // resolved (success / error / empty) and treat the pre-resolved window
  // as loading so the skeleton renders instead.
  bool _hasFirstResolved = false;

  IncidentController get _controller => IncidentController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.load();
      if (mounted) setState(() => _hasFirstResolved = true);
    });
  }

  Future<void> _refresh() => _controller.load();

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-6 p-6 w-full h-full overflow-y-auto',
      children: [
        WDiv(
          className: 'flex flex-col gap-1',
          children: [
            WText(
              trans('incident.index.title'),
              className: 'text-2xl font-bold text-gray-900 dark:text-white',
            ),
            WText(
              trans('incident.index.subtitle'),
              className: 'text-sm text-gray-600 dark:text-gray-400',
            ),
          ],
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            final incidents = _controller.incidents;
            final filtered = _filtered(incidents);
            final hasError = _controller.rxStatus.isError && incidents.isEmpty;
            // Treat the pre-first-fetch window as loading so the empty
            // state never flashes before the API answers (BUG #5).
            final isLoading =
                (!_hasFirstResolved || _controller.isLoading) &&
                incidents.isEmpty &&
                !hasError;
            return WDiv(
              className: 'flex flex-col gap-4',
              children: [
                _toolbar(incidents),
                if (hasError)
                  ErrorBanner(
                    message: _controller.rxStatus.message,
                    onRetry: _refresh,
                  )
                else if (isLoading)
                  const SkeletonRowList()
                else
                  WDiv(
                    className: '''
                      rounded-xl overflow-hidden
                      bg-white dark:bg-gray-800
                      border border-gray-200 dark:border-gray-700
                      flex flex-col
                    ''',
                    child: filtered.isEmpty ? _emptyList() : _list(filtered),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _toolbar(List<Incident> incidents) {
    return WDiv(
      className: '''
        flex flex-col items-stretch gap-3
        sm:flex-row sm:items-center
      ''',
      children: [
        WDiv(className: 'w-full sm:flex-1', child: _statusTabs(incidents)),
        RefreshIconButton(onTap: _refresh, isRefreshing: _controller.isLoading),
        WButton(
          onTap: () => setState(() => _aiOnly = !_aiOnly),
          states: _aiOnly ? {'active'} : {},
          className: '''
            px-3 py-2.5 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            active:bg-primary-50 dark:active:bg-primary-900/30
            active:border-primary-300 dark:active:border-primary-700
            flex flex-row items-center justify-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.auto_awesome_rounded,
                states: _aiOnly ? {'active'} : {},
                className: '''
                  text-sm text-gray-500 dark:text-gray-400
                  active:text-primary-600 dark:active:text-primary-400
                ''',
              ),
              WText(
                trans('incident.filter.ai_owned'),
                states: _aiOnly ? {'active'} : {},
                className: '''
                  text-sm font-semibold
                  text-gray-700 dark:text-gray-200
                  active:text-primary-700 dark:active:text-primary-300
                ''',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusTabs(List<Incident> all) {
    final tabs = <(IncidentTab, String)>[
      (IncidentTab.triggered, trans('incident.tab.triggered')),
      (IncidentTab.acknowledged, trans('incident.tab.acknowledged')),
      (IncidentTab.resolved, trans('incident.tab.resolved')),
      (IncidentTab.all, trans('incident.tab.all')),
    ];
    return WDiv(
      className: 'flex flex-row flex-wrap gap-2',
      children: [
        for (final entry in tabs)
          WButton(
            onTap: () => setState(() => _tab = entry.$1),
            states: _tab == entry.$1 ? {'active'} : {},
            className: '''
              px-3 py-2 rounded-lg
              border border-gray-200 dark:border-gray-700
              bg-white dark:bg-gray-800
              hover:bg-gray-100 dark:hover:bg-gray-700
              active:bg-primary-50 dark:active:bg-primary-900/30
              active:border-primary-300 dark:active:border-primary-700
              flex flex-row items-center gap-2
            ''',
            child: WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                WText(
                  entry.$2,
                  states: _tab == entry.$1 ? {'active'} : {},
                  className: '''
                    text-sm font-semibold
                    text-gray-700 dark:text-gray-200
                    active:text-primary-700 dark:active:text-primary-300
                  ''',
                ),
                WText(
                  all
                      .where((i) => incidentMatchesTab(i.status, entry.$1))
                      .length
                      .toString(),
                  className: '''
                    text-xs font-bold
                    text-gray-500 dark:text-gray-400
                  ''',
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Incident> _filtered(List<Incident> incidents) {
    Iterable<Incident> chain = incidents;
    chain = chain.where((i) => incidentMatchesTab(i.status, _tab));
    if (_aiOnly) {
      chain = chain.where((i) => i.aiOwned);
    }
    return chain.toList();
  }

  Widget _emptyList() {
    return EmptyState(
      icon: Icons.check_circle_outline_rounded,
      titleKey: 'incident.empty.title',
      subtitleKey: 'incident.empty.subtitle',
      variant: 'plain',
    );
  }

  Widget _list(List<Incident> items) {
    return WDiv(
      className: 'flex flex-col',
      children: [
        for (final i in items)
          IncidentListItem(incident: i, onTap: () => _openSheet(i)),
      ],
    );
  }

  Future<void> _openSheet(Incident incident) async {
    unawaited(_controller.loadOne(incident.id));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, _) => AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            final detail = _controller.detail;
            final fresh = detail != null && detail.id == incident.id
                ? detail
                : _controller.incidents.firstWhere(
                    (i) => i.id == incident.id,
                    orElse: () => incident,
                  );
            return IncidentDetailPanel(
              incident: fresh,
              onClose: () => MagicRoute.back(),
              onAcknowledge: () => IncidentNoteComposer.show(
                ctx,
                incidentId: fresh.id,
                incidentTitle: fresh.title,
                initialIntent: 'investigating',
                onSubmit: (text, intent) => _onNoteSubmit(fresh, text, intent),
              ),
              onResolve: () => IncidentNoteComposer.show(
                ctx,
                incidentId: fresh.id,
                incidentTitle: fresh.title,
                initialIntent: 'resolved',
                onSubmit: (text, intent) => _onNoteSubmit(fresh, text, intent),
              ),
              onAddNote: () => IncidentNoteComposer.show(
                ctx,
                incidentId: fresh.id,
                incidentTitle: fresh.title,
                onSubmit: (text, intent) => _onNoteSubmit(fresh, text, intent),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onNoteSubmit(
    Incident incident,
    String body,
    String intent,
  ) async {
    final intentKey = intent.isEmpty ? 'note' : intent;
    final next = switch (intentKey) {
      'investigating' => IncidentStatus.investigating,
      'identified' => IncidentStatus.identified,
      'monitoring' => IncidentStatus.monitoring,
      'mitigated' => IncidentStatus.mitigated,
      'resolved' => IncidentStatus.resolved,
      _ => incident.status,
    };
    await _controller.postUpdate(id: incident.id, body: body, status: next);
  }
}
