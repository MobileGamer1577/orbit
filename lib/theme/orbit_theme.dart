import 'package:flutter/material.dart';

/// =========================
/// Orbit Theme System
/// =========================

enum OrbitDarkTheme {
  purple,
  blue,
  red,
  emerald,
  neonNights, // ✅ Neonnächte
}

class OrbitTheme {
  /// Aktuelles Dark Theme (wird später aus Settings gesetzt)
  static OrbitDarkTheme currentDarkTheme = OrbitDarkTheme.purple;

  /// =========================
  /// LIGHT THEME
  /// =========================
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.light,


          static ThemeData light() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C4DFF),
    brightness: Brightness.light,
  ),
);

        ),
      );

  /// =========================
  /// DARK THEME
  /// =========================
  static ThemeData dark() {
    final seed = _darkSeedColor(currentDarkTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,



        return ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ),
);

      ),
    );
  }

  /// =========================
  /// BACKGROUND COLORS (STRONGER)
  /// =========================
  /// Ziel: sichtbarere Styles (mehr Kontrast / mehr Sättigung),
  /// ohne komplett grell zu werden.
  static List<Color> backgroundColors(OrbitDarkTheme theme) {
    switch (theme) {
      case OrbitDarkTheme.purple:
        // kräftiger "Orbit Purple": mehr Magenta-Vibe oben, tiefes Violett unten
        return const [
          Color(0xFF3B0C7A), // brighter purple top
          Color(0xFF190B3B), // deep violet mid
          Color(0xFF070312), // near-black bottom
        ];

      case OrbitDarkTheme.blue:
        // "Ocean Blue": mehr Tiefe + klarer Blau-Stich
        return const [
          Color(0xFF0A3C78), // strong ocean blue top
          Color(0xFF071A33), // deep navy mid
          Color(0xFF030812), // almost black blue bottom
        ];

      case OrbitDarkTheme.red:
        // "Crimson Red": deutlich stärker + dunkles Rot unten
        return const [
          Color(0xFF7A0B16), // strong crimson top
          Color(0xFF2B0610), // deep wine mid
          Color(0xFF0F0206), // near-black red bottom
        ];

      case OrbitDarkTheme.emerald:
        // "Emerald Green": mehr Punch, aber noch edel
        return const [
          Color(0xFF0A5B41), // strong emerald top
          Color(0xFF052417), // deep green mid
          Color(0xFF020A06), // near-black green bottom
        ];

      case OrbitDarkTheme.neonNights:
        // ✅ Neonnächte: kräftiger, cyber-night Look (Blau -> Violett -> Schwarz)
        // oben: electric navy, mitte: neon-violet, unten: deep black-purple
        return const [
          Color(0xFF083A7A), // electric navy top
          Color(0xFF2A0A5E), // neon violet mid
          Color(0xFF050012), // deep night bottom
        ];
    }
  }

  /// =========================
  /// SEED COLORS (STRONGER ACCENTS)
  /// =========================
  static Color _darkSeedColor(OrbitDarkTheme theme) {
    switch (theme) {
      case OrbitDarkTheme.purple:
        return const Color(0xFF9B5CFF); // stronger purple accent

      case OrbitDarkTheme.blue:
        return const Color(0xFF4AA3FF); // brighter blue accent

      case OrbitDarkTheme.red:
        return const Color(0xFFFF4D6D); // vivid crimson accent

      case OrbitDarkTheme.emerald:
        return const Color(0xFF2EE6A6); // vivid emerald accent

      case OrbitDarkTheme.neonNights:
        return const Color(0xFF00E5FF); // neon cyan accent
    }
  }

  /// =========================
  /// HELPER
  /// =========================

  /// Robust: falls alte Werte gespeichert sind (z.B. "amoled" oder "neon"),
  /// wird automatisch auf Purple zurückgefallen.
  static OrbitDarkTheme fromName(String name) {
    final n = name.trim().toLowerCase();

    // alte/entfernte Themes -> fallback
    if (n == 'amoled' || n == 'neon') return OrbitDarkTheme.purple;

    return OrbitDarkTheme.values.firstWhere(
      (e) => e.name.toLowerCase() == n,
      orElse: () => OrbitDarkTheme.purple,
    );
  }

  static String displayName(OrbitDarkTheme theme) {
    switch (theme) {
      case OrbitDarkTheme.purple:
        return 'Orbit Purple';
      case OrbitDarkTheme.blue:
        return 'Ocean Blue';
      case OrbitDarkTheme.red:
        return 'Crimson Red';
      case OrbitDarkTheme.emerald:
        return 'Emerald Green';
      case OrbitDarkTheme.neonNights:
        return 'Neonnächte';
    }
  }
}

/// =========================
/// BACKGROUND WIDGET
/// =========================
class OrbitBackground extends StatelessWidget {
  final Widget child;

  const OrbitBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.backgroundColors(OrbitTheme.currentDarkTheme);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}