import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/incidents/maintenance_controller.dart';
import '../../../app/enums/incident_status.dart';
import '../../../app/models/incident.dart';
import '../components/common/app_back_button.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/skeleton_row.dart';
import '../components/incidents/incident_status_pill.dart';

/// Maintenance window detail.
///
/// Renders the status pill, start/end timestamps, the affected-monitors
/// strip, and the maintenance body. A "Cancel window" action is surfaced
/// when the window has not yet reached [IncidentStatus.completed].
class MaintenanceShowView extends MagicStatefulView<MaintenanceController> {
  const MaintenanceShowView({super.key, required this.id});

  final String id;

  @override
  State<MaintenanceShowView> createState() => _MaintenanceShowViewState();
}

class _MaintenanceShowViewState
    extends MagicStatefulViewState<MaintenanceController, MaintenanceShowView> {
  @override
  void onInit() {
    super.onInit();
    controller.loadOne(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final window = controller.detail;
        if (controller.isLoading && window == null) {
          return const WDiv(
            className: 'p-4 lg:p-6',
            children: [SkeletonRowList()],
          );
        }
        if (controller.isError && window == null) {
          return WDiv(
            className: 'p-4 lg:p-6',
            child: ErrorBanner(
              message: controller.rxStatus.message,
              onRetry: () => controller.loadOne(widget.id),
            ),
          );
        }
        if (window == null) {
          return const WDiv(
            className: 'p-4 lg:p-6',
            child: EmptyState(
              titleKey: 'maintenance.empty.title',
              subtitleKey: 'maintenance.empty.subtitle',
              icon: Icons.build_circle_outlined,
            ),
          );
        }
        return WDiv(
          className: 'p-4 lg:p-6 flex flex-col gap-5',
          children: [
            _header(window),
            _window(window),
            _affected(window),
            _body(window),
          ],
        );
      },
    );
  }

  Widget _header(Incident window) {
    final cancelable = window.status != IncidentStatus.completed;
    return WDiv(
      className: 'flex flex-row items-center gap-3',
      children: [
        const AppBackButton(fallbackPath: '/maintenance'),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            window.title,
            className: '''
              text-lg font-bold
              text-gray-900 dark:text-white truncate
            ''',
          ),
        ),
        if (cancelable)
          WButton(
            onTap: controller.isSubmitting ? null : () => _cancel(window),
            className: '''
              px-3 py-2 rounded-lg
              bg-down-50 dark:bg-down-900/30
              border border-down-200 dark:border-down-800
              hover:bg-down-100 dark:hover:bg-down-900/50
            ''',
            child: WText(
              trans('maintenance.actions.cancel'),
              className: '''
                text-xs font-semibold
                text-down-700 dark:text-down-300
              ''',
            ),
          ),
      ],
    );
  }

  Widget _window(Incident window) {
    return WDiv(
      className: 'flex flex-row items-center gap-2 flex-wrap',
      children: [
        IncidentStatusPill(status: window.status),
        if (window.scheduledFor != null)
          _pill(
            label: trans('maintenance.schedule.scheduled_for'),
            value: Carbon.parse(
              window.scheduledFor!.toIso8601String(),
            ).diffForHumans(),
          ),
        if (window.scheduledUntil != null)
          _pill(
            label: trans('maintenance.schedule.scheduled_until'),
            value: Carbon.parse(
              window.scheduledUntil!.toIso8601String(),
            ).diffForHumans(),
          ),
      ],
    );
  }

  Widget _pill({required String label, required String value}) {
    return WDiv(
      className: '''
        px-2.5 py-1 rounded-full
        bg-subtle dark:bg-subtle-dark
        border border-subtle dark:border-subtle-dark
        flex flex-row items-center gap-1.5
      ''',
      children: [
        WText(
          label,
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            text-muted dark:text-muted-dark
          ''',
        ),
        WText(
          value,
          className: '''
            text-xs font-semibold
            text-gray-800 dark:text-gray-100
          ''',
        ),
      ],
    );
  }

  Widget _affected(Incident window) {
    if (window.affectedMonitors.isEmpty) return const SizedBox.shrink();
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
            for (final affected in window.affectedMonitors)
              WDiv(
                className: 'flex flex-row items-center justify-between gap-2',
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

  Widget _body(Incident window) {
    return WDiv(
      className: '''
        p-4 rounded-lg border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        flex flex-col gap-2
      ''',
      children: [
        WText(
          trans('maintenance.show.details_heading'),
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            text-muted dark:text-muted-dark
          ''',
        ),
        WText(
          window.updates.isNotEmpty
              ? window.updates.first.body
              : trans('maintenance.show.no_details'),
          className: '''
            text-sm leading-relaxed
            text-gray-800 dark:text-gray-100
          ''',
        ),
      ],
    );
  }

  Future<void> _cancel(Incident window) async {
    final ok = await Magic.confirm(
      title: trans('maintenance.actions.cancel'),
      message: trans('maintenance.actions.confirm_cancel'),
      isDangerous: true,
    );
    if (!ok) return;
    final cancelled = await controller.cancel(window.id);
    if (!mounted || !cancelled) return;
    Magic.toast(trans('maintenance.toast.cancelled'));
  }
}
