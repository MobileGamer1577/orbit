import 'dart:ui';
import 'package:flutter/material.dart';

class OrbitTheme {
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
        TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
      },
    );
  }

  /// Das einzige Design: Reiches tiefes Lila
  static List<Color> backgroundGradient() {
    return const [
      Color(0xFF2D0B65), // sattes Lila oben
      Color(0xFF10041E), // tiefes Violett mittig
      Color(0xFF060209), // fast schwarz unten
    ];
  }
}

/// ──────────────────────────────────────────────
/// Custom Page Transition (Fade + kleiner Slide)
/// ──────────────────────────────────────────────
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
    if (route.isFirst) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    final slide = Tween<Offset>(
      begin: const Offset(0.03, 0.0),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

/// ──────────────────────────────────────────────
/// OrbitBackground – verschönerter Hintergrund
/// mit Gradient + subtilen Leucht-Orbs
/// ──────────────────────────────────────────────
class OrbitBackground extends StatelessWidget {
  final Widget child;

  const OrbitBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.backgroundGradient();

    return Stack(
      children: [
        // Basis-Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),

        // Leuchtender Orb oben-mitte (lila Glow)
        Positioned(
          top: -80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Zweiter subtiler Orb unten-rechts (blau-violett)
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4A1FA8).withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Soft Blur über allem für cremigen Look
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(color: Colors.transparent),
        ),

        // Content
        child,
      ],
    );
  }
}
