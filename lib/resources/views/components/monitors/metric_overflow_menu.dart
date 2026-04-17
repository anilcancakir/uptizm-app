import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Overflow (…) menu used in the metric detail sheet header.
///
/// Exposes Edit, Duplicate and Delete actions. Delete is rendered in the
/// danger tone.
class MetricOverflowMenu extends StatelessWidget {
  const MetricOverflowMenu({
    super.key,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return WPopover(
      alignment: PopoverAlignment.bottomRight,
      triggerBuilder: (context, isOpen, isHovering) => WButton(
        className: '''
          w-9 h-9 rounded-lg
          bg-gray-100 dark:bg-gray-800
          hover:bg-gray-200 dark:hover:bg-gray-700
          flex items-center justify-center
        ''',
        child: WIcon(
          Icons.more_horiz_rounded,
          className: 'text-base text-gray-600 dark:text-gray-300',
        ),
      ),
      contentBuilder: (context, close) => WDiv(
        className: '''
          w-48 p-1 rounded-lg
          bg-white dark:bg-gray-900
          border border-gray-200 dark:border-gray-700
          shadow-lg
          flex flex-col gap-0.5
        ''',
        children: [
          _item(
            icon: Icons.edit_outlined,
            labelKey: 'monitor.metric_menu.edit',
            onTap: () {
              close();
              onEdit();
            },
          ),
          _item(
            icon: Icons.content_copy_outlined,
            labelKey: 'monitor.metric_menu.duplicate',
            onTap: () {
              close();
              onDuplicate();
            },
          ),
          WDiv(
            className: '''
              h-px my-1
              bg-gray-100 dark:bg-gray-800
            ''',
          ),
          _item(
            icon: Icons.delete_outline_rounded,
            labelKey: 'monitor.metric_menu.delete',
            onTap: () {
              close();
              onDelete();
            },
            dangerous: true,
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String labelKey,
    required VoidCallback onTap,
    bool dangerous = false,
  }) {
    return WButton(
      onTap: onTap,
      states: dangerous ? {'danger'} : {},
      className: '''
        w-full px-3 py-2 rounded-md
        flex flex-row items-center gap-2
        hover:bg-gray-100 dark:hover:bg-gray-800
        danger:hover:bg-down-50 dark:danger:hover:bg-down-900/30
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-2 w-full',
        children: [
          WIcon(
            icon,
            states: dangerous ? {'danger'} : {},
            className: '''
              text-sm
              text-gray-600 dark:text-gray-300
              danger:text-down-600 dark:danger:text-down-400
            ''',
          ),
          WText(
            trans(labelKey),
            states: dangerous ? {'danger'} : {},
            className: '''
              text-sm font-semibold
              text-gray-700 dark:text-gray-200
              danger:text-down-600 dark:danger:text-down-400
            ''',
          ),
        ],
      ),
    );
  }
}
