import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../components/settings/settings_list_row.dart';
import '../components/settings/settings_list_section.dart';

/// Settings hub. iOS-style grouped list that stays responsive on web.
class SettingsHubView extends StatelessWidget {
  const SettingsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          title: trans('settings.title'),
          subtitle: trans('settings.subtitle'),
          inlineActions: true,
        ),
        SettingsListSection(
          titleKey: 'settings.section.account',
          rows: [
            SettingsListRow(
              icon: Icons.person_outline_rounded,
              iconTone: 'primary',
              titleKey: 'settings.profile.title',
              subtitleKey: 'settings.profile.subtitle',
              onTap: () => MagicRoute.to(MagicStarterConfig.profileRoute()),
              isFirst: true,
            ),
            SettingsListRow(
              icon: Icons.group_outlined,
              iconTone: 'up',
              titleKey: 'settings.team.title',
              subtitleKey: 'settings.team.subtitle',
              onTap: () =>
                  MagicRoute.to(MagicStarterConfig.teamSettingsRoute()),
              isLast: true,
            ),
          ],
        ),
        SettingsListSection(
          titleKey: 'settings.section.workspace',
          rows: [
            SettingsListRow(
              icon: Icons.auto_awesome_rounded,
              iconTone: 'primary',
              titleKey: 'settings.ai.title',
              subtitleKey: 'settings.ai.subtitle',
              onTap: () => MagicRoute.to('/settings/ai'),
              isFirst: true,
            ),
            SettingsListRow(
              icon: Icons.analytics_outlined,
              iconTone: 'degraded',
              titleKey: 'settings.metrics_library.title',
              subtitleKey: 'settings.metrics_library.subtitle',
              onTap: () => MagicRoute.to('/settings/metrics-library'),
              isLast: true,
            ),
          ],
        ),
        SettingsListSection(
          titleKey: 'settings.section.preferences',
          rows: [
            SettingsListRow(
              icon: Icons.notifications_none_rounded,
              iconTone: 'degraded',
              titleKey: 'settings.notifications.title',
              subtitleKey: 'settings.notifications.subtitle',
              onTap: () => MagicRoute.to(
                MagicStarterConfig.notificationPreferencesRoute(),
              ),
              isFirst: true,
            ),
            SettingsListRow(
              icon: Icons.dark_mode_outlined,
              iconTone: 'paused',
              titleKey: 'settings.appearance.title',
              subtitleKey: 'settings.appearance.subtitle',
              onTap: () => MagicRoute.to('/settings/appearance'),
              isLast: true,
            ),
          ],
        ),
        SettingsListSection(
          titleKey: 'settings.section.about',
          rows: [
            SettingsListRow(
              icon: Icons.help_outline_rounded,
              iconTone: 'primary',
              titleKey: 'settings.help.title',
              subtitleKey: 'settings.help.subtitle',
              onTap: () {},
              isFirst: true,
              comingSoon: true,
            ),
            SettingsListRow(
              icon: Icons.info_outline_rounded,
              iconTone: 'paused',
              titleKey: 'settings.about.title',
              subtitleKey: 'settings.about.subtitle',
              onTap: () {},
              isLast: true,
              comingSoon: true,
            ),
          ],
        ),
        SettingsListSection(
          titleKey: 'settings.section.session',
          rows: [
            SettingsListRow(
              icon: Icons.logout_rounded,
              iconTone: 'down',
              titleKey: 'settings.logout.title',
              subtitleKey: 'settings.logout.subtitle',
              onTap: _confirmLogout,
              isFirst: true,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await Magic.confirm(
      title: trans('settings.logout.confirm_title'),
      message: trans('settings.logout.confirm_message'),
      confirmText: trans('settings.logout.confirm_action'),
      cancelText: trans('common.cancel'),
      isDangerous: true,
    );
    if (!ok) return;
    final customLogout = MagicStarter.manager.onLogout;
    if (customLogout != null) {
      await customLogout();
    }
  }
}
