import 'package:magic/magic.dart';
import 'package:flutter/material.dart';
import 'package:magic_starter/magic_starter.dart';
import '../controllers/metrics/metrics_library_controller.dart';
import '../controllers/metrics/monitor_metric_controller.dart';
import '../models/user.dart';

/// Application Service Provider.
///
/// Use this provider to bind your own services to the IoC container and
/// to perform any bootstrap logic that requires other services to be ready.
class AppServiceProvider extends ServiceProvider {
  AppServiceProvider(super.app);

  /// Synchronous bindings. Pre-instantiates metrics controllers so nested
  /// tabs (MonitorMetricsTab, SettingsMetricsLibraryView) can resolve them
  /// via `Magic.find<T>()` before their `initState` runs.
  @override
  void register() {
    MonitorMetricController.instance;
    MetricsLibraryController.instance;
  }

  /// Async bootstrap. Configures auth, navigation, brand theme, page header
  /// theme, logout, locale, and team resolver in the Magic Starter plugin.
  ///
  /// 1. Auth: register the user factory so `Auth.user<User>()` and Magic
  ///    Starter's session restoration hydrate the concrete model.
  /// 2. Navigation: sidebar / mobile bottom bar / profile menu entries.
  /// 3. Brand + page header theme: Uptizm wordmark and borderless header.
  /// 4. Logout, locales, team resolver.
  @override
  Future<void> boot() async {
    Auth.manager.setUserFactory((data) => User.fromMap(data));
    MagicStarter.useUserModel((data) => User.fromMap(data));

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

    // Magic Starter: Borderless page header (Uptizm uses card surfaces below)
    // and `tablet:` stacking (Uptizm only defines the `tablet` breakpoint,
    // upstream default `sm:flex-row` is a no-op here). Title/subtitle wrapping
    // is handled by the upstream `line-clamp-2` defaults since alpha.14.
    MagicStarter.usePageHeaderTheme(
      const MagicStarterPageHeaderTheme(
        containerClassName: '''
          w-full flex flex-col tablet:flex-row
          items-start tablet:items-center tablet:justify-between
          gap-4 p-2 lg:p-4
        ''',
        containerInlineClassName: '''
          w-full flex flex-row items-center justify-between
          gap-4 p-2 lg:p-4
        ''',
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
