import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/monitors/monitor_controller.dart';
import '../components/common/app_back_button.dart';
import '../components/common/danger_button.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/monitors/monitor_form_shell.dart';

/// Monitor edit screen.
///
/// Loads the target monitor through [MonitorController.load] on mount,
/// feeds the hydrated snapshot into [MonitorFormShell], and wires the
/// footer actions to the controller's submit / destroy flows. Validation
/// errors raised by the API surface inline under each field via
/// `ValidatesRequests`.
class MonitorEditView extends MagicStatefulView<MonitorController> {
  const MonitorEditView({super.key, required this.monitorId});

  final String monitorId;

  @override
  State<MonitorEditView> createState() => _MonitorEditViewState();
}

class _MonitorEditViewState
    extends MagicStatefulViewState<MonitorController, MonitorEditView> {
  @override
  void onInit() {
    super.onInit();
    controller.load(widget.monitorId);
  }

  Future<void> _onSubmit(MonitorFormValues values) async {
    if (controller.isSubmitting) return;
    final monitor = await controller.update(widget.monitorId, values);
    if (monitor == null) {
      final message =
          controller.rxStatus.message ?? trans('monitor.edit.error_generic');
      Magic.snackbar(trans('monitor.edit.title'), message, type: 'error');
      return;
    }
    Magic.toast(trans('monitor.edit.toast_saved'));
    MagicRoute.to('/monitors/${monitor.id}');
  }

  Future<void> _onDelete() async {
    if (controller.isDeleting) return;
    final confirmed = await Magic.confirm(
      title: trans('monitor.edit.delete_confirm_title'),
      message: trans('monitor.edit.delete_confirm_message'),
      confirmText: trans('monitor.edit.delete_confirm_confirm'),
      cancelText: trans('monitor.edit.cancel'),
      isDangerous: true,
    );
    if (!confirmed) return;
    final ok = await controller.destroy(widget.monitorId);
    if (!ok) {
      final message =
          controller.rxStatus.message ?? trans('monitor.edit.error_delete');
      Magic.snackbar(trans('monitor.edit.title'), message, type: 'error');
      return;
    }
    Magic.toast(trans('monitor.edit.toast_deleted'));
    MagicRoute.to('/monitors');
  }

  @override
  Widget build(BuildContext context) {
    final monitor = controller.monitor;
    final initial = monitor != null
        ? MonitorFormValues.fromMap(monitor.toMap())
        : null;
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: AppBackButton(fallbackPath: '/monitors/${widget.monitorId}'),
          title: trans('monitor.edit.title'),
          subtitle: initial?.name ?? trans('monitor.edit.loading'),
          inlineActions: true,
        ),
        if (initial == null) _loadingOrError() else _form(initial),
      ],
    );
  }

  Widget _loadingOrError() {
    if (controller.isError) {
      return WText(
        controller.rxStatus.message ?? trans('monitor.edit.error_load'),
        className: 'text-sm text-down-600 dark:text-down-400',
      );
    }
    return WDiv(
      className: 'w-full py-12 flex items-center justify-center',
      child: const CircularProgressIndicator(),
    );
  }

  Widget _form(MonitorFormValues initial) {
    final canDestroy = Gate.allows('monitors.destroy', controller.monitor);
    return MonitorFormShell(
      initial: initial,
      errorFor: (field) => controller.getError(field),
      onFieldEdit: (field) => controller.clearFieldError(field),
      footerBuilder: (context, read) => AnimatedBuilder(
        animation: controller,
        builder: (_, _) => WDiv(
          className: '''
            w-full pt-2 gap-3
            flex flex-col-reverse items-stretch
            sm:flex-row sm:flex-wrap sm:items-center sm:justify-end
          ''',
          children: [
            if (canDestroy)
              WDiv(
                className: 'sm:mr-auto',
                child: DangerButton(
                  labelKey: 'monitor.edit.delete',
                  icon: Icons.delete_outline_rounded,
                  isLoading: controller.isDeleting,
                  isDisabled: controller.isSubmitting,
                  onTap: _onDelete,
                ),
              ),
            SecondaryButton(
              labelKey: 'monitor.edit.cancel',
              onTap: () {
                if (controller.isSubmitting) return;
                MagicRoute.to('/monitors/${widget.monitorId}');
              },
            ),
            PrimaryButton(
              labelKey: 'monitor.edit.submit',
              icon: Icons.check_rounded,
              isLoading: controller.isSubmitting,
              isDisabled: controller.isDeleting,
              onTap: () => _onSubmit(read()),
            ),
          ],
        ),
      ),
    );
  }
}
