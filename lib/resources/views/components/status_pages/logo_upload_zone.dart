import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Upload zone for the status-page logo. Mockup only; [onPick] is invoked
/// with a stubbed path when the user taps the "Upload logo" action.
class LogoUploadZone extends StatelessWidget {
  const LogoUploadZone({
    super.key,
    required this.logoPath,
    required this.onPick,
    required this.onClear,
  });

  final String? logoPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: '''
        rounded-lg p-4
        bg-gray-50 dark:bg-gray-900
        border border-dashed border-gray-300 dark:border-gray-700
        flex flex-col items-stretch gap-3
        sm:flex-row sm:items-center sm:gap-4
      ''',
      children: [
        WDiv(
          className: '''
            w-16 h-16 rounded-lg
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex items-center justify-center
          ''',
          child: logoPath == null
              ? WIcon(
                  Icons.image_outlined,
                  className: 'text-xl text-gray-400 dark:text-gray-500',
                )
              : WIcon(
                  Icons.check_rounded,
                  className: 'text-xl text-up-600 dark:text-up-400',
                ),
        ),
        WDiv(
          className: 'w-full sm:flex-1 flex flex-col gap-1 min-w-0',
          children: [
            WText(
              trans(
                logoPath == null
                    ? 'status_page.create.logo.hint_empty'
                    : 'status_page.create.logo.hint_set',
              ),
              className: '''
                text-sm font-semibold
                text-gray-800 dark:text-gray-100
              ''',
            ),
            WText(
              trans('status_page.create.logo.spec'),
              className: '''
                text-xs
                text-gray-500 dark:text-gray-400
              ''',
            ),
          ],
        ),
        if (logoPath != null)
          WButton(
            onTap: onClear,
            className: '''
              px-3 py-2 rounded-lg
              hover:bg-gray-100 dark:hover:bg-gray-800
            ''',
            child: WText(
              trans('status_page.create.logo.clear'),
              className: '''
                text-sm font-semibold
                text-gray-600 dark:text-gray-300
              ''',
            ),
          ),
        WButton(
          onTap: onPick,
          className: '''
            px-3 py-2 rounded-lg
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            hover:bg-gray-100 dark:hover:bg-gray-700
            flex flex-row items-center gap-2
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-2',
            children: [
              WIcon(
                Icons.upload_file_rounded,
                className: 'text-sm text-gray-700 dark:text-gray-200',
              ),
              WText(
                trans(
                  logoPath == null
                      ? 'status_page.create.logo.upload'
                      : 'status_page.create.logo.replace',
                ),
                className: '''
                  text-sm font-semibold
                  text-gray-800 dark:text-gray-100
                ''',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
