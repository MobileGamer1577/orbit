import 'dart:ui';
import 'package:flutter/material.dart';

enum OrbitDarkTheme {
  purple,
  blue,
  red,
  emerald,
  neonNights,
}

class OrbitTheme {
  /// Wird von deinen Settings gesetzt (AppSettingsStore)
  static OrbitDarkTheme currentDarkTheme = OrbitDarkTheme.purple;

  static String displayName(OrbitDarkTheme t) {
    switch (t) {
      case OrbitDarkTheme.purple:
        return 'Purple';
      case OrbitDarkTheme.blue:
        return 'Blue';
      case OrbitDarkTheme.red:
        return 'Red';
      case OrbitDarkTheme.emerald:
        return 'Emerald';
      case OrbitDarkTheme.neonNights:
        return 'Neon Nights';
    }
  }

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: _pageTransitions(),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: Colors.transparent,

      // bisschen „cremiger“ Text (wie bei deinem Look)
      textTheme: const TextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      pageTransitionsTheme: _pageTransitions(),
    );
  }

  static PageTransitionsTheme _pageTransitions() {
    // ✅ Leichte Animationen (Fade + mini Slide)
    // - fühlt sich auf Handy gut an
    // - kostet kaum Performance
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
      },
    );
  }

  /// Farben fürs Background-Gradient je nach Design
  static List<Color> backgroundGradient(OrbitDarkTheme t) {
    switch (t) {
      case OrbitDarkTheme.purple:
        return const [
          Color(0xFF2A0A57),
          Color(0xFF12051F),
          Color(0xFF07030D),
        ];
      case OrbitDarkTheme.blue:
        return const [
          Color(0xFF062A5B),
          Color(0xFF051323),
          Color(0xFF04070D),
        ];
      case OrbitDarkTheme.red:
        return const [
          Color(0xFF4A0A12),
          Color(0xFF1D0508),
          Color(0xFF090305),
        ];
      case OrbitDarkTheme.emerald:
        return const [
          Color(0xFF053B2B),
          Color(0xFF041A13),
          Color(0xFF030908),
        ];
      case OrbitDarkTheme.neonNights:
        return const [
          Color(0xFF0B0B2B),
          Color(0xFF12031C),
          Color(0xFF030206),
        ];
    }
  }
}

/// ✅ Custom Page Transition (Fade + very small Slide)
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Keine Animation für "initial route"
    if (route.isFirst) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

    // sehr kleiner Slide → wirkt „flüssig“ statt ruckelig
    final slide = Tween<Offset>(
      begin: const Offset(0.03, 0.0),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

/// =========================
/// Background Widget (dein Look)
/// =========================
class OrbitBackground extends StatelessWidget {
  final Widget child;

  const OrbitBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.backgroundGradient(OrbitTheme.currentDarkTheme);

    return Stack(
      children: [
        // Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),

        // leichter Blur „cremig“
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.transparent),
        ),

        // Content
        child,
      ],
    );
  }
}