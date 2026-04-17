import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../components/common/app_back_button.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/monitors/monitor_form_shell.dart';

/// Monitor create screen.
///
/// Thin wrapper around [MonitorFormShell] that provides a page header and
/// a Cancel / Create footer.
class MonitorCreateView extends StatelessWidget {
  const MonitorCreateView({super.key});

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
          footerBuilder: (context, read) => WDiv(
            className:
                'w-full flex flex-row items-center justify-end gap-3 pt-2',
            children: [
              SecondaryButton(
                labelKey: 'common.cancel',
                onTap: () => MagicRoute.to('/monitors'),
              ),
              PrimaryButton(
                labelKey: 'monitor.create.submit',
                icon: Icons.check_rounded,
                onTap: () {
                  read();
                  Magic.toast(trans('monitor.create.toast_created'));
                  MagicRoute.to('/monitors/sample?welcome=1');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
