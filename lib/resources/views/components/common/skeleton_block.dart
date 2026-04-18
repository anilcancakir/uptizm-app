import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Shimmering placeholder block used inside list / card skeletons.
///
/// Geometry is caller-controlled via [className] so each view can mirror the
/// final layout without bespoke components.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.className = 'w-full h-4'});

  final String className;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className:
          '''
        $className
        rounded-md
        bg-gray-200 dark:bg-gray-700
        animate-pulse
      ''',
    );
  }
}
