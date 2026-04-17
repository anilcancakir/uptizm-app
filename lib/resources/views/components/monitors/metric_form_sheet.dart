import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/metric_source.dart';
import '../../../../app/enums/metric_type.dart';
import '../../../../app/enums/threshold_direction.dart';
import '../common/form_field_label.dart';
import '../common/form_section_card.dart';
import '../common/primary_button.dart';
import '../common/secondary_button.dart';
import '../common/segmented_choice.dart';
import 'live_preview_card.dart';
import 'threshold_band_editor.dart';

/// Pre-filled values when opening the sheet for edit/duplicate.
class MetricFormInitial {
  const MetricFormInitial({
    this.label = '',
    this.key = '',
    this.group = '',
    this.source = MetricSource.jsonPath,
    this.path = '',
    this.fallback = '',
    this.type = MetricType.numeric,
    this.unit = '',
    this.direction = ThresholdDirection.highBad,
    this.warn = '',
    this.critical = '',
  });

  final String label;
  final String key;
  final String group;
  final MetricSource source;
  final String path;
  final String fallback;
  final MetricType type;
  final String unit;
  final ThresholdDirection direction;
  final String warn;
  final String critical;
}

/// Bottom sheet for creating / editing / duplicating a custom metric.
///
/// Design-first mockup: local state only, no persistence. The "save" action
/// just pops the sheet and shows a toast.
class MetricFormSheet extends StatefulWidget {
  const MetricFormSheet({
    super.key,
    required this.mode,
    required this.existingGroups,
    this.initial = const MetricFormInitial(),
  });

  /// 'create' | 'edit' | 'duplicate'
  final String mode;
  final List<String> existingGroups;
  final MetricFormInitial initial;

  static Future<void> show(
    BuildContext context, {
    required String mode,
    required List<String> existingGroups,
    MetricFormInitial initial = const MetricFormInitial(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MetricFormSheet(
        mode: mode,
        existingGroups: existingGroups,
        initial: initial,
      ),
    );
  }

  @override
  State<MetricFormSheet> createState() => _MetricFormSheetState();
}

class _MetricFormSheetState extends State<MetricFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _key;
  late final TextEditingController _group;
  late final TextEditingController _path;
  late final TextEditingController _fallback;
  late final TextEditingController _unit;
  late final TextEditingController _warn;
  late final TextEditingController _critical;

