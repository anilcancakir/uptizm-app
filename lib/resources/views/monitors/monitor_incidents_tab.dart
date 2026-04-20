import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/incidents/incident_controller.dart';
import '../../../app/enums/incident_status.dart';
import '../../../app/models/incident.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';
import '../components/incidents/incident_create_sheet.dart';
import '../components/incidents/incident_detail_panel.dart';
import '../components/incidents/incident_list_item.dart';
import '../components/incidents/incident_note_composer.dart';

/// Incidents tab.
///
/// Lists incidents for the given monitor via [IncidentController]. Tabs
/// filter locally by status family; the AI-only chip further narrows to
/// AI-owned rows. Actions flow through the controller so list, detail
/// sheet, and toolbar stay consistent without manual reloads.
class MonitorIncidentsTab extends StatefulWidget {
  const MonitorIncidentsTab({super.key, required this.monitorId});

  final String monitorId;

  @override
  State<MonitorIncidentsTab> createState() => _MonitorIncidentsTabState();
}

enum _IncidentTab { triggered, acknowledged, resolved, all }

class _MonitorIncidentsTabState extends State<MonitorIncidentsTab> {
  _IncidentTab _tab = _IncidentTab.triggered;
  bool _aiOnly = false;

  IncidentController get _controller => IncidentController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load(monitorId: widget.monitorId);
    });
  }

  Future<void> _refresh() => _controller.load(monitorId: widget.monitorId);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final incidents = _controller.incidents
            .where((i) => i.monitorId == widget.monitorId)
            .toList();
        final filtered = _filtered(incidents);
        final hasError = _controller.rxStatus.isError && incidents.isEmpty;
        final isLoading = _controller.isLoading && incidents.isEmpty;
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
        WButton(
          onTap: () => IncidentCreateSheet.show(
            context,
            monitorTitle: widget.monitorId,
            monitorId: widget.monitorId,
          ),
          className: '''
            px-4 py-2.5 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            flex flex-row items-center justify-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.add_rounded,
                className: 'text-sm text-gray-700 dark:text-gray-200',
              ),
              WText(
                trans('incident.report_button'),
                className: '''
                  text-sm font-semibold
                  text-gray-700 dark:text-gray-200
                ''',
              ),
            ],
          ),
        ),
      ],
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
            // Pull the freshest list entry on every rebuild so the sheet
            // reflects events appended by `addEvent`. Fall back to the
            // captured closure when the controller has purged the row.
            final fresh = _controller.incidents.firstWhere(
              (i) => i.id == incident.id,
              orElse: () => incident,
            );
            return IncidentDetailPanel(
              incident: fresh,
              onClose: () => MagicRoute.back(),
              onAcknowledge: () {
                MagicRoute.back();
                _transitionStatus(fresh, IncidentStatus.investigating);
              },
              onResolve: () {
                MagicRoute.back();
                _transitionStatus(fresh, IncidentStatus.resolved);
              },
              onAddNote: () => IncidentNoteComposer.show(
                ctx,
                incidentTitle: fresh.title,
                onSubmit: (text, intent) => _onNoteSubmit(fresh, text, intent),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _transitionStatus(Incident incident, IncidentStatus next) async {
    final result = await _controller.update(incident.id, {'status': next.name});
    if (!mounted) return;
    if (result == null) {
      final err = _controller.getError('status') ?? _controller.firstError;
      Magic.toast(err ?? trans('incident.errors.generic_update'));
      return;
    }
    Magic.toast(
      trans(switch (next) {
        IncidentStatus.investigating => 'incident.toast.acknowledged',
        IncidentStatus.resolved => 'incident.toast.resolved',
        _ => 'incident.toast.updated',
      }),
    );
  }

  Future<void> _onNoteSubmit(
    Incident incident,
    String text,
    String intent,
  ) async {
    if (text.isNotEmpty) {
      final ok = await _controller.addEvent(incident.id, {
        'event_type': 'note',
        'message': text,
      });
      if (!ok && mounted) {
        Magic.toast(
          _controller.firstError ?? trans('incident.errors.generic_event'),
        );
        return;
      }
    }
    final next = switch (intent) {
      'acknowledge' => IncidentStatus.investigating,
      'mitigated' => IncidentStatus.mitigated,
      'resolved' => IncidentStatus.resolved,
      _ => null,
    };
    if (next != null && incident.status != next) {
      await _transitionStatus(incident, next);
      return;
    }
    if (mounted) Magic.toast(trans('incident.note.toast_added'));
  }

  Widget _statusTabs(List<Incident> incidents) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perTab = constraints.maxWidth / _IncidentTab.values.length;
        final scroll = perTab < 110;
        final buttons = [
          for (final t in _IncidentTab.values)
            WButton(
              onTap: () => setState(() => _tab = t),
              states: _tab == t ? {'active'} : {},
              className:
                  '''
                ${scroll ? '' : 'flex-1'} px-3 py-2 rounded-lg
                hover:bg-gray-200/60 dark:hover:bg-gray-700/60
                active:bg-white dark:active:bg-gray-900
                active:shadow-sm
                flex flex-row items-center justify-center gap-2
              ''',
              child: _statusTabChild(t, _countFor(incidents, t)),
            ),
        ];
        final row = WDiv(
          className: '''
            rounded-xl p-1
            bg-gray-100 dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex flex-row gap-1
          ''',
          children: buttons,
        );
        if (scroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row,
          );
        }
        return row;
      },
    );
  }

  Widget _statusTabChild(_IncidentTab t, int count) {
    return WDiv(
      className: 'flex flex-row items-center gap-2',
      children: [
        WText(
          trans('incident.tab.${t.name}'),
          states: _tab == t ? {'active'} : {},
          className: '''
            text-sm font-semibold
            text-gray-500 dark:text-gray-400
            active:text-gray-900 dark:active:text-white
          ''',
        ),
        WDiv(
          states: _tab == t ? {'active'} : {},
          className: '''
            px-1.5 py-0.5 rounded-full
            bg-gray-200 dark:bg-gray-700
            active:bg-primary-100 dark:active:bg-primary-900/40
          ''',
          child: WText(
            '$count',
            states: _tab == t ? {'active'} : {},
            className: '''
              text-[10px] font-bold
              text-gray-600 dark:text-gray-300
              active:text-primary-700 dark:active:text-primary-300
            ''',
          ),
        ),
      ],
    );
  }

  bool _matchesTab(Incident i, _IncidentTab t) {
    return switch (t) {
      _IncidentTab.triggered => i.status == IncidentStatus.detected,
      _IncidentTab.acknowledged =>
        i.status == IncidentStatus.investigating ||
            i.status == IncidentStatus.mitigated,
      _IncidentTab.resolved => i.status == IncidentStatus.resolved,
      _IncidentTab.all => true,
    };
  }

  int _countFor(List<Incident> incidents, _IncidentTab t) {
    return incidents
        .where((i) => _matchesTab(i, t) && (!_aiOnly || i.aiOwned))
        .length;
  }

  List<Incident> _filtered(List<Incident> incidents) {
    return incidents
        .where((i) => _matchesTab(i, _tab) && (!_aiOnly || i.aiOwned))
        .toList();
  }

  Widget _emptyList() {
    return const EmptyState(
      icon: Icons.shield_moon_rounded,
      titleKey: 'incident.empty.title',
      subtitleKey: 'incident.empty.subtitle',
      tone: 'up',
      variant: 'plain',
    );
  }
}
