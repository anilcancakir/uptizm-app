import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../components/common/app_back_button.dart';
import '../components/common/form_section_card.dart';

enum _ThemeMode { system, light, dark }

/// Appearance settings. Syncs with the WindTheme controller so the chosen
/// mode is reflected immediately across the whole app (dark: class pairs).
class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WindTheme.of(context);
    final data = controller.data;
    final current = data.syncWithSystem
        ? _ThemeMode.system
        : data.brightness == Brightness.light
            ? _ThemeMode.light
            : _ThemeMode.dark;

    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/settings'),
          title: trans('settings.appearance.title'),
          subtitle: trans('settings.appearance.subtitle'),
          inlineActions: true,
        ),
        FormSectionCard(
          titleKey: 'settings.appearance.section_theme_title',
          subtitleKey: 'settings.appearance.section_theme_subtitle',
          icon: Icons.palette_outlined,
          child: WDiv(
            className: 'flex flex-col gap-2',
            children: [
              _option(
                mode: _ThemeMode.system,
                current: current,
                icon: Icons.brightness_auto_outlined,
                titleKey: 'settings.appearance.mode_system_title',
                subtitleKey: 'settings.appearance.mode_system_subtitle',
                onSelect: () => controller.resetToSystem(),
              ),
              _option(
                mode: _ThemeMode.light,
                current: current,
                icon: Icons.light_mode_outlined,
                titleKey: 'settings.appearance.mode_light_title',
                subtitleKey: 'settings.appearance.mode_light_subtitle',
                onSelect: () => controller.setTheme(
                  data.copyWith(
                    brightness: Brightness.light,
                    syncWithSystem: false,
                  ),
                ),
              ),
              _option(
                mode: _ThemeMode.dark,
                current: current,
                icon: Icons.dark_mode_outlined,
                titleKey: 'settings.appearance.mode_dark_title',
                subtitleKey: 'settings.appearance.mode_dark_subtitle',
                onSelect: () => controller.setTheme(
                  data.copyWith(
                    brightness: Brightness.dark,
                    syncWithSystem: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _option({
    required _ThemeMode mode,
    required _ThemeMode current,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    required VoidCallback onSelect,
  }) {
    final isActive = mode == current;
    return WButton(
      onTap: () {
        if (isActive) return;
        onSelect();
        Magic.toast(trans('settings.appearance.toast_saved'));
      },
      states: isActive ? {'active'} : {},
      className: '''
        w-full px-4 py-3 rounded-lg
        bg-white dark:bg-gray-800
        border border-gray-200 dark:border-gray-700
        hover:bg-gray-50 dark:hover:bg-gray-900/40
        active:border-primary-500 dark:active:border-primary-400
        active:bg-primary-50/40 dark:active:bg-primary-900/20
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: isActive ? {'active'} : {},
            className: '''
              w-9 h-9 rounded-lg
              bg-gray-100 dark:bg-gray-900
              active:bg-primary-100 dark:active:bg-primary-900/40
              flex items-center justify-center
            ''',
            child: WIcon(
              icon,
              states: isActive ? {'active'} : {},
              className: '''
                text-base
                text-gray-600 dark:text-gray-300
                active:text-primary-600 dark:active:text-primary-300
              ''',
            ),
          ),
          WDiv(
            className: 'flex-1 flex flex-col gap-0.5 min-w-0',
            children: [
              WText(
                trans(titleKey),
                className: '''
                  text-sm font-semibold
                  text-gray-900 dark:text-white
                ''',
              ),
              WText(
                trans(subtitleKey),
                className: '''
                  text-xs
                  text-gray-500 dark:text-gray-400
                ''',
              ),
            ],
          ),
          WDiv(
            states: isActive ? {'active'} : {},
            className: '''
              w-5 h-5 rounded-full
              border-2
              border-gray-300 dark:border-gray-600
              active:border-primary-500 dark:active:border-primary-400
              active:bg-primary-500 dark:active:bg-primary-400
              flex items-center justify-center
            ''',
            child: isActive
                ? const WIcon(
                    Icons.check_rounded,
                    className: 'text-xs text-white',
                  )
                : const WSpacer(className: 'w-0 h-0'),
          ),
        ],
      ),
    );
  }
}
