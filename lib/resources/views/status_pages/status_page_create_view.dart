import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/helpers/slugify.dart';
import '../../../app/models/mock/status_page.dart';
import '../components/common/app_back_button.dart';
import '../components/common/form_field_label.dart';
import '../components/common/form_section_card.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/common/setting_toggle_row.dart';
import '../components/status_pages/color_chip_grid.dart';
import '../components/status_pages/logo_upload_zone.dart';
import '../components/status_pages/monitor_assign_list.dart';

/// Create a new status page. Mock behavior: submits a toast + navigates to
/// the sample show page.
class StatusPageCreateView extends StatefulWidget {
  const StatusPageCreateView({super.key});

  @override
  State<StatusPageCreateView> createState() => _StatusPageCreateViewState();
}

class _StatusPageCreateViewState extends State<StatusPageCreateView> {
  final _titleCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  bool _slugTouched = false;
  bool _isPublic = true;
  String _primaryColor = '#2563EB';
  String? _logoPath;
  final Set<String> _selectedMonitors = {};

  late final _monitorOptions = StatusPageMonitorOption.mockAll();

  static const _inputClass = '''
    w-full px-3 py-2.5 rounded-lg
    bg-white dark:bg-gray-900
    border border-gray-200 dark:border-gray-700
    text-sm text-gray-900 dark:text-white
    focus:border-primary-500 dark:focus:border-primary-400
  ''';

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_syncSlugFromTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
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
              const FormFieldLabel(
                labelKey: 'status_page.create.fields.logo',
              ),
              LogoUploadZone(
                logoPath: _logoPath,
                onPick: () => setState(
                  () => _logoPath = 'mock://logo/uploaded.png',
                ),
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
      child: MonitorAssignList(
        options: _monitorOptions,
        selected: _selectedMonitors,
        onToggle: (id) => setState(() {
          if (!_selectedMonitors.remove(id)) {
            _selectedMonitors.add(id);
          }
        }),
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
          onTap: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final slugError = validateSlug(_slugCtrl.text);
    if (_titleCtrl.text.trim().isEmpty) {
      Magic.toast(trans('status_page.validation.title_required'));
      return;
    }
    if (slugError != null) {
      Magic.toast(trans(slugError));
      return;
    }
    Magic.toast(trans('status_page.create.toast_created'));
    MagicRoute.to('/status-pages/sample');
  }
}
