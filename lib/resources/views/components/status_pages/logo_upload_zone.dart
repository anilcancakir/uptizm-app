import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Upload zone for the status-page logo. The parent view owns the actual
/// `Pick.image()` + upload call and passes the async [onPick] handler
/// plus an [isUploading] flag so the button can reflect in-flight state.
///
/// [previewBytes] are the raw bytes of the just-picked image and take
/// precedence over the placeholder icon so the user can confirm what
/// was uploaded without a server round trip.
class LogoUploadZone extends StatelessWidget {
  const LogoUploadZone({
    super.key,
    required this.logoPath,
    required this.onPick,
    required this.onClear,
    this.previewBytes,
    this.isUploading = false,
  });

  final String? logoPath;
  final Uint8List? previewBytes;
  final Future<void> Function() onPick;
  final VoidCallback onClear;
  final bool isUploading;

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
            w-16 h-16 rounded-lg overflow-hidden
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            flex items-center justify-center
          ''',
          child: previewBytes != null
              ? WImage(
                  image: MemoryImage(previewBytes!),
                  className: 'w-full h-full object-contain',
                )
              : logoPath == null
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
        if (logoPath != null && !isUploading)
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
          onTap: isUploading ? null : onPick,
          states: isUploading ? {'disabled'} : {},
          className: '''
            px-3 py-2 rounded-lg
            bg-white dark:bg-gray-800
            border border-gray-200 dark:border-gray-700
            hover:bg-gray-100 dark:hover:bg-gray-700
            disabled:opacity-60
            flex flex-row items-center gap-2
          ''',
          child: WDiv(
            className: 'flex flex-row items-center gap-2',
            children: [
              WIcon(
                isUploading
                    ? Icons.hourglass_top_rounded
                    : Icons.upload_file_rounded,
                className: 'text-sm text-gray-700 dark:text-gray-200',
              ),
              WText(
                trans(
                  isUploading
                      ? 'status_page.create.logo.uploading'
                      : logoPath == null
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
