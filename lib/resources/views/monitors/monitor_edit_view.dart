import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../components/common/app_back_button.dart';
import '../components/common/danger_button.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/monitors/monitor_form_shell.dart';

/// Monitor edit screen. Reuses [MonitorFormShell] with a prefilled payload
/// and a Cancel / Delete / Save footer.
class MonitorEditView extends StatelessWidget {
  const MonitorEditView({super.key, required this.monitorId});

  final String monitorId;

  @override
  Widget build(BuildContext context) {
    final initial = MonitorFormInitial.sample();
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: AppBackButton(fallbackPath: '/monitors/$monitorId'),
          title: trans('monitor.edit.title'),
          subtitle: initial.name,
          inlineActions: true,
        ),
        MonitorFormShell(
          initial: initial,
          footerBuilder: (context, read) {
            return WDiv(
              className: '''
                w-full pt-2 gap-3
                flex flex-col-reverse items-stretch
                sm:flex-row sm:flex-wrap sm:items-center sm:justify-end
              ''',
              children: [
                WDiv(
                  className: 'sm:mr-auto',
                  child: DangerButton(
                    labelKey: 'monitor.edit.delete',
                    icon: Icons.delete_outline_rounded,
                    onTap: () => _confirmDelete(monitorId),
                  ),
                ),
                SecondaryButton(
                  labelKey: 'monitor.edit.cancel',
                  onTap: () => MagicRoute.to('/monitors/$monitorId'),
                ),
                PrimaryButton(
                  labelKey: 'monitor.edit.submit',
                  icon: Icons.check_rounded,
                  onTap: () {
                    read();
                    Magic.toast(trans('monitor.edit.toast_saved'));
                    MagicRoute.to('/monitors/$monitorId');
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await Magic.confirm(
      title: trans('monitor.edit.delete_confirm_title'),
      message: trans('monitor.edit.delete_confirm_message'),
      confirmText: trans('monitor.edit.delete_confirm_confirm'),
      cancelText: trans('monitor.edit.cancel'),
      isDangerous: true,
    );
    if (confirmed) {
      Magic.toast(trans('monitor.edit.toast_deleted'));
      MagicRoute.to('/monitors');
    }
  }
}
