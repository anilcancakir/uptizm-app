import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/monitors/monitor_controller.dart';
import '../../../app/controllers/status_pages/status_pages_controller.dart';
import '../../../app/helpers/slugify.dart';
import '../components/common/app_back_button.dart';
import '../components/common/form_field_label.dart';
import '../components/common/form_section_card.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/common/setting_toggle_row.dart';
import '../components/status_pages/color_chip_grid.dart';
import '../components/status_pages/logo_upload_zone.dart';
import '../components/status_pages/monitor_assign_list.dart';

/// Create a new status page.
///
/// Holds only the transient field values; [StatusPagesController.submitCreate]
/// builds the payload, owns the `isSubmitting` flag, and surfaces 422 field
/// errors via `getError`.
class StatusPageCreateView extends MagicStatefulView<StatusPagesController> {
  const StatusPageCreateView({super.key});

  @override
  State<StatusPageCreateView> createState() => _StatusPageCreateViewState();
}

class _StatusPageCreateViewState
    extends
        MagicStatefulViewState<StatusPagesController, StatusPageCreateView> {
  final _titleCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  bool _slugTouched = false;
  bool _isPublic = true;
  String _primaryColor = '#2563EB';
  String? _logoPath;
  final Set<String> _selectedMonitors = {};

  MonitorController get _monitors => MonitorController.instance;

  static const _inputClass = '''
    w-full px-3 py-2.5 rounded-lg
    bg-white dark:bg-gray-900
    border border-gray-200 dark:border-gray-700
    text-sm text-gray-900 dark:text-white
    focus:border-primary-500 dark:focus:border-primary-400
  ''';

  @override
  void onInit() {
    super.onInit();
    _titleCtrl.addListener(_syncSlugFromTitle);
    WidgetsBinding.instance.addPostFrameCallback((_) => _monitors.loadList());
  }

  @override
  void onClose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    super.onClose();
  }

  void _syncSlugFromTitle() {
    if (_slugTouched) return;
    final s = slugify(_titleCtrl.text);
    if (s != _slugCtrl.text) {
      _slugCtrl.value = _slugCtrl.value.copyWith(
        text: s,
        selection: TextSelection.collapsed(offset: s.length),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: const AppBackButton(fallbackPath: '/status-pages'),
          title: trans('status_page.create.title'),
          subtitle: trans('status_page.create.subtitle'),
          inlineActions: true,
        ),
        _basicsSection(),
        _brandingSection(),
        _assignSection(),
        _footer(),
      ],
    );
  }

  Widget _basicsSection() {
    final slugError = validateSlug(_slugCtrl.text);
    return FormSectionCard(
      titleKey: 'status_page.create.basics.title',
      subtitleKey: 'status_page.create.basics.subtitle',
      icon: Icons.edit_note_rounded,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'status_page.create.fields.title',
                required: true,
              ),
              WInput(
                value: _titleCtrl.text,
                onChanged: (v) => _titleCtrl.text = v,
                placeholder: trans(
                  'status_page.create.fields.title_placeholder',
                ),
                className: _inputClass,
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'status_page.create.fields.slug',
                required: true,
              ),
              WInput(
                value: _slugCtrl.text,
                onChanged: (v) {
                  _slugTouched = true;
                  _slugCtrl.text = v;
                  setState(() {});
                },
                placeholder: trans(
                  'status_page.create.fields.slug_placeholder',
                ),
                className: _inputClass,
              ),
              WDiv(
                className: 'mt-1.5 flex flex-col gap-0.5',
                children: [
                  if (slugError != null && _slugCtrl.text.isNotEmpty)
                    WText(
                      trans(slugError),
                      className: '''
                        text-xs
                        text-down-600 dark:text-down-400
                      ''',
                    )
                  else if (_slugCtrl.text.isNotEmpty)
                    WText(
                      '${_slugCtrl.text}.uptizm.com',
                      className: '''
                        text-xs font-mono
                        text-gray-500 dark:text-gray-400
                      ''',
                    )
                  else
                    WText(
                      trans('status_page.create.fields.slug_hint'),
                      className: '''
                        text-xs
                        text-gray-500 dark:text-gray-400
                      ''',
                    ),
                ],
              ),
            ],
          ),
          SettingToggleRow(
            icon: Icons.public_rounded,
            titleKey: 'status_page.create.fields.public_title',
            subtitleKey: 'status_page.create.fields.public_subtitle',
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
        ],
      ),
    );
  }

  Widget _brandingSection() {
    return FormSectionCard(
      titleKey: 'status_page.create.branding.title',
      subtitleKey: 'status_page.create.branding.subtitle',
      icon: Icons.palette_rounded,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'status_page.create.fields.primary_color',
              ),
              ColorChipGrid(
                selected: _primaryColor,
                onChanged: (hex) => setState(() => _primaryColor = hex),
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(labelKey: 'status_page.create.fields.logo'),
              LogoUploadZone(
                logoPath: _logoPath,
                onPick: () =>
                    setState(() => _logoPath = 'mock://logo/uploaded.png'),
                onClear: () => setState(() => _logoPath = null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assignSection() {
    return FormSectionCard(
      titleKey: 'status_page.create.assign.title',
      subtitleKey: 'status_page.create.assign.subtitle',
      icon: Icons.monitor_heart_outlined,
      child: ValueListenableBuilder(
        valueListenable: _monitors.list,
        builder: (_, options, _) => MonitorAssignList(
          options: options,
          selected: _selectedMonitors,
          onToggle: (id) => setState(() {
            if (!_selectedMonitors.remove(id)) {
              _selectedMonitors.add(id);
            }
          }),
        ),
      ),
    );
  }

  Widget _footer() {
    return WDiv(
      className: '''
        w-full flex flex-row items-center justify-end gap-3 pt-2
      ''',
      children: [
        SecondaryButton(
          labelKey: 'common.cancel',
          onTap: () => MagicRoute.to('/status-pages'),
        ),
        PrimaryButton(
          labelKey: 'status_page.create.submit',
          icon: Icons.check_rounded,
          isLoading: controller.isSubmitting,
          onTap: _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (controller.isSubmitting) return;
    final created = await controller.submitCreate(
      title: _titleCtrl.text,
      slug: _slugCtrl.text,
      primaryColor: _primaryColor,
      logoPath: _logoPath,
      isPublic: _isPublic,
      monitorIds: _selectedMonitors.toList(),
    );
    if (!mounted) return;
    if (created == null) {
      if (!controller.hasErrors) {
        Magic.toast(
          controller.rxStatus.message ??
              trans('status_page.errors.generic_create'),
        );
      }
      return;
    }
    Magic.toast(trans('status_page.create.toast_created'));
    MagicRoute.to('/status-pages/${created.id}');
  }
}
