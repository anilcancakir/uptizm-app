import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Fixed-size colored shape used by color pickers and preview swatches.
///
/// User-picked hex is runtime-dynamic, so it flows through
/// `WDiv.backgroundColor` (bypasses the className cache) instead of
/// `bg-[#$hex]` interpolation.
class HexSwatch extends StatelessWidget {
  const HexSwatch({
    super.key,
    required this.hex,
    this.size = 'md',
    this.shape = 'circle',
    this.dimension,
    this.radius,
    this.child,
  });

  final String hex;

  /// `'xs'` (16px), `'sm'` (20px), `'md'` (28px), `'lg'` (40px). Ignored when
  /// [dimension] is provided.
  final String size;

  /// `'circle'` or `'square'` (rounded-md). Ignored when [radius] is provided.
  final String shape;

  /// Explicit width/height override in logical pixels.
  final double? dimension;

  /// Explicit corner radius override in logical pixels.
  final double? radius;

  /// Optional content centered inside the swatch (e.g. brand initials).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dim =
        dimension ??
        switch (size) {
          'xs' => 16.0,
          'sm' => 20.0,
          'lg' => 40.0,
          _ => 28.0,
        };
    final cornerRadius = radius ?? (shape == 'square' ? 6.0 : dim / 2);
    return WDiv(
      backgroundColor: parse(context, hex),
      className:
          '''
        flex items-center justify-center
        w-[${dim.toInt()}px] h-[${dim.toInt()}px]
        rounded-[${cornerRadius.toInt()}px]
      ''',
      child: child,
    );
  }

  /// Parses a `#RRGGBB` / `RRGGBB` / `#AARRGGBB` hex string into a [Color].
  ///
  /// Falls back to the workspace primary token when the input is unparsable.
  static Color parse(BuildContext context, String input) {
    var s = input.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final value = int.tryParse(s, radix: 16);
    if (value != null) return Color(value);
    return wColor(context, 'primary', shade: 600) ??
        Theme.of(context).colorScheme.primary;
  }
}
