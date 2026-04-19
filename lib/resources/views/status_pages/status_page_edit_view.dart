import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/monitors/monitor_controller.dart';
import '../../../app/controllers/status_pages/status_pages_controller.dart';
import '../../../app/models/status_page.dart';
import '../components/common/app_back_button.dart';
import '../components/common/color_swatch.dart';
import '../components/common/error_banner.dart';
import '../components/common/form_field_error.dart';
import '../components/common/form_field_label.dart';
import '../components/common/form_section_card.dart';
import '../components/common/primary_button.dart';
import '../components/common/secondary_button.dart';
import '../components/common/setting_toggle_row.dart';
import '../components/common/skeleton_block.dart';
import '../components/status_pages/logo_upload_zone.dart';
import '../components/status_pages/metric_assign_list.dart';
import '../components/status_pages/monitor_assign_list.dart';

/// Edit an existing status page.
///
/// Preloads detail via [StatusPagesController.loadOne] and seeds form state
/// from the fetched record. Submits through
/// [StatusPagesController.submitUpdate] which mirrors the server-side
/// partial-update semantics.
class StatusPageEditView extends StatefulWidget {
  const StatusPageEditView({super.key, required this.statusPageId});

  final String statusPageId;

  @override
  State<StatusPageEditView> createState() => _StatusPageEditViewState();
}

class _StatusPageEditViewState extends State<StatusPageEditView> {
  StatusPagesController get _c => StatusPagesController.instance;
  MonitorController get _monitors => MonitorController.instance;

  final _titleCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  bool _isPublic = false;
  String _primaryColor = '#2563EB';
  String? _logoPath;
  Uint8List? _logoBytes;
  bool _isUploadingLogo = false;
  final Set<String> _selectedMonitors = {};
  final Set<String> _selectedMetrics = {};
  bool _seeded = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _c.loadOne(widget.statusPageId);
      await _monitors.loadList();
      _seedFromDetail();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  void _seedFromDetail() {
    final page = _c.detail;
    if (page == null || _seeded) return;
    _seeded = true;
    _titleCtrl.text = page.title;
    _slugCtrl.text = page.slug;
    _primaryColor = page.primaryColor;
    _logoPath = page.logoPath;
    _isPublic = page.isPublic;
    _selectedMonitors
      ..clear()
      ..addAll(page.monitorIds);
    _selectedMetrics
      ..clear()
      ..addAll(page.metricIds);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final page = _c.detail;
        if (_c.rxStatus.isError && page == null) {
          return WDiv(
            className: 'p-4 lg:p-6',
            child: ErrorBanner(
              message: _c.rxStatus.message,
              onRetry: () => _c.loadOne(widget.statusPageId),
            ),
          );
        }
        if (!_seeded && page != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _seedFromDetail(),
          );
        }
        if (page == null) {
          return _skeleton();
        }
        return _body(page);
      },
    );
  }

  Widget _skeleton() {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: const [
        SkeletonBlock(className: 'w-1/3 h-6'),
        SkeletonBlock(className: 'w-full h-32 rounded-xl'),
        SkeletonBlock(className: 'w-full h-40 rounded-xl'),
      ],
    );
  }

  Widget _body(StatusPage page) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        MagicStarterPageHeader(
          leading: AppBackButton(fallbackPath: '/status-pages/${page.id}'),
          title: trans('status_page.edit.title'),
          subtitle: trans('status_page.edit.subtitle'),
          inlineActions: true,
        ),
        _basicsSection(),
        _brandingSection(),
        _assignSection(),
        _metricsSection(),
        _footer(page.id),
      ],
    );
  }

  Widget _basicsSection() {
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
                onChanged: (v) => setState(() => _titleCtrl.text = v),
                placeholder: trans(
                  'status_page.create.fields.title_placeholder',
                ),
                className: _inputClass,
              ),
              FormFieldError(message: _c.getError('title')),
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
                onChanged: (v) => setState(() => _slugCtrl.text = v),
                placeholder: trans(
                  'status_page.create.fields.slug_placeholder',
                ),
                className: _inputClass,
              ),
              FormFieldError(message: _c.getError('slug')),
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
              WDiv(
                className: 'flex flex-row items-center gap-2',
                children: [
                  HexSwatch(hex: _primaryColor, size: 'sm', shape: 'square'),
                  WDiv(
                    className: 'flex-1',
                    child: WInput(
                      value: _primaryColor,
                      onChanged: (v) => setState(() => _primaryColor = v),
                      placeholder: '#2563EB',
                      className: _inputClass,
                    ),
                  ),
                ],
              ),
              FormFieldError(message: _c.getError('primary_color')),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(labelKey: 'status_page.create.fields.logo'),
              LogoUploadZone(
                logoPath: _logoPath,
                previewBytes: _logoBytes,
                isUploading: _isUploadingLogo,
                onPick: _pickAndUploadLogo,
                onClear: () => setState(() {
                  _logoPath = null;
                  _logoBytes = null;
                }),
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
            _selectedMetrics.removeWhere((_) => false);
          }),
        ),
      ),
    );
  }

  Widget _metricsSection() {
    return FormSectionCard(
      titleKey: 'status_page.create.metrics_section.title',
      subtitleKey: 'status_page.create.metrics_section.subtitle',
      icon: Icons.insights_rounded,
      child: ValueListenableBuilder(
        valueListenable: _monitors.list,
        builder: (_, options, _) => MetricAssignList(
          monitors: options,
          monitorIds: _selectedMonitors,
          selected: _selectedMetrics,
          onToggle: (id) => setState(() {
            if (!_selectedMetrics.remove(id)) {
              _selectedMetrics.add(id);
            }
          }),
        ),
      ),
    );
  }

  Widget _footer(String id) {
    return WDiv(
      className: '''
        w-full flex flex-row items-center justify-end gap-3 pt-2
      ''',
      children: [
        SecondaryButton(
          labelKey: 'common.cancel',
          onTap: () => MagicRoute.to('/status-pages/$id'),
        ),
        PrimaryButton(
          labelKey: 'status_page.edit.submit',
          icon: Icons.check_rounded,
          isLoading: _c.isSubmitting,
          onTap: () => _submit(id),
        ),
      ],
    );
  }

  static const _maxLogoBytes = 1024 * 1024;

  Future<void> _pickAndUploadLogo() async {
    if (_isUploadingLogo) return;
    final file = await Pick.image();
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes == null || bytes.isEmpty) {
      Magic.toast(trans('status_page.errors.generic_logo_upload'));
      return;
    }
    if (bytes.length > _maxLogoBytes) {
      Magic.toast(trans('status_page.create.logo.too_large'));
      return;
    }

    setState(() => _isUploadingLogo = true);
    try {
      final path = await _c.uploadLogo(file);
      if (!mounted) return;
      if (path != null) {
        setState(() {
          _logoPath = path;
          _logoBytes = bytes;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  Future<void> _submit(String id) async {
    if (_c.isSubmitting) return;
    final updated = await _c.submitUpdate(
      id: id,
      title: _titleCtrl.text,
      slug: _slugCtrl.text,
      primaryColor: _primaryColor,
      logoPath: _logoPath,
      isPublic: _isPublic,
      monitorIds: _selectedMonitors.toList(),
      metricIds: _selectedMetrics.toList(),
    );
    if (!mounted) return;
    if (updated == null) {
      if (!_c.hasErrors) {
        Magic.toast(
          _c.rxStatus.message ?? trans('status_page.errors.generic_update'),
        );
      }
      return;
    }
    Magic.toast(trans('status_page.edit.save_success'));
    MagicRoute.to('/status-pages/$id');
  }
}
