import 'package:flutter/material.dart';

/// Glass-Karte OHNE BackdropFilter.
///
/// BackdropFilter auf mehreren gleichzeitig sichtbaren Karten (z.B. in einer
/// ListView) bedeutet, dass Flutter für jede Karte einen eigenen Compositing-
/// Layer anlegt und alles dahinter separat blurren muss — das ist die
/// häufigste Ursache für Ruckler in Flutter-Listen.
///
/// Der Glaseffekt wird hier rein visuell mit einem halbtransparenten
/// Gradient + einem feinen weißen Border imitiert — auf einem dunklen
/// Hintergrund wie OrbitBackground ist der Unterschied kaum zu sehen,
/// die Performance aber deutlich besser.
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}
