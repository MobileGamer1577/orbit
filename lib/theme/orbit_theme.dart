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
}

// ──────────────────────────────────────────────
// Custom Page Transition
// ──────────────────────────────────────────────
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

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// OrbitBackground
//
// ❌ KEIN BackdropFilter über den ganzen Screen – das kostet bei jeder
//    Animation Frames, weil Flutter den kompletten Screen-Inhalt
//    neu blurren muss. Stattdessen: nur Gradient + zwei dekorative
//    RadialGradient-Orbs (reine CPU-Paint, kein Compositing-Layer).
// ──────────────────────────────────────────────────────────────────────────
class OrbitBackground extends StatelessWidget {
  final Widget child;

  const OrbitBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Basis-Gradient (3 Farben, links-oben → rechts-unten)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D0B65),
                Color(0xFF10041E),
                Color(0xFF060209),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),

        // Lila Glow-Orb oben-mitte
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

        // Blauer Glow-Orb unten-rechts
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

        // Content
        child,
      ],
    );
  }
}
