import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//
//  🎨 MINECRAFT TEXT WIDGET
//  Datei: lib/widgets/minecraft_text.dart
//
//  Parst Minecraft §-Farbcodes und rendert sie als
//  farbigen Flutter-Text (RichText / TextSpan).
//
//  Unterstützte Codes:
//    §0 = Schwarz       §8 = Dunkelgrau
//    §1 = Dunkelblau    §9 = Blau
//    §2 = Dunkelgrün    §a = Grün
//    §3 = Dunkelaquamarin §b = Aquamarin
//    §4 = Dunkelrot     §c = Rot
//    §5 = Lila          §d = Hellviolett
//    §6 = Gold          §e = Gelb
//    §7 = Grau          §f = Weiß
//    §l = Fett          §o = Kursiv
//    §n = Unterstrichen §m = Durchgestrichen
//    §r = Reset
//
//  Verwendung:
//    MinecraftText(text: '§6Goldener §cRoter Text')
//    MinecraftText(text: loreString, fontSize: 13)
//
// ══════════════════════════════════════════════════════════════

// ── Farbzuordnung: § + Zeichen → Flutter Color ─────────────────
const Map<String, Color> _kMcColors = {
  '0': Color(0xFF000000), // Schwarz
  '1': Color(0xFF0000AA), // Dunkelblau
  '2': Color(0xFF00AA00), // Dunkelgrün
  '3': Color(0xFF00AAAA), // Dunkelaquamarin
  '4': Color(0xFFAA0000), // Dunkelrot
  '5': Color(0xFFAA00AA), // Lila
  '6': Color(0xFFFFAA00), // Gold
  '7': Color(0xFFAAAAAA), // Grau
  '8': Color(0xFF555555), // Dunkelgrau
  '9': Color(0xFF5555FF), // Blau
  'a': Color(0xFF55FF55), // Grün
  'b': Color(0xFF55FFFF), // Aquamarin
  'c': Color(0xFFFF5555), // Rot
  'd': Color(0xFFFF55FF), // Hellviolett
  'e': Color(0xFFFFFF55), // Gelb
  'f': Color(0xFFFFFFFF), // Weiß
};

// ──────────────────────────────────────────────────────────────
//  MinecraftText — Haupt-Widget
//
//  Gibt einen RichText zurück wenn §-Codes gefunden werden,
//  sonst einfachen Text (Performance-Optimierung).
// ──────────────────────────────────────────────────────────────

class MinecraftText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color fallbackColor;  // Farbe wenn kein §-Code aktiv
  final int? maxLines;
  final TextOverflow overflow;

  const MinecraftText({
    super.key,
    required this.text,
    this.fontSize     = 14,
    this.fontWeight   = FontWeight.w500,
    this.fallbackColor = Colors.white,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    // Enthält der Text überhaupt §-Codes?
    // Wenn nicht → einfacher Text, kein Overhead
    if (!text.contains('§')) {
      return Text(
        text,
        style: TextStyle(
          color:      fallbackColor,
          fontSize:   fontSize,
          fontWeight: fontWeight,
        ),
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // § gefunden → parsen und als RichText rendern
    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        children: _parseMinecraftText(text, fontSize, fontWeight, fallbackColor),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  _parseMinecraftText — Kern-Parser
//
//  Geht den String Zeichen für Zeichen durch.
//  Findet §x → setzt aktuelle Farbe/Format.
//  Sammelt normalen Text → erstellt TextSpan.
// ──────────────────────────────────────────────────────────────

List<TextSpan> _parseMinecraftText(
  String text,
  double fontSize,
  FontWeight baseWeight,
  Color fallback,
) {
  final spans = <TextSpan>[];

  // Aktueller Zustand (wird durch §-Codes verändert)
  Color       currentColor  = fallback;
  bool        bold          = false;
  bool        italic        = false;
  bool        underline     = false;
  bool        strikethrough = false;

  final buf = StringBuffer(); // Puffer für normalen Text

  // Hilfsfunktion: puffer → TextSpan leeren
  void flush() {
    if (buf.isEmpty) return;
    spans.add(TextSpan(
      text: buf.toString(),
      style: TextStyle(
        color:      currentColor,
        fontSize:   fontSize,
        fontWeight: bold ? FontWeight.w900 : baseWeight,
        fontStyle:  italic ? FontStyle.italic : FontStyle.normal,
        decoration: _buildDecoration(underline, strikethrough),
      ),
    ));
    buf.clear();
  }

  int i = 0;
  while (i < text.length) {
    final ch = text[i];

    if (ch == '§' && i + 1 < text.length) {
      // Puffer leeren bevor wir den Code verarbeiten
      flush();

      final code = text[i + 1].toLowerCase();

      if (_kMcColors.containsKey(code)) {
        // Farbcode → Farbe wechseln, Format beibehalten
        currentColor = _kMcColors[code]!;
      } else {
        switch (code) {
          case 'l': bold          = true;  break;
          case 'o': italic        = true;  break;
          case 'n': underline     = true;  break;
          case 'm': strikethrough = true;  break;
          case 'r':
            // Reset → zurück auf Standardwerte
            currentColor  = fallback;
            bold          = false;
            italic        = false;
            underline     = false;
            strikethrough = false;
            break;
        }
      }

      i += 2; // §x überspringen
    } else {
      buf.write(ch);
      i++;
    }
  }

  // Restlichen Puffer leeren
  flush();

  return spans;
}

// Baut TextDecoration aus underline + strikethrough
TextDecoration _buildDecoration(bool underline, bool strikethrough) {
  if (underline && strikethrough) {
    return TextDecoration.combine([
      TextDecoration.underline,
      TextDecoration.lineThrough,
    ]);
  }
  if (underline)     return TextDecoration.underline;
  if (strikethrough) return TextDecoration.lineThrough;
  return TextDecoration.none;
}

// ──────────────────────────────────────────────────────────────
//  Hilfsfunktion: §-Codes aus String entfernen (plain text)
//
//  Verwendung: wenn nur der Suchindex wichtig ist,
//  nicht die Darstellung.
// ──────────────────────────────────────────────────────────────

String stripMinecraftCodes(String text) {
  final result = StringBuffer();
  int i = 0;
  while (i < text.length) {
    if (text[i] == '§' && i + 1 < text.length) {
      i += 2; // §x überspringen
    } else {
      result.write(text[i]);
      i++;
    }
  }
  return result.toString();
}
