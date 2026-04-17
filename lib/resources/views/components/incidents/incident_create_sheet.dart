import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/incident_severity.dart';
import '../../../../app/models/mock/monitor_metric.dart';
import '../common/form_field_label.dart';
import '../common/segmented_choice.dart';

/// Bottom-sheet composer for manually reporting an incident on a monitor.
///
/// Mock-only: captures severity, title, description, optional metric link
/// and a notify-team toggle. Submits nothing; just toasts.
class IncidentCreateSheet extends StatefulWidget {
  const IncidentCreateSheet({
    super.key,
    required this.monitorTitle,
    this.monitorId,
    this.metrics,
    this.onSubmit,
  });

  final String monitorTitle;
  final String? monitorId;
  final List<MonitorMetric>? metrics;
  final void Function(
    IncidentSeverity severity,
    String title,
    String description,
    String? metricKey,
    bool notifyTeam,
  )? onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String monitorTitle,
    String? monitorId,
    List<MonitorMetric>? metrics,
    void Function(
      IncidentSeverity severity,
      String title,
      String description,
      String? metricKey,
      bool notifyTeam,
    )? onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidentCreateSheet(
        monitorTitle: monitorTitle,
        monitorId: monitorId,
        metrics: metrics,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<IncidentCreateSheet> createState() => _IncidentCreateSheetState();
}

class _IncidentCreateSheetState extends State<IncidentCreateSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  IncidentSeverity _severity = IncidentSeverity.warn;
  String? _metricKey;
  bool _notifyTeam = true;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return WDiv(
          className: '''
            rounded-t-2xl
            bg-white dark:bg-gray-900
            border-t border-gray-200 dark:border-gray-700
            flex flex-col
          ''',
          children: [
            _grabber(),
            _header(),
            WDiv(
              className: 'flex-1 overflow-y-auto',
              scrollPrimary: true,
              children: [
                WDiv(
                  className: 'p-4 flex flex-col gap-5',
                  children: [
                    _severityField(),
                    _titleField(),
                    _descriptionField(),
                    _metricField(),
                    _notifyField(),
                  ],
                ),
              ],
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
        className: 'w-10 h-1 rounded-full bg-gray-300 dark:bg-gray-600',
      ),
    );
  }

  Widget _header() {
    return WDiv(
      className: '''
        px-4 pb-4
        border-b border-gray-100 dark:border-gray-800
        flex flex-col gap-1
      ''',
      children: [
        WText(
          trans('incident.create.title'),
          className: '''
            text-lg font-bold
            text-gray-900 dark:text-white
          ''',
        ),
        WText(
          widget.monitorTitle,
          className: '''
            text-xs
            text-gray-500 dark:text-gray-400 truncate
          ''',
        ),
      ],
    );
  }