  late MetricSource _source;
  late MetricType _type;
  late ThresholdDirection _direction;
  bool _keyManuallyEdited = false;
  bool _groupDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _label = TextEditingController(text: i.label);
    _key = TextEditingController(text: i.key);
    _group = TextEditingController(text: i.group);
    _path = TextEditingController(text: i.path);
    _fallback = TextEditingController(text: i.fallback);
    _unit = TextEditingController(text: i.unit);
    _warn = TextEditingController(text: i.warn);
    _critical = TextEditingController(text: i.critical);
    _source = i.source;
    _type = i.type;
    _direction = i.direction;
    _keyManuallyEdited = i.key.isNotEmpty;
  }

  @override
  void dispose() {
    _label.dispose();
    _key.dispose();
    _group.dispose();
    _path.dispose();
    _fallback.dispose();
    _unit.dispose();
    _warn.dispose();
    _critical.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return replaced.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _onLabelChanged(String v) {
    _label.text = v;
    if (!_keyManuallyEdited) {
      setState(() => _key.text = _slugify(v));
    }
  }

  void _onKeyChanged(String v) {
    _key.text = v;
    setState(() => _keyManuallyEdited = v.isNotEmpty);
  }

  String get _titleKey => switch (widget.mode) {
        'edit' => 'monitor.metric_form.title.edit',
        'duplicate' => 'monitor.metric_form.title.duplicate',
        _ => 'monitor.metric_form.title.create',
      };

  String get _submitKey => switch (widget.mode) {
        'edit' => 'monitor.metric_form.submit.edit',
        _ => 'monitor.metric_form.submit.create',
      };

  bool get _hasParseRule => _path.text.trim().isNotEmpty;

  void _onSubmit() {
    final keyError = MetricType.validateMetricKey(_key.text.trim());
    if (keyError != null) {
      Magic.error(
        trans('monitor.metric_form.toast_invalid'),
        trans(keyError),
      );
      return;
    }
    if (_type == MetricType.numeric) {
      final warn = double.tryParse(_warn.text.trim());
      final critical = double.tryParse(_critical.text.trim());
      if (warn != null && critical != null) {
        final thresholdError = ThresholdDirection.validate(
          _direction,
          warn,
          critical,
        );
        if (thresholdError != null) {
          Magic.error(
            trans('monitor.metric_form.toast_invalid'),
            trans(thresholdError),
          );
          return;
        }
      }
    }
    MagicRoute.back();
    Magic.toast(trans('monitor.metric_form.toast_saved'));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return WDiv(
          className: '''
            bg-white dark:bg-gray-900
            rounded-t-2xl
            flex flex-col h-full
          ''',
          children: [
            _grabber(),
            _header(),
            WDiv(
              className: 'flex-1 overflow-y-auto',
              scrollPrimary: true,
              child: WDiv(
                className: 'flex flex-col gap-4 p-4 lg:p-6',
                children: [
                  _basicsSection(),
                  _parseSection(),
                  _typeSection(),
                  if (_type == MetricType.numeric) _thresholdSection(),
                  _previewSection(),
                  const WSpacer(),
                ],
              ),
            ),
            _footer(),
          ],
        );
      },
    );
  }

  Widget _grabber() {
    return WDiv(
      className: 'w-full flex flex-row justify-center py-3',
      child: WDiv(
        className: '''
          w-10 h-1 rounded-full
          bg-gray-300 dark:bg-gray-700
        ''',
      ),
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 lg:px-6 pb-3
        flex flex-row items-start justify-between gap-3
        border-b border-gray-200 dark:border-gray-800
      ''',
      children: [
        WDiv(
          className: 'flex-1 flex flex-col gap-1 min-w-0',
          children: [
            WText(
              trans(_titleKey),
              className: '''
                text-lg font-bold
                text-gray-900 dark:text-white truncate
              ''',
            ),
            WText(
              trans('monitor.metric_form.subtitle'),
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          ],
        ),
        WButton(
          onTap: () => MagicRoute.back(),
          className: '''
            w-9 h-9 rounded-lg
            bg-gray-100 dark:bg-gray-800
            hover:bg-gray-200 dark:hover:bg-gray-700
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.close_rounded,
            className: 'text-base text-gray-600 dark:text-gray-300',
          ),
        ),
      ],
    );
  }

  Widget _basicsSection() {
    return FormSectionCard(
      titleKey: 'monitor.metric_form.basics.title',
      subtitleKey: 'monitor.metric_form.basics.subtitle',
      icon: Icons.label_outline_rounded,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.metric_form.fields.label',
                hintKey: 'monitor.metric_form.fields.label_hint',
                required: true,
              ),
              WInput(
                value: _label.text,
                onChanged: _onLabelChanged,
                placeholder: 'DB connections',
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.metric_form.fields.key',
                hintKey: 'monitor.metric_form.fields.key_hint',
              ),
              WDiv(
                className: '''
                  flex flex-row items-center gap-2
                  bg-white dark:bg-gray-900/40
                  border border-gray-200 dark:border-gray-700
                  rounded-lg px-3
                ''',
                children: [
                  WIcon(
                    Icons.tag_rounded,
                    className: 'text-sm text-gray-400 dark:text-gray-500',
                  ),
                  WDiv(
                    className: 'flex-1',
                    child: WInput(
                      value: _key.text,
                      onChanged: _onKeyChanged,
                      placeholder: 'db_connections',
                      className: 'border-0 bg-transparent px-0',
                    ),
                  ),
                  if (_keyManuallyEdited && _label.text.isNotEmpty)
                    WButton(
                      onTap: () {
                        setState(() {
                          _keyManuallyEdited = false;
                          _key.text = _slugify(_label.text);
                        });
                      },
                      className: '''
                        px-2 py-1 rounded-md
                        hover:bg-gray-100 dark:hover:bg-gray-800
                      ''',
                      child: WText(
                        trans('monitor.metric_form.fields.key_reset'),
                        className: '''
                          text-xs font-semibold
                          text-primary dark:text-primary-300
                        ''',
                      ),
                    ),
                ],
              ),
            ],
          ),
          _groupCombobox(),
        ],
      ),
    );
  }

  Widget _groupCombobox() {
    final suggestions = widget.existingGroups
        .where((g) => g.toLowerCase().contains(_group.text.toLowerCase()))
        .toList();
    final canCreate = _group.text.trim().isNotEmpty &&
        !widget.existingGroups
            .any((g) => g.toLowerCase() == _group.text.toLowerCase());

    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'monitor.metric_form.fields.group',
          hintKey: 'monitor.metric_form.fields.group_hint',
        ),
        WDiv(
          className: '''
            flex flex-row items-center gap-2
            bg-white dark:bg-gray-900/40
            border border-gray-200 dark:border-gray-700
            rounded-lg px-3
          ''',
          children: [
            WIcon(
              Icons.folder_outlined,
              className: 'text-sm text-gray-400 dark:text-gray-500',
            ),
            WDiv(
              className: 'flex-1',
              child: WInput(
                value: _group.text,
                onChanged: (v) => setState(() {
                  _group.text = v;
                  _groupDropdownOpen = true;
                }),
                placeholder: 'Database',
                className: 'border-0 bg-transparent px-0',
              ),
            ),
            WButton(
              onTap: () =>
                  setState(() => _groupDropdownOpen = !_groupDropdownOpen),
              className: '''
                w-7 h-7 rounded-md
                hover:bg-gray-100 dark:hover:bg-gray-800
                flex items-center justify-center
              ''',
              child: WIcon(
                _groupDropdownOpen
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                className: 'text-base text-gray-500 dark:text-gray-400',
              ),
            ),
          ],
        ),
        if (_groupDropdownOpen) _groupDropdown(suggestions, canCreate),
      ],
    );
  }

  Widget _groupDropdown(List<String> suggestions, bool canCreate) {
    return WDiv(
      className: '''
        mt-1 p-1 rounded-lg
        bg-white dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
        flex flex-col gap-0.5
      ''',
      children: [
        for (final g in suggestions) _groupItem(g, isExisting: true),
        if (canCreate) _groupItem(_group.text, isExisting: false),
        if (suggestions.isEmpty && !canCreate)
          WDiv(
            className: 'px-3 py-2',
            child: WText(
              trans('monitor.metric_form.fields.group_empty'),
              className: 'text-xs text-gray-500 dark:text-gray-400',
            ),
          ),
      ],
    );
  }

  Widget _groupItem(String name, {required bool isExisting}) {
    final isSelected = _group.text.toLowerCase() == name.toLowerCase();
    return WButton(
      onTap: () => setState(() {
        _group.text = name;
        _groupDropdownOpen = false;
      }),
      states: isSelected ? {'selected'} : {},
      className: '''
        w-full px-3 py-2 rounded-md
        flex flex-row items-center gap-2
        hover:bg-gray-100 dark:hover:bg-gray-800
        selected:bg-primary-50 dark:selected:bg-primary-900/30
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-2 w-full',
        children: [
          WIcon(
            isExisting ? Icons.folder_outlined : Icons.add_rounded,
            states: isSelected ? {'selected'} : {},
            className: '''
              text-sm text-gray-400 dark:text-gray-500
              selected:text-primary dark:selected:text-primary-300
            ''',
          ),
          WDiv(
            className: 'flex-1',
            child: WText(
              isExisting
                  ? name
                  : trans(
                      'monitor.metric_form.fields.group_create',
                      {'name': name},
                    ),
              states: isSelected ? {'selected'} : {},
              className: '''
                text-sm
                text-gray-700 dark:text-gray-200
                selected:text-primary-700 dark:selected:text-primary-300
                selected:font-semibold
              ''',
            ),
          ),
          if (isSelected)
            WIcon(
              Icons.check_rounded,
              className: 'text-sm text-primary dark:text-primary-300',
            ),
        ],
      ),
    );
  }

  Widget _parseSection() {
    return FormSectionCard(
      titleKey: 'monitor.metric_form.parse.title',
      subtitleKey: 'monitor.metric_form.parse.subtitle',
      icon: Icons.alt_route_rounded,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.metric_form.fields.source',
                hintKey: 'monitor.metric_form.fields.source_hint',
              ),
              SegmentedChoice<MetricSource>(
                options: MetricSource.values,
                selected: _source,
                onChanged: (v) => setState(() => _source = v),
                labelBuilder: (v) => trans(v.labelKey),
                iconBuilder: (v) => switch (v) {
                  MetricSource.jsonPath => Icons.data_object_rounded,
                  MetricSource.regex => Icons.code_rounded,
                  MetricSource.xpath => Icons.account_tree_outlined,
                  MetricSource.header => Icons.http_rounded,
                },
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              FormFieldLabel(
                labelKey: 'monitor.metric_form.fields.path',
                hintKey: 'monitor.metric_form.fields.path_hint',
                required: true,
              ),
              WDiv(
                className: '''
                  flex flex-row items-center gap-2
                  bg-gray-50 dark:bg-gray-900/60
                  border border-gray-200 dark:border-gray-700
                  rounded-lg px-3
                  font-mono
                ''',
                children: [
                  WIcon(
                    Icons.chevron_right_rounded,
                    className: 'text-sm text-primary dark:text-primary-300',
                  ),
                  WDiv(
                    className: 'flex-1',
                    child: WInput(
                      value: _path.text,
                      onChanged: (v) => setState(() => _path.text = v),
                      placeholder: trans(_source.placeholderKey),
                      className: 'border-0 bg-transparent px-0',
                    ),
                  ),
                ],
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.metric_form.fields.fallback',
                hintKey: 'monitor.metric_form.fields.fallback_hint',
              ),
              WInput(
                value: _fallback.text,
                onChanged: (v) => _fallback.text = v,
                placeholder: '0',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeSection() {
    return FormSectionCard(
      titleKey: 'monitor.metric_form.type_section.title',
      subtitleKey: 'monitor.metric_form.type_section.subtitle',
      icon: Icons.category_rounded,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.metric_form.fields.type',
              ),
              SegmentedChoice<MetricType>(
                options: MetricType.values,
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
                labelBuilder: (v) => trans(v.labelKey),
                iconBuilder: (v) => switch (v) {
                  MetricType.numeric => Icons.pin_rounded,
                  MetricType.status => Icons.toggle_on_rounded,
                  MetricType.string => Icons.text_fields_rounded,
                },
              ),
            ],
          ),
          if (_type == MetricType.numeric)
            WDiv(
              className: 'flex flex-col',
              children: [
                const FormFieldLabel(
                  labelKey: 'monitor.metric_form.fields.unit',
                  hintKey: 'monitor.metric_form.fields.unit_hint',
                ),
                WInput(
                  value: _unit.text,
                  onChanged: (v) => setState(() => _unit.text = v),
                  placeholder: 'ms',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _thresholdSection() {
    return FormSectionCard(
      titleKey: 'monitor.metric_form.threshold.title',
      subtitleKey: 'monitor.metric_form.threshold.subtitle',
      icon: Icons.rule_rounded,
      child: ThresholdBandEditor(
        direction: _direction,
        warn: _warn,
        critical: _critical,
        unit: _unit.text,
        onDirectionChanged: (v) => setState(() => _direction = v),
        onWarnChanged: (v) => setState(() {}),
        onCriticalChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _previewSection() {
    return FormSectionCard(
      titleKey: 'monitor.metric_form.preview_section.title',
      subtitleKey: 'monitor.metric_form.preview_section.subtitle',
      icon: Icons.visibility_outlined,
      child: LivePreviewCard(
        hasRule: _hasParseRule,
        onRerun: () {},
        typeLabel: trans(_type.labelKey),
      ),
    );
  }

  Widget _footer() {
    return WDiv(
      className: '''
        px-4 lg:px-6 py-3
        border-t border-gray-200 dark:border-gray-800
        bg-white dark:bg-gray-900
        flex flex-row items-center justify-end gap-3
      ''',
      children: [
        SecondaryButton(
          labelKey: 'common.cancel',
          onTap: () => MagicRoute.back(),
        ),
        PrimaryButton(
          labelKey: _submitKey,
          icon: Icons.check_rounded,
          onTap: _onSubmit,
        ),
      ],
    );
  }
}
