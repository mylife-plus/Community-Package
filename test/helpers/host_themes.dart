import 'package:flutter/material.dart';

/// Host themes like the three apps': a hand-built scheme (Inventory), the
/// Flutter defaults (SpaceTime) and a seeded scheme (money).
final hostThemes = <String, ThemeData>{
  'hand-built dark': ThemeData(
    scaffoldBackgroundColor: const Color(0xFF0B1220),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF2C9DFF),
      onPrimary: Colors.white,
      secondary: Color(0xFF4BE000),
      onSecondary: Colors.black,
      surface: Color(0xFF141C2B),
      onSurface: Color(0xFFE8EDF5),
      error: Color(0xFFFF5A5A),
      onError: Colors.white,
    ),
  ),
  'hand-built light': ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF2F4F8),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0066CC),
      onPrimary: Colors.white,
      secondary: Color(0xFF2E8B00),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF111827),
      error: Color(0xFFD00000),
      onError: Colors.white,
    ),
  ),
  'default light': ThemeData.light(),
  'default dark': ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
  'seeded light': ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
  'seeded dark': ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark)),
};
