import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/threshold_direction.dart';
import '../common/form_field_label.dart';
import '../common/segmented_choice.dart';

/// Directional threshold editor for numeric metrics.
///
/// Combines: direction toggle (> high bad / < low bad), two numeric inputs
/// (warn, critical) and a visual three-segment band bar that flips color
/// order when the direction changes.
class ThresholdBandEditor extends StatelessWidget {
  const ThresholdBandEditor({
    super.key,
    required this.direction,
    required this.warn,
    required this.critical,
    required this.unit,
    required this.onDirectionChanged,
    required this.onWarnChanged,
    required this.onCriticalChanged,
  });

  final ThresholdDirection direction;
  final TextEditingController warn;
  final TextEditingController critical;
  final String unit;
  final ValueChanged<ThresholdDirection> onDirectionChanged;
  final ValueChanged<String> onWarnChanged;
  final ValueChanged<String> onCriticalChanged;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-4',
      children: [
        WDiv(
          className: 'flex flex-col gap-2',
          children: [
            const FormFieldLabel(
              labelKey: 'monitor.metric_form.direction_label',
              hintKey: 'monitor.metric_form.direction_subtitle',
            ),
            SegmentedChoice<ThresholdDirection>(
              options: ThresholdDirection.values,
              selected: direction,
              onChanged: onDirectionChanged,
              labelBuilder: (d) => trans(d.labelKey),
              iconBuilder: (d) => switch (d) {
                ThresholdDirection.highBad => Icons.north_east_rounded,
                ThresholdDirection.lowBad => Icons.south_east_rounded,
              },
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-col sm:flex-row gap-3',
          children: [
            _numericInput(
              labelKey: 'monitor.metric_form.warn_at',
              controller: warn,
              onChanged: onWarnChanged,
              toneKey: 'warn',
            ),
            _numericInput(
              labelKey: 'monitor.metric_form.critical_at',
              controller: critical,
              onChanged: onCriticalChanged,
              toneKey: 'critical',
            ),
          ],
        ),
        _bandBar(),
      ],
    );
  }

  Widget _numericInput({
    required String labelKey,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String toneKey,
  }) {
    return WDiv(
      className: 'flex-1 flex flex-col gap-1.5',
      children: [
        WDiv(
          className: 'flex flex-row items-center gap-2',
          children: [
            WDiv(
              states: {toneKey},
              className: '''
                w-2 h-2 rounded-full
                warn:bg-degraded-500 dark:warn:bg-degraded-400
                critical:bg-down-500 dark:critical:bg-down-400
              ''',
            ),
            WText(
              trans(labelKey),
              className: '''
                text-xs font-semibold uppercase tracking-wide
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
        WDiv(
          className: '''
            flex flex-row items-center gap-2
            bg-white dark:bg-gray-900/40
            border border-gray-200 dark:border-gray-700
            rounded-lg px-3 py-2
          ''',
          children: [
            WDiv(
              className: 'flex-1',
              child: WInput(
                value: controller.text,
                onChanged: (v) {
                  controller.text = v;
                  onChanged(v);
                },
                placeholder: '0',
              ),
            ),
            if (unit.isNotEmpty)
              WText(
                unit,
                className: '''
                  text-xs font-mono
                  text-gray-500 dark:text-gray-400
                ''',
              ),
          ],
        ),
      ],
    );
  }

  Widget _bandBar() {
    final isHigh = direction == ThresholdDirection.highBad;
    final warnLabel = warn.text.isEmpty ? '--' : warn.text;
    final critLabel = critical.text.isEmpty ? '--' : critical.text;

    return WDiv(
      className: '''
        flex flex-col gap-2 p-3 rounded-lg
        bg-gray-50 dark:bg-gray-900/40
        border border-gray-200 dark:border-gray-700
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center h-2 rounded-full overflow-hidden',
          children: [
            _bandSegment(
              tone: isHigh ? 'ok' : 'critical',
              flex: 1,
              position: 'first',
            ),
            _bandSegment(tone: 'warn', flex: 1, position: 'middle'),
            _bandSegment(
              tone: isHigh ? 'critical' : 'ok',
              flex: 1,
              position: 'last',
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-row items-center justify-between',
          children: [
            _bandCaption(
              labelKey: isHigh
                  ? 'monitor.metric_form.band.ok'
                  : 'monitor.metric_form.band.critical',
              tone: isHigh ? 'ok' : 'critical',
            ),
            _bandCaption(
              labelKey: 'monitor.metric_form.band.warn',
              tone: 'warn',
              value: warnLabel,
            ),
            _bandCaption(
              labelKey: isHigh
                  ? 'monitor.metric_form.band.critical'
                  : 'monitor.metric_form.band.ok',
              tone: isHigh ? 'critical' : 'ok',
              value: critLabel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _bandSegment({
    required String tone,
    required int flex,
    required String position,
  }) {
    return WDiv(
      className: 'flex-$flex h-2',
      child: WDiv(
        states: {tone},
        className: '''
          w-full h-full
          ok:bg-up-500 dark:ok:bg-up-400
          warn:bg-degraded-500 dark:warn:bg-degraded-400
          critical:bg-down-500 dark:critical:bg-down-400
        ''',
      ),
    );
  }

  Widget _bandCaption({
    required String labelKey,
    required String tone,
    String? value,
  }) {
    return WDiv(
      className: 'flex flex-col items-start gap-0.5',
      children: [
        WText(
          trans(labelKey),
          states: {tone},
          className: '''
            text-[10px] font-bold uppercase tracking-wide
            ok:text-up-700 dark:ok:text-up-300
            warn:text-degraded-700 dark:warn:text-degraded-300
            critical:text-down-700 dark:critical:text-down-300
          ''',
        ),
        if (value != null)
          WText(
            '$value ${unit.isNotEmpty ? unit : ''}'.trim(),
            className: '''
              text-xs font-mono
              text-gray-600 dark:text-gray-300
            ''',
          ),
      ],
    );
  }
}
