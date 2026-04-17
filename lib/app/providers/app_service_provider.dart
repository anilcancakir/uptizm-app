import 'package:magic/magic.dart';
import 'package:flutter/material.dart';
import 'package:magic_starter/magic_starter.dart';
import '../models/user.dart';

/// Application Service Provider.
///
/// Use this provider to bind your own services to the IoC container and
/// to perform any bootstrap logic that requires other services to be ready.
class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  @override
  void register() {
    // Bind your services here (sync only; do not resolve other services).
    // Example:
    //   app.singleton('my_service', () => MyService());
  }

  @override
  Future<void> boot() async {
    // Perform async bootstrap logic here.
    //
    // IMPORTANT: Call setUserFactory() so Auth.user<T>() returns your model:
    //   Auth.manager.setUserFactory((data) => User.fromMap(data));
    // Magic Starter: Register user factory for auth session restoration.
    Auth.manager.setUserFactory((data) => User.fromMap(data));
    MagicStarter.useUserModel((data) => User.fromMap(data));

    // Magic Starter: Uptizm sidebar + mobile bottom bar navigation.
    // Four top-level surfaces; team switcher lives in the starter header.
    MagicStarter.useNavigation(
      mainItems: [
        MagicStarterNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          labelKey: 'nav.dashboard',
          path: MagicStarterConfig.homeRoute(),
        ),
        MagicStarterNavItem(
          icon: Icons.monitor_heart_outlined,
          activeIcon: Icons.monitor_heart,
          labelKey: 'nav.monitors',
          path: '/monitors',
        ),
        MagicStarterNavItem(
          icon: Icons.public_outlined,
          activeIcon: Icons.public,
          labelKey: 'nav.status_pages',
          path: '/status-pages',
        ),
        MagicStarterNavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          labelKey: 'nav.settings',
          path: '/settings',
        ),
      ],
      systemItems: const [],
      bottomItems: [
        MagicStarterNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          labelKey: 'nav.dashboard',
          path: MagicStarterConfig.homeRoute(),
        ),
        MagicStarterNavItem(
          icon: Icons.monitor_heart_outlined,
          activeIcon: Icons.monitor_heart,
          labelKey: 'nav.monitors',
          path: '/monitors',
        ),
        MagicStarterNavItem(
          icon: Icons.public_outlined,
          activeIcon: Icons.public,
          labelKey: 'nav.status_pages',
          path: '/status-pages',
        ),
        MagicStarterNavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          labelKey: 'nav.settings',
          path: '/settings',
        ),
      ],
      profileMenuItems: [
        MagicStarterNavItem(
          icon: Icons.settings_outlined,
          labelKey: 'settings.title',
          path: '/settings',
        ),
        MagicStarterNavItem(
          icon: Icons.auto_awesome_rounded,
          labelKey: 'settings.ai.title',
          path: '/settings/ai',
        ),
        MagicStarterNavItem(
          icon: Icons.analytics_outlined,
          labelKey: 'settings.metrics_library.title',
          path: '/settings/metrics-library',
        ),
        MagicStarterNavItem(
          icon: Icons.palette_outlined,
          labelKey: 'settings.appearance.title',
          path: '/settings/appearance',
        ),
      ],
    );

    // Magic Starter: Uptizm brand (wordmark + up-500 pulse dot).
    MagicStarter.useNavigationTheme(
      MagicStarterNavigationTheme(
        brandBuilder: (context) => WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WDiv(
              className: '''
                w-2.5 h-2.5 rounded-full
                bg-up-500 dark:bg-up-400
                animate-pulse
              ''',
            ),
            WText(
              trans('app.name'),
              className: '''
                text-lg font-bold tracking-tight
                text-gray-900 dark:text-white
              ''',
            ),
          ],
        ),
      ),
    );

    // Magic Starter: Borderless page header (Uptizm uses card surfaces below).
    MagicStarter.usePageHeaderTheme(
      const MagicStarterPageHeaderTheme(
        containerClassName:
            'w-full flex flex-col sm:flex-row items-start sm:items-center sm:justify-between gap-4 p-2 lg:p-4',
        containerInlineClassName:
            'w-full flex flex-row items-center justify-between gap-4 p-2 lg:p-4',
      ),
    );

    // Magic Starter: Logout callback.
    MagicStarter.useLogout(() async {
      await Auth.logout();
      MagicRoute.to(MagicStarterConfig.loginRoute());
    });

    // Magic Starter: Supported locale options for profile settings.
    MagicStarter.useLocaleOptions({'en': 'English'});

    // Magic Starter: Team resolver for sidebar team switcher.
    MagicStarter.useTeamResolver(
      currentTeam: () => User.current.currentTeam?.toMagicStarterTeam(),
      allTeams: () =>
          User.current.allTeams.map((t) => t.toMagicStarterTeam()).toList(),
      onSwitch: (teamId) =>
          MagicStarterTeamController.instance.switchTeam(teamId),
    );
  }
}
