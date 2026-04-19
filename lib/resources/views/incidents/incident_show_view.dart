import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/incidents/incident_controller.dart';
import '../../../app/enums/incident_status.dart';
import '../../../app/models/incident.dart';
import '../components/common/app_back_button.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/form_field_error.dart';
import '../components/common/form_field_label.dart';
import '../components/common/skeleton_row.dart';
import '../components/incidents/incident_impact_badge.dart';
import '../components/incidents/incident_status_pill.dart';
import '../components/incidents/incident_update_stream.dart';

/// Incident detail view.
///
/// Renders the status + impact header, the affected-monitors strip, an
/// inline update composer that posts to the public update stream, the
/// reverse-chronological stream itself, and a postmortem editor that is
/// locked until the incident reaches a terminal lifecycle state.
class IncidentShowView extends MagicStatefulView<IncidentController> {
  const IncidentShowView({super.key, required this.id});

  final String id;

  @override
  State<IncidentShowView> createState() => _IncidentShowViewState();
}

class _IncidentShowViewState
    extends MagicStatefulViewState<IncidentController, IncidentShowView> {
  final _updateBody = TextEditingController();
  final _postmortemBody = TextEditingController();

  IncidentStatus _updateStatus = IncidentStatus.investigating;
  bool _notifyUpdate = true;
  bool _notifyPostmortem = false;
  bool _postmortemSeeded = false;

  @override
  void onInit() {
    super.onInit();
    controller.loadOne(widget.id);
  }

  @override
  void onClose() {
    _updateBody.dispose();
    _postmortemBody.dispose();
    super.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final incident = controller.detail;
        if (controller.isLoading && incident == null) {
          return const _DetailSkeleton();
        }
        if (controller.isError && incident == null) {
          return WDiv(
            className: 'p-4 lg:p-6',
            child: ErrorBanner(
              message: controller.rxStatus.message,
              onRetry: () => controller.loadOne(widget.id),
            ),
          );
        }
        if (incident == null) {
          return WDiv(
            className: 'p-4 lg:p-6',
            child: const EmptyState(
              titleKey: 'incident.empty.title',
              subtitleKey: 'incident.empty.subtitle',
              icon: Icons.inbox_outlined,
            ),
          );
        }
        _seedPostmortem(incident);
        return WDiv(
          className: 'p-4 lg:p-6 flex flex-col gap-5',
          children: [
            _header(incident),
            _affectedMonitors(incident),
            _updateComposer(incident),
            IncidentUpdateStream(updates: incident.updates),
            _postmortemSection(incident),
          ],
        );
      },
    );
  }

  void _seedPostmortem(Incident incident) {
    if (_postmortemSeeded) return;
    _postmortemSeeded = true;
    final existing = incident.postmortemBody;
    if (existing != null && existing.isNotEmpty) {
      _postmortemBody.text = existing;
    }
  }

  Widget _header(Incident incident) {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-3',
          children: [
            AppBackButton(fallbackPath: '/incidents'),
            WDiv(
              className: 'flex-1 min-w-0',
              child: WText(
                incident.title,
                className: '''
                  text-lg font-bold
                  text-gray-900 dark:text-white truncate
                ''',
              ),
            ),
            if (!incident.isPublished)
              WButton(
                onTap: controller.isSubmitting
                    ? null
                    : () => _publish(incident),
                className: '''
                  px-3 py-2 rounded-lg
                  bg-primary-600 dark:bg-primary-500
                  hover:bg-primary-700 dark:hover:bg-primary-400
                  flex flex-row items-center gap-1.5
                ''',
                child: WText(
                  trans('incident.publish.publish_to_status_page'),
                  className: 'text-xs font-semibold text-white',
                ),
              )
            else
              WDiv(
                className: '''
                  px-2 py-1 rounded-md
                  bg-up-50 dark:bg-up-900/30
                  border border-up-200 dark:border-up-800
                ''',
                child: WText(
                  trans('incident.publish.already_public'),
                  className: '''
                    text-[10px] font-bold uppercase tracking-wide
                    text-up-700 dark:text-up-300
                  ''',
                ),
              ),
          ],
        ),
        WDiv(
          className: 'flex flex-row items-center gap-2 flex-wrap',
          children: [
            IncidentStatusPill(status: incident.status),
            IncidentImpactBadge(impact: incident.impact),
            WText(
              Carbon.parse(
                incident.startedAt.toIso8601String(),
              ).diffForHumans(),
              className: '''
                text-xs
                text-muted dark:text-muted-dark
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _affectedMonitors(Incident incident) {
    if (incident.affectedMonitors.isEmpty) return const SizedBox.shrink();
    return WDiv(
      className: '''
        p-4 rounded-lg border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        flex flex-col gap-2
      ''',
      children: [
        WText(
          trans('incident.affected_monitors'),
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            text-muted dark:text-muted-dark
          ''',
        ),
        WDiv(
          className: 'flex flex-col gap-1',
          children: [
            for (final affected in incident.affectedMonitors)
              WDiv(
                className: '''
                  flex flex-row items-center justify-between gap-2
                  py-1
                ''',
                children: [
                  WText(
                    affected.name,
                    className: '''
                      text-sm
                      text-gray-800 dark:text-gray-100 truncate
                    ''',
                  ),
                  WText(
                    trans(affected.statusCurrent.labelKey),
                    className: '''
                      text-xs font-semibold
                      text-muted dark:text-muted-dark
                    ''',
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _updateComposer(Incident incident) {
    final submitting = controller.isSubmitting;
    return WDiv(
      className: '''
        p-4 rounded-lg border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        flex flex-col gap-3
      ''',
      children: [
        WText(
          trans('incident.update.compose'),
          className: '''
            text-sm font-semibold
            text-gray-900 dark:text-white
          ''',
        ),
        WDiv(
          className: 'flex flex-col gap-1',
          children: [
            const FormFieldLabel(labelKey: 'incident.update.status_change'),
            WDiv(
              className: 'flex flex-row gap-1 flex-wrap',
              children: [
                for (final status in _composerStatuses(incident))
                  _statusChip(status),
              ],
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-col gap-1',
          children: [
            WInput(
              controller: _updateBody,
              type: InputType.multiline,
              minLines: 3,
              maxLines: 8,
              placeholder: trans('incident.update.body_placeholder'),
              placeholderClassName: 'text-sm text-gray-400 dark:text-gray-500',
              className: '''
                rounded-lg px-3 py-2.5 text-sm
                bg-white dark:bg-gray-900
                border border-gray-200 dark:border-gray-700
              ''',
            ),
            FormFieldError(message: controller.getError('body')),
          ],
        ),
        WDiv(
          className: 'flex flex-row items-center justify-between gap-2',
          children: [
            WDiv(
              className: 'flex flex-row items-center gap-2',
              children: [
                WCheckbox(
                  value: _notifyUpdate,
                  onChanged: (v) => setState(() => _notifyUpdate = v),
                ),
                WText(
                  trans('incident.update.notify_subscribers'),
                  className: '''
                    text-xs
                    text-gray-700 dark:text-gray-200
                  ''',
                ),
              ],
            ),
            WButton(
              onTap: submitting ? null : () => _postUpdate(incident),
              className: '''
                px-3 py-2 rounded-lg
                bg-primary-600 dark:bg-primary-500
                hover:bg-primary-700 dark:hover:bg-primary-400
                flex flex-row items-center
              ''',
              child: WText(
                trans('incident.update.compose'),
                className: 'text-xs font-semibold text-white',
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<IncidentStatus> _composerStatuses(Incident incident) {
    if (incident.status.isScheduledLane) {
      return const [
        IncidentStatus.scheduled,
        IncidentStatus.inProgress,
        IncidentStatus.verifying,
        IncidentStatus.completed,
      ];
    }
    return const [
      IncidentStatus.investigating,
      IncidentStatus.identified,
      IncidentStatus.monitoring,
      IncidentStatus.resolved,
    ];
  }

  Widget _statusChip(IncidentStatus status) {
    final isActive = _updateStatus == status;
    return WButton(
      onTap: () => setState(() => _updateStatus = status),
      states: isActive ? {'active'} : {},
      className: '''
        px-2.5 py-1 rounded-full
        border border-gray-200 dark:border-gray-700
        bg-white dark:bg-gray-900
        hover:bg-gray-50 dark:hover:bg-gray-800
        active:bg-primary-50 dark:active:bg-primary-900/30
        active:border-primary-300 dark:active:border-primary-700
      ''',
      child: WText(
        trans(status.labelKey),
        states: isActive ? {'active'} : {},
        className: '''
          text-[10px] font-bold uppercase tracking-wide
          text-muted dark:text-muted-dark
          active:text-primary-700 dark:active:text-primary-300
        ''',
      ),
    );
  }

  Widget _postmortemSection(Incident incident) {
    final locked = !incident.status.isTerminal;
    return WDiv(
      className: '''
        p-4 rounded-lg border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        flex flex-col gap-3
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center justify-between gap-2',
          children: [
            WText(
              trans('incident.postmortem.title'),
              className: '''
                text-sm font-semibold
                text-gray-900 dark:text-white
              ''',
            ),
            if (incident.postmortemPublishedAt != null)
              WText(
                trans('incident.postmortem.published_at').replaceAll(
                  '{at}',
                  Carbon.parse(
                    incident.postmortemPublishedAt!.toIso8601String(),
                  ).diffForHumans(),
                ),
                className: '''
                  text-xs
                  text-muted dark:text-muted-dark
                ''',
              ),
          ],
        ),
        if (locked)
          WText(
            trans('incident.postmortem.locked_hint'),
            className: '''
              text-xs
              text-muted dark:text-muted-dark
            ''',
          )
        else ...[
          WInput(
            controller: _postmortemBody,
            type: InputType.multiline,
            minLines: 5,
            maxLines: 14,
            placeholder: trans('incident.postmortem.placeholder'),
            placeholderClassName: 'text-sm text-gray-400 dark:text-gray-500',
            className: '''
              rounded-lg px-3 py-2.5 text-sm
              bg-white dark:bg-gray-900
              border border-gray-200 dark:border-gray-700
            ''',
          ),
          FormFieldError(message: controller.getError('body')),
          WDiv(
            className: 'flex flex-row items-center justify-between gap-2',
            children: [
              WDiv(
                className: 'flex flex-row items-center gap-2',
                children: [
                  WCheckbox(
                    value: _notifyPostmortem,
                    onChanged: (v) => setState(() => _notifyPostmortem = v),
                  ),
                  WText(
                    trans('incident.postmortem.notify_subscribers'),
                    className: '''
                      text-xs
                      text-gray-700 dark:text-gray-200
                    ''',
                  ),
                ],
              ),
              WButton(
                onTap: controller.isSubmitting
                    ? null
                    : () => _publishPostmortem(incident),
                className: '''
                  px-3 py-2 rounded-lg
                  bg-primary-600 dark:bg-primary-500
                  hover:bg-primary-700 dark:hover:bg-primary-400
                ''',
                child: WText(
                  trans('incident.postmortem.publish'),
                  className: 'text-xs font-semibold text-white',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _postUpdate(Incident incident) async {
    final created = await controller.postUpdate(
      incidentId: incident.id,
      status: _updateStatus,
      body: _updateBody.text,
      deliverNotifications: _notifyUpdate,
    );
    if (!mounted) return;
    if (created == null) {
      if (!controller.hasErrors) {
        Magic.toast(
          controller.rxStatus.message ??
              trans('incident.errors.generic_update'),
        );
      }
      return;
    }
    _updateBody.clear();
    Magic.toast(trans('incident.toast.updated'));
  }

  Future<void> _publish(Incident incident) async {
    final ok = await controller.publish(incident.id);
    if (!mounted || !ok) return;
    Magic.toast(trans('incident.toast.updated'));
  }

  Future<void> _publishPostmortem(Incident incident) async {
    final ok = await controller.publishPostmortem(
      incidentId: incident.id,
      body: _postmortemBody.text,
      notify: _notifyPostmortem,
    );
    if (!mounted || !ok) return;
    Magic.toast(trans('incident.toast.updated'));
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-3',
      children: const [SkeletonRowList()],
    );
  }
}