  Widget _severityField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'incident.create.fields.severity',
          hintKey: 'incident.create.fields.severity_hint',
          required: true,
        ),
        SegmentedChoice<IncidentSeverity>(
          options: IncidentSeverity.values,
          selected: _severity,
          onChanged: (v) => setState(() => _severity = v),
          labelBuilder: (v) => trans(v.labelKey),
          iconBuilder: (v) => switch (v) {
            IncidentSeverity.critical => Icons.error_rounded,
            IncidentSeverity.warn => Icons.warning_amber_rounded,
            IncidentSeverity.info => Icons.info_outline_rounded,
          },
        ),
      ],
    );
  }

  Widget _titleField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'incident.create.fields.title',
          hintKey: 'incident.create.fields.title_hint',
          required: true,
        ),
        WInput(
          value: _title.text,
          onChanged: (v) => _title.text = v,
          placeholder: trans('incident.create.fields.title_placeholder'),
          className: '''
            w-full px-3 py-2.5 rounded-lg
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
            text-sm text-gray-900 dark:text-white
            focus:border-primary-500 dark:focus:border-primary-400
          ''',
        ),
      ],
    );
  }

  Widget _descriptionField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'incident.create.fields.description',
          hintKey: 'incident.create.fields.description_hint',
        ),
        WDiv(
          className: '''
            rounded-lg
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
          ''',
          child: TextField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: trans(
                'incident.create.fields.description_placeholder',
              ),
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricField() {
    final metrics = widget.metrics ?? const <MonitorMetric>[];
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'incident.create.fields.metric',
          hintKey: 'incident.create.fields.metric_hint',
        ),
        if (metrics.isEmpty)
          _metricEmptyHint()
        else
          WDiv(
            className: 'flex flex-col gap-1.5',
            children: [
              _metricRow(null, trans('incident.create.metric_none')),
              for (final m in metrics) _metricRow(m.key, m.label),
            ],
          ),
      ],
    );
  }

  Widget _metricEmptyHint() {
    return WDiv(
      className: '''
        px-3 py-4 rounded-lg
        bg-gray-50 dark:bg-gray-900
        border border-dashed border-gray-200 dark:border-gray-700
        flex flex-row items-center gap-2
      ''',
      children: [
        WIcon(
          Icons.insights_rounded,
          className: 'text-sm text-gray-400 dark:text-gray-500',
        ),
        WText(
          trans('incident.create.metric_empty'),
          className: 'text-xs text-gray-500 dark:text-gray-400',
        ),
      ],
    );
  }

  Widget _metricRow(String? key, String label) {
    final isActive = _metricKey == key;
    return WButton(
      onTap: () => setState(() => _metricKey = key),
      states: isActive ? {'active'} : {},
      className: '''
        w-full px-3 py-2.5 rounded-lg
        bg-white dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
        hover:bg-gray-50 dark:hover:bg-gray-800
        active:bg-primary-50 dark:active:bg-primary-900/30
        active:border-primary-300 dark:active:border-primary-700
        flex flex-row items-center gap-3
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-3 w-full',
        children: [
          WDiv(
            states: isActive ? {'active'} : {},
            className: '''
              w-4 h-4 rounded-full
              border border-gray-300 dark:border-gray-600
              active:border-primary-500 dark:active:border-primary-400
              active:bg-primary-500 dark:active:bg-primary-400
              flex items-center justify-center
            ''',
            child: isActive
                ? WIcon(
                    Icons.check_rounded,
                    className: 'text-[10px] text-white',
                  )
                : const SizedBox.shrink(),
          ),
          WDiv(
            className: 'flex-1 min-w-0',
            child: WText(
              label,
              states: isActive ? {'active'} : {},
              className: '''
                text-sm font-mono
                text-gray-700 dark:text-gray-200
                active:text-primary-700 dark:active:text-primary-300
                active:font-semibold
                truncate
              ''',
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifyField() {
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
        p-3 rounded-lg
        bg-gray-50 dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
      ''',
      children: [
        WDiv(
          className: '''
            w-9 h-9 rounded-lg
            bg-primary-50 dark:bg-primary-900/30
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.campaign_rounded,
            className: 'text-base text-primary-600 dark:text-primary-400',
          ),
        ),
        WDiv(
          className: 'flex-1 flex flex-col gap-0.5 min-w-0',
          children: [
            WText(
              trans('incident.create.fields.notify_title'),
              className: '''
                text-sm font-semibold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('incident.create.fields.notify_subtitle'),
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
        WCheckbox(
          value: _notifyTeam,
          onChanged: (v) => setState(() => _notifyTeam = v),
        ),
      ],
    );
  }

  Widget _footer() {
    return WDiv(
      className: '''
        w-full px-4 py-3
        border-t border-gray-200 dark:border-gray-800
        flex flex-row items-center justify-end gap-2
      ''',
      children: [
        WButton(
          onTap: () => MagicRoute.back(),
          className: '''
            px-4 py-2.5 rounded-lg
            border border-gray-200 dark:border-gray-700
            bg-white dark:bg-gray-800
            hover:bg-gray-100 dark:hover:bg-gray-700
            flex flex-row items-center justify-center
          ''',
          child: WText(
            trans('common.cancel'),
            className: '''
              text-sm font-semibold
              text-gray-700 dark:text-gray-200
            ''',
          ),
        ),
        WButton(
          onTap: _submit,
          className: '''
            px-4 py-2.5 rounded-lg
            bg-primary-600 dark:bg-primary-500
            hover:bg-primary-700 dark:hover:bg-primary-400
            flex flex-row items-center gap-1.5
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-1.5',
            children: [
              WIcon(
                Icons.report_problem_rounded,
                className: 'text-sm text-white',
              ),
              WText(
                trans('incident.create.submit'),
                className: 'text-sm font-semibold text-white',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      Magic.toast(trans('incident.create.title_required'));
      return;
    }
    widget.onSubmit?.call(
      _severity,
      title,
      _description.text.trim(),
      _metricKey,
      _notifyTeam,
    );
    MagicRoute.back();
    Magic.toast(trans('incident.create.toast_created'));
  }
}
