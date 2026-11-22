import 'package:flutter/material.dart';

import 'colors.dart';

/// The app's theme for one brightness and the chosen accent (3.10.4), built on [RgColors].
ThemeData buildTheme(Brightness brightness, [RgAccent accent = RgAccent.red]) {
  final c = (brightness == Brightness.dark ? RgColors.dark : RgColors.light).withAccent(
    accent,
    brightness,
  );
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: Colors.white,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.text,
    secondary: c.accent2,
    onSecondary: Colors.white,
    error: c.err,
    onError: Colors.white,
    surface: c.bg,
    onSurface: c.text,
    surfaceContainerLowest: c.panel,
    surfaceContainerLow: c.panel,
    surfaceContainer: c.panel,
    surfaceContainerHigh: c.panel2,
    surfaceContainerHighest: c.panel2,
    onSurfaceVariant: c.dim,
    outline: c.line,
    outlineVariant: c.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.panel2,
      hintStyle: TextStyle(color: c.dim),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : c.dim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.panel2,
      ),
      trackOutlineColor: WidgetStateProperty.all(c.line),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
    ),
  );
}
