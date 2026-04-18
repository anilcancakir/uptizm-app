import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/settings/appearance_controller.dart';
import '../components/common/app_back_button.dart';
import '../components/common/form_section_card.dart';
import '../components/common/primary_button.dart';

enum _ThemeMode { system, light, dark }

/// Appearance preferences: theme mode (system / light / dark) and accent
/// color. Persists via [AppearanceController] and reflects changes
/// immediately through Wind UI's theme stream.
class SettingsAppearanceView extends StatefulWidget {
  const SettingsAppearanceView({super.key});

  @override
  State<SettingsAppearanceView> createState() => _SettingsAppearanceViewState();
}

class _SettingsAppearanceViewState extends State<SettingsAppearanceView> {
  AppearanceController get _c => AppearanceController.instance;

  final _color = TextEditingController();
  final _logo = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.load().then((_) => _onControllerChanged());
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _color.dispose();
    _logo.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final s = _c.settings;
    if (s == null || _hydrated) return;
    _hydrated = true;
    _color.text = s.primaryColor ?? '';
    _logo.text = s.logoPath ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await _c.update({
      'appearance_primary_color': _color.text.trim(),
      'appearance_logo_path': _logo.text.trim().isEmpty
          ? null
          : _logo.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Magic.toast(trans('settings.appearance.brand_saved'));
    } else {
      Magic.toast(trans('settings.appearance.errors.generic_update'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = WindTheme.of(context);
    final data = themeController.data;
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
                onSelect: () => themeController.resetToSystem(),
              ),
              _option(
                mode: _ThemeMode.light,
                current: current,
                icon: Icons.light_mode_outlined,
                titleKey: 'settings.appearance.mode_light_title',
                subtitleKey: 'settings.appearance.mode_light_subtitle',
                onSelect: () => themeController.setTheme(
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
                onSelect: () => themeController.setTheme(
                  data.copyWith(
                    brightness: Brightness.dark,
                    syncWithSystem: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        FormSectionCard(
          titleKey: 'settings.appearance.section_brand_title',
          subtitleKey: 'settings.appearance.section_brand_subtitle',
          icon: Icons.brush_outlined,
          child: WDiv(
            className: 'flex flex-col gap-4',
            children: [
              _field(
                labelKey: 'settings.appearance.brand_color_label',
                hintKey: 'settings.appearance.brand_color_hint',
                controller: _color,
                placeholder: '#2563eb',
                errorKey: 'appearance_primary_color',
              ),
              _field(
                labelKey: 'settings.appearance.brand_logo_label',
                hintKey: 'settings.appearance.brand_logo_hint',
                controller: _logo,
                placeholder: 'logos/team.png',
                errorKey: 'appearance_logo_path',
              ),
              WDiv(
                className: 'flex flex-row justify-end',
                child: PrimaryButton(
                  labelKey: 'settings.appearance.brand_save',
                  icon: Icons.save_rounded,
                  isLoading: _saving,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String labelKey,
    required String hintKey,
    required TextEditingController controller,
    required String placeholder,
    required String errorKey,
  }) {
    final err = _c.getError(errorKey);
    return WDiv(
      className: 'flex flex-col gap-1.5',
      children: [
        WText(
          trans(labelKey),
          className: '''
            text-xs font-semibold uppercase tracking-wide
            text-gray-500 dark:text-gray-400
          ''',
        ),
        WInput(
          controller: controller,
          placeholder: placeholder,
          className: '''
            w-full px-3 py-2.5 rounded-lg text-sm
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
            focus:border-primary-500 dark:focus:border-primary-400
          ''',
        ),
        WText(
          err ?? trans(hintKey),
          className: err == null
              ? 'text-xs text-gray-500 dark:text-gray-400'
              : 'text-xs text-down-600 dark:text-down-400',
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
