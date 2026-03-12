import 'package:flutter/material.dart';

// Haupthintergrundfarbe – wird überall als scaffoldBackgroundColor gesetzt,
// damit beim Screen-Wechsel KEIN weißer Blitz erscheint.
const _kBgColor = Color(0xFF07020F);

class OrbitTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _kBgColor,
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
      // ← WICHTIG: NICHT transparent. Dunkel = kein weißer Blitz.
      scaffoldBackgroundColor: _kBgColor,
      textTheme: const TextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      pageTransitionsTheme: _pageTransitions(),
    );
  }

  static PageTransitionsTheme _pageTransitions() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _OrbitPageTransition(),
        TargetPlatform.iOS: _OrbitPageTransition(),
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Einfacher Fade (kein Slide → weniger GPU-Arbeit, kein weißes Flackern
// an den Rändern beim Slide-Overshot).
// ──────────────────────────────────────────────────────────────────────────
class _OrbitPageTransition extends PageTransitionsBuilder {
  const _OrbitPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// OrbitBackground
// Kein BackdropFilter! Nur Gradient + RadialGradient-Orbs.
// BackdropFilter auf dem ganzen Screen → massiver Lag bei Animationen.
// ──────────────────────────────────────────────────────────────────────────
class OrbitBackground extends StatelessWidget {
  final Widget child;

  const OrbitBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Basis-Gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D0B65),
                Color(0xFF10041E),
                Color(0xFF07020F),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),

        // Lila Orb oben-mitte
        Positioned(
          top: -110,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Blauer Orb unten-rechts
        Positioned(
          bottom: -90,
          right: -90,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3A0FA0).withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
