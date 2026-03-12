import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass-Karte mit BackdropFilter.
///
/// BackdropFilter hier ist OK – er wird nur auf die kleine Kartenfläche
/// angewendet, nicht auf den ganzen Screen. Das kostet deutlich weniger.
class OrbitGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const OrbitGlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.11),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.13)),
          ),
          child: child,
        ),
      ),
    );
  }
}
