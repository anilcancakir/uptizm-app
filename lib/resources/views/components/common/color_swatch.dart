import 'package:flutter/material.dart';

/// Fixed-size colored shape used by color pickers and preview swatches.
///
/// Uses a native `Container` to paint the dynamic hex color, since Wind's
/// `bg-[#hex]` arbitrary class is parsed as an asset reference on web.
class HexSwatch extends StatelessWidget {
  const HexSwatch({
    super.key,
    required this.hex,
    this.size = 'md',
    this.shape = 'circle',
  });

  final String hex;

  /// `'xs'` (16px), `'sm'` (20px), `'md'` (28px), `'lg'` (40px).
  final String size;

  /// `'circle'` or `'square'` (rounded-md).
  final String shape;

  @override
  Widget build(BuildContext context) {
    final dim = switch (size) {
      'xs' => 16.0,
      'sm' => 20.0,
      'lg' => 40.0,
      _ => 28.0,
    };
    final radius = shape == 'square'
        ? BorderRadius.circular(6)
        : BorderRadius.circular(dim / 2);
    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: parse(hex),
        borderRadius: radius,
      ),
    );
  }

  static Color parse(String input) {
    var s = input.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final value = int.tryParse(s, radix: 16);
    return value == null ? const Color(0xFF2563EB) : Color(value);
  }
}
