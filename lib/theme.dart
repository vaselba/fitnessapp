import 'package:flutter/material.dart';

final Color seedColor = const Color.fromARGB(255, 152, 11, 196);

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
);

final cardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
);

final appTextTheme = TextTheme(
  headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: lightColorScheme.primary),
  headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: lightColorScheme.primary),
  titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: lightColorScheme.primary),
  bodyLarge: TextStyle(fontSize: 16, color: lightColorScheme.onSurface),
  bodyMedium: TextStyle(fontSize: 14, color: lightColorScheme.onSurface),
  labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: lightColorScheme.secondary),
);

final appTheme = ThemeData(
  colorScheme: lightColorScheme,
  brightness: Brightness.light,
  cardTheme: CardThemeData(
    color: lightColorScheme.surface,
    shape: cardShape,
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  textTheme: appTextTheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: lightColorScheme.surfaceContainerHighest,
  ),
);

final appDarkTheme = ThemeData(
  colorScheme: darkColorScheme,
  brightness: Brightness.dark,
  cardTheme: CardThemeData(
    color: darkColorScheme.surface,
    shape: cardShape,
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
  textTheme: appTextTheme.apply(
      bodyColor: darkColorScheme.onSurface,
      displayColor: darkColorScheme.primary),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: darkColorScheme.surfaceContainerHighest,
  ),
);
