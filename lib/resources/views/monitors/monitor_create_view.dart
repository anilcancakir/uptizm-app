import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/monitors/monitor_controller.dart';
import '../components/common/app_back_button.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/monitors/monitor_form_shell.dart';

/// Monitor create screen.
///
/// Thin wrapper around [MonitorFormShell] that provides a page header and
/// a Cancel / Create footer. Submit state is owned by
/// [MonitorController]; the view only reads the form snapshot,
/// hands it to the controller, and navigates to the freshly created
/// monitor on success.
class MonitorCreateView extends MagicStatefulView<MonitorController> {
  const MonitorCreateView({super.key});

  @override
  State<MonitorCreateView> createState() => _MonitorCreateViewState();
}

class _MonitorCreateViewState
    extends MagicStatefulViewState<MonitorController, MonitorCreateView> {
  Future<void> _onSubmit(MonitorFormValues values) async {
    if (controller.isSubmitting) return;
    final monitor = await controller.store(values);
    if (monitor == null) {
      // Inline per-field errors are surfaced via MonitorFormShell.errorFor.
      // Only toast when the failure is generic (no field-level error).
      if (!controller.hasErrors) {
        final message =
            controller.rxStatus.message ??
            trans('monitor.create.error_generic');
        Magic.toast(message);
      }
      return;
    }
    Magic.toast(trans('monitor.create.toast_created'));
    MagicRoute.to('/monitors/${monitor.id}?welcome=1');
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/monitors'),
          title: trans('monitor.create.title'),
          subtitle: trans('monitor.create.subtitle'),
          inlineActions: true,
        ),
        MonitorFormShell(
          errorFor: (field) => controller.getError(field),
          onFieldEdit: (field) => controller.clearFieldError(field),
          footerBuilder: (context, read) => AnimatedBuilder(
            animation: controller,
            builder: (_, _) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: WDiv(
                className:
                    'w-full flex flex-row items-center justify-end gap-3 pt-2 wrap',
                children: [
                  SecondaryButton(
                    labelKey: 'common.cancel',
                    onTap: () {
                      if (controller.isSubmitting) return;
                      MagicRoute.to('/monitors');
                    },
                  ),
                  PrimaryButton(
                    labelKey: 'monitor.create.submit',
                    icon: Icons.check_rounded,
                    isLoading: controller.isSubmitting,
                    onTap: () => _onSubmit(read()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
