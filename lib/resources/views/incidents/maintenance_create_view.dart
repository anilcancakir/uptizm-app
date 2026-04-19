import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../app/controllers/incidents/maintenance_controller.dart';
import '../../../app/controllers/monitors/monitor_controller.dart';
import '../../../app/models/monitor.dart';
import '../components/common/app_back_button.dart';
import '../components/common/form_field_error.dart';
import '../components/common/form_field_label.dart';

/// Composer for scheduling a new maintenance window.
///
/// Captures the title, a start/end timestamp pair, optional markdown body,
/// the affected monitors (multi-select from [MonitorController.list]),
/// and the two notify-at-{start,end} toggles. The controller owns payload
/// building via [ScheduleMaintenanceRequest]; this view only collects the
/// field values and delegates to [MaintenanceController.submitCreate].
class MaintenanceCreateView extends MagicStatefulView<MaintenanceController> {
  const MaintenanceCreateView({super.key});

  @override
  State<MaintenanceCreateView> createState() => _MaintenanceCreateViewState();
}

class _MaintenanceCreateViewState
    extends
        MagicStatefulViewState<MaintenanceController, MaintenanceCreateView> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end = DateTime.now().add(const Duration(hours: 2));
  final Set<String> _monitorIds = {};
  bool _notifyStart = true;
  bool _notifyEnd = true;

  @override
  void onInit() {
    super.onInit();
    MonitorController.instance.loadList();
  }

  @override
  void onClose() {
    _title.dispose();
    _body.dispose();
    super.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-5',
      children: [
        AnimatedBuilder(animation: controller, builder: (_, _) => _header()),
        _titleField(),
        _windowFields(),
        _bodyField(),
        _monitorsField(),
        _notifyFields(),
        _submitRow(),
      ],
    );
  }

  Widget _header() {
    return WDiv(
      className: 'flex flex-row items-center gap-3',
      children: [
        const AppBackButton(fallbackPath: '/maintenance'),
        WDiv(
          className: 'flex-1 min-w-0 flex flex-col gap-0.5',
          children: [
            WText(
              trans('maintenance.schedule.title'),
              className: '''
                text-lg font-bold
                text-gray-900 dark:text-white
              ''',
            ),
            WText(
              trans('maintenance.schedule.subtitle'),
              className: '''
                text-xs
                text-muted dark:text-muted-dark
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _titleField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'maintenance.schedule.title_field',
          required: true,
        ),
        WInput(
          controller: _title,
          placeholder: trans('maintenance.schedule.title_placeholder'),
          placeholderClassName: 'text-sm text-gray-400 dark:text-gray-500',
          className: '''
            w-full px-3 py-2.5 rounded-lg
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
            text-sm text-gray-900 dark:text-white
          ''',
        ),
        FormFieldError(message: controller.getError('title')),
      ],
    );
  }

  Widget _windowFields() {
    return WDiv(
      className: 'flex flex-col gap-3 lg:flex-row lg:gap-4',
      children: [
        WDiv(
          className: 'flex-1 flex flex-col',
          children: [
            const FormFieldLabel(
              labelKey: 'maintenance.schedule.scheduled_for',
              required: true,
            ),
            _datePickerButton(
              value: _start,
              onPick: (v) => setState(() {
                _start = v;
                if (!_end.isAfter(v)) _end = v.add(const Duration(hours: 1));
              }),
            ),
            FormFieldError(message: controller.getError('scheduled_for')),
          ],
        ),
        WDiv(
          className: 'flex-1 flex flex-col',
          children: [
            const FormFieldLabel(
              labelKey: 'maintenance.schedule.scheduled_until',
              required: true,
            ),
            _datePickerButton(
              value: _end,
              onPick: (v) => setState(() => _end = v),
            ),
            FormFieldError(message: controller.getError('scheduled_until')),
          ],
        ),
      ],
    );
  }

  Widget _datePickerButton({
    required DateTime value,
    required void Function(DateTime) onPick,
  }) {
    return WButton(
      onTap: () => _pickDateTime(value, onPick),
      className: '''
        w-full px-3 py-2.5 rounded-lg
        bg-white dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
        hover:bg-gray-50 dark:hover:bg-gray-800
        flex flex-row items-center justify-between gap-2
      ''',
      child: WDiv(
        className: 'flex flex-row items-center justify-between gap-2 w-full',
        children: [
          WText(
            _formatDateTime(value),
            className: '''
              text-sm
              text-gray-900 dark:text-white
            ''',
          ),
          WIcon(
            Icons.calendar_today_rounded,
            className: 'text-sm text-muted dark:text-muted-dark',
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(
    DateTime initial,
    void Function(DateTime) onPick,
  ) async {
    final context = this.context;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  Widget _bodyField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(labelKey: 'maintenance.schedule.body_field'),
        WInput(
          controller: _body,
          type: InputType.multiline,
          minLines: 3,
          maxLines: 8,
          placeholder: trans('maintenance.schedule.body_placeholder'),
          placeholderClassName: 'text-sm text-gray-400 dark:text-gray-500',
          className: '''
            rounded-lg px-3 py-2.5 text-sm
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
          ''',
        ),
      ],
    );
  }

  Widget _monitorsField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'maintenance.schedule.monitors_field',
          required: true,
        ),
        ValueListenableBuilder<List<Monitor>>(
          valueListenable: MonitorController.instance.list,
          builder: (_, monitors, _) {
            if (monitors.isEmpty) {
              return _monitorsEmpty();
            }
            return WDiv(
              className: 'flex flex-col gap-1.5',
              children: [for (final m in monitors) _monitorRow(m)],
            );
          },
        ),
        FormFieldError(message: controller.getError('monitor_ids')),
      ],
    );
  }

  Widget _monitorsEmpty() {
    return WDiv(
      className: '''
        px-3 py-4 rounded-lg
        bg-gray-50 dark:bg-gray-900
        border border-dashed border-gray-200 dark:border-gray-700
      ''',
      child: WText(
        trans('maintenance.schedule.monitors_empty'),
        className: 'text-xs text-gray-500 dark:text-gray-400',
      ),
    );
  }

  Widget _monitorRow(Monitor monitor) {
    final isActive = _monitorIds.contains(monitor.id);
    return WButton(
      onTap: () => setState(() {
        if (isActive) {
          _monitorIds.remove(monitor.id);
        } else {
          _monitorIds.add(monitor.id);
        }
      }),
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
              w-4 h-4 rounded
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
              monitor.name ?? monitor.id,
              className: '''
                text-sm
                text-gray-800 dark:text-gray-100 truncate
              ''',
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifyFields() {
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [
        _notifyRow(
          labelKey: 'maintenance.schedule.notify_start',
          value: _notifyStart,
          onChanged: (v) => setState(() => _notifyStart = v),
        ),
        _notifyRow(
          labelKey: 'maintenance.schedule.notify_end',
          value: _notifyEnd,
          onChanged: (v) => setState(() => _notifyEnd = v),
        ),
      ],
    );
  }

  Widget _notifyRow({
    required String labelKey,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return WDiv(
      className: '''
        flex flex-row items-center gap-3
        p-3 rounded-lg
        bg-gray-50 dark:bg-gray-900
        border border-gray-200 dark:border-gray-700
      ''',
      children: [
        WCheckbox(value: value, onChanged: onChanged),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            trans(labelKey),
            className: 'text-sm text-gray-800 dark:text-gray-100',
          ),
        ),
      ],
    );
  }

  Widget _submitRow() {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final submitting = controller.isSubmitting;
        return WDiv(
          className: '''
            flex flex-row items-center justify-end gap-2
            pt-2
          ''',
          children: [
            WButton(
              onTap: () => MagicRoute.to('/maintenance'),
              className: '''
                px-4 py-2.5 rounded-lg
                border border-gray-200 dark:border-gray-700
                bg-white dark:bg-gray-800
                hover:bg-gray-100 dark:hover:bg-gray-700
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
              onTap: submitting ? null : _submit,
              className: '''
                px-4 py-2.5 rounded-lg
                bg-primary-600 dark:bg-primary-500
                hover:bg-primary-700 dark:hover:bg-primary-400
              ''',
              child: WText(
                trans('maintenance.schedule.submit'),
                className: 'text-sm font-semibold text-white',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (controller.isSubmitting) return;
    final created = await controller.submitCreate(
      title: _title.text,
      scheduledFor: _start,
      scheduledUntil: _end,
      monitorIds: _monitorIds.toList(),
      body: _body.text,
      notifyAtStart: _notifyStart,
      notifyAtEnd: _notifyEnd,
    );
    if (!mounted) return;
    if (created == null) {
      if (!controller.hasErrors) {
        Magic.toast(
          controller.rxStatus.message ?? trans('maintenance.errors.create'),
        );
      }
      return;
    }
    Magic.toast(trans('maintenance.toast.scheduled'));
    MagicRoute.to('/maintenance');
  }
}
