import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/ai/ai_settings_controller.dart';
import '../../../app/enums/ai_mode.dart';
import '../components/ai/ai_mode_selector.dart';
import '../components/common/app_back_button.dart';
import '../components/common/form_section_card.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/common/setting_toggle_row.dart';

/// Workspace-level AI settings.
///
/// Drives the default AI autonomy mode and the daily digest flag. Backed by
/// `AiSettingsController` which mirrors the `/settings/ai` endpoint; the view
/// only holds the transient form snapshot and delegates submit to the
/// controller.
class SettingsAiView extends MagicStatefulView<AiSettingsController> {
  const SettingsAiView({super.key});

  @override
  State<SettingsAiView> createState() => _SettingsAiViewState();
}

class _SettingsAiViewState
    extends MagicStatefulViewState<AiSettingsController, SettingsAiView> {
  AiMode _default = AiMode.suggest;
  bool _digest = true;
  bool _hydrated = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.load();
      final loaded = controller.settings;
      if (!mounted || loaded == null) return;
      setState(() {
        _default = loaded.aiMode;
        _digest = loaded.dailyDigestEnabled;
        _hydrated = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/'),
          title: trans('settings.ai.title'),
          subtitle: trans('settings.ai.subtitle'),
          inlineActions: true,
          actions: [
            SecondaryButton(
              labelKey: 'settings.ai.activity_link',
              icon: Icons.history_rounded,
              onTap: () => MagicRoute.to('/settings/ai/activity'),
            ),
          ],
        ),
        _defaultModeSection(),
        _behaviorSection(),
        _previewSection(),
        _footer(),
      ],
    );
  }

  Widget _defaultModeSection() {
    return FormSectionCard(
      titleKey: 'settings.ai.default_mode.title',
      subtitleKey: 'settings.ai.default_mode.subtitle',
      icon: Icons.auto_awesome_rounded,
      child: WDiv(
        className: 'flex flex-col gap-3',
        children: [
          AiModeSelector(
            selected: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          WDiv(
            className: '''
              rounded-lg p-3
              bg-gray-50 dark:bg-gray-900
              border border-gray-200 dark:border-gray-700
              flex flex-row items-start gap-2
            ''',
            children: [
              WIcon(
                Icons.info_outline_rounded,
                className: 'text-sm text-gray-500 dark:text-gray-400',
              ),
              WDiv(
                className: 'flex-1',
                child: WText(
                  trans(_default.descriptionKey),
                  className: '''
                    text-xs leading-relaxed
                    text-gray-700 dark:text-gray-200
                  ''',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _behaviorSection() {
    return FormSectionCard(
      titleKey: 'settings.ai.behavior.title',
      subtitleKey: 'settings.ai.behavior.subtitle',
      icon: Icons.tune_rounded,
      child: SettingToggleRow(
        icon: Icons.summarize_outlined,
        titleKey: 'settings.ai.behavior.digest_title',
        subtitleKey: 'settings.ai.behavior.digest_subtitle',
        value: _digest,
        onChanged: (v) => setState(() => _digest = v),
      ),
    );
  }

  Widget _previewSection() {
    return FormSectionCard(
      titleKey: 'settings.ai.preview.title',
      subtitleKey: 'settings.ai.preview.subtitle',
      icon: Icons.visibility_outlined,
      child: WDiv(
        className: '''
          rounded-lg p-4
          bg-ai-50/50 dark:bg-ai-900/20
          border border-ai-200/60 dark:border-ai-800/40
          flex flex-col gap-2
        ''',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-2',
            children: [
              WIcon(
                Icons.auto_awesome_rounded,
                className: 'text-sm text-ai-600 dark:text-ai-300',
              ),
              WText(
                trans('ai.actor_name'),
                className: '''
                  text-xs font-semibold
                  text-ai-700 dark:text-ai-300
                ''',
              ),
              WText('•', className: 'text-xs text-gray-400 dark:text-gray-500'),
              WText(
                trans('ai.confidence.high'),
                className: 'text-xs text-gray-500 dark:text-gray-400',
              ),
            ],
          ),
          WText(
            trans(_previewKeyForMode(_default)),
            className: '''
              text-sm leading-relaxed
              text-gray-800 dark:text-gray-100
            ''',
          ),
        ],
      ),
    );
  }

  String _previewKeyForMode(AiMode mode) {
    return switch (mode) {
      AiMode.off => 'settings.ai.preview.sample_off',
      AiMode.suggest => 'settings.ai.preview.sample_suggest',
      AiMode.auto => 'settings.ai.preview.sample_auto',
    };
  }

  Widget _footer() {
    return WDiv(
      className: 'w-full flex flex-row items-center justify-end gap-3 pt-2',
      children: [
        PrimaryButton(
          labelKey: 'common.save',
          icon: Icons.check_rounded,
          isLoading: controller.isSubmitting,
          isDisabled: !_hydrated,
          onTap: _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (controller.isSubmitting) return;
    final ok = await controller.submit(aiMode: _default, dailyDigest: _digest);
    if (!mounted) return;
    if (ok) {
      Magic.toast(trans('settings.ai.toast_saved'));
      return;
    }
    if (!controller.hasErrors) {
      Magic.toast(trans('settings.ai.errors.generic_update'));
    }
  }
}
