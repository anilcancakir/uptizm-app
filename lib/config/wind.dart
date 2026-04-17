import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

/// Wind Theme Configuration.
///
/// Registers Uptizm brand palette plus monitor-status colors so that
/// className tokens like `bg-primary`, `text-up`, `border-down`, `bg-degraded`
/// and `text-paused` resolve consistently across web, Android and iOS.
///
/// Status mapping:
/// - up       : monitor is responding within SLA (emerald)
/// - down     : monitor is failing checks (red)
/// - degraded : monitor is responding but breaching thresholds (amber)
/// - paused   : monitor is manually paused or awaiting first check (slate)
WindThemeData get windTheme => WindThemeData(
  screens: const {'tablet': 760},
  colors: {
    'primary': const MaterialColor(0xFF009E60, <int, Color>{
      50: Color(0xFFE0F4ED),
      100: Color(0xFFB3E4D1),
      200: Color(0xFF80D2B3),
      300: Color(0xFF4DBF94),
      400: Color(0xFF26B07D),
      500: Color(0xFF009E60),
      600: Color(0xFF009156),
      700: Color(0xFF00814A),
      800: Color(0xFF00723F),
      900: Color(0xFF004D2F),
      950: Color(0xFF002E1B),
    }),
    'up': const MaterialColor(0xFF10B981, <int, Color>{
      50: Color(0xFFECFDF5),
      100: Color(0xFFD1FAE5),
      200: Color(0xFFA7F3D0),
      300: Color(0xFF6EE7B7),
      400: Color(0xFF34D399),
      500: Color(0xFF10B981),
      600: Color(0xFF059669),
      700: Color(0xFF047857),
      800: Color(0xFF065F46),
      900: Color(0xFF064E3B),
      950: Color(0xFF022C22),
    }),
    'down': const MaterialColor(0xFFEF4444, <int, Color>{
      50: Color(0xFFFEF2F2),
      100: Color(0xFFFEE2E2),
      200: Color(0xFFFECACA),
      300: Color(0xFFFCA5A5),
      400: Color(0xFFF87171),
      500: Color(0xFFEF4444),
      600: Color(0xFFDC2626),
      700: Color(0xFFB91C1C),
      800: Color(0xFF991B1B),
      900: Color(0xFF7F1D1D),
      950: Color(0xFF450A0A),
    }),
    'degraded': const MaterialColor(0xFFF59E0B, <int, Color>{
      50: Color(0xFFFFFBEB),
      100: Color(0xFFFEF3C7),
      200: Color(0xFFFDE68A),
      300: Color(0xFFFCD34D),
      400: Color(0xFFFBBF24),
      500: Color(0xFFF59E0B),
      600: Color(0xFFD97706),
      700: Color(0xFFB45309),
      800: Color(0xFF92400E),
      900: Color(0xFF78350F),
      950: Color(0xFF451A03),
    }),
    'info': const MaterialColor(0xFF3B82F6, <int, Color>{
      50: Color(0xFFEFF6FF),
      100: Color(0xFFDBEAFE),
      200: Color(0xFFBFDBFE),
      300: Color(0xFF93C5FD),
      400: Color(0xFF60A5FA),
      500: Color(0xFF3B82F6),
      600: Color(0xFF2563EB),
      700: Color(0xFF1D4ED8),
      800: Color(0xFF1E40AF),
      900: Color(0xFF1E3A8A),
      950: Color(0xFF172554),
    }),
    'ai': const MaterialColor(0xFF6366F1, <int, Color>{
      50: Color(0xFFEEF2FF),
      100: Color(0xFFE0E7FF),
      200: Color(0xFFC7D2FE),
      300: Color(0xFFA5B4FC),
      400: Color(0xFF818CF8),
      500: Color(0xFF6366F1),
      600: Color(0xFF4F46E5),
      700: Color(0xFF4338CA),
      800: Color(0xFF3730A3),
      900: Color(0xFF312E81),
      950: Color(0xFF1E1B4B),
    }),
    'paused': const MaterialColor(0xFF64748B, <int, Color>{
      50: Color(0xFFF8FAFC),
      100: Color(0xFFF1F5F9),
      200: Color(0xFFE2E8F0),
      300: Color(0xFFCBD5E1),
      400: Color(0xFF94A3B8),
      500: Color(0xFF64748B),
      600: Color(0xFF475569),
      700: Color(0xFF334155),
      800: Color(0xFF1E293B),
      900: Color(0xFF0F172A),
      950: Color(0xFF020617),
    }),
  },
);
