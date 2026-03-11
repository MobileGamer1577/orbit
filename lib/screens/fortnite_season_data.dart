import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  🎮 FORTNITE SEASON DATEN – Hier einfach Daten updaten!
//
//  Format: DateTime(Jahr, Monat, Tag)
//  Beispiel: 15. April 2026 → DateTime(2026, 4, 15)
// ─────────────────────────────────────────────────────────────

final List<FortnitePassData> fortnitePasses = [
  FortnitePassData(
    name: 'Battle Pass',
    icon: Icons.shield,
    startDate: DateTime(2025, 11, 30),
    endDate: DateTime(2026, 3, 19),
    color: Color(0xFF42A5F5),
  ),
  FortnitePassData(
    name: 'LEGO Pass',
    icon: Icons.widgets,
    startDate: DateTime(2025, 12, 11),
    endDate: DateTime(2026, 4, 1),
    color: Color(0xFF66BB6A),
  ),
  FortnitePassData(
    name: 'OG Pass',
    icon: Icons.bolt,
    startDate: DateTime(2025, 12, 11),
    endDate: DateTime(2026, 3, 18),
    color: Color(0xFFCE93D8),
  ),
  FortnitePassData(
    name: 'Festival Pass',
    icon: Icons.music_note,
    startDate: DateTime(2026, 2, 5),
    endDate: DateTime(2026, 4, 16),
    color: Color(0xFFF48FB1),
  ),
  FortnitePassData(
    name: 'Test Countdown',
    icon: Icons.music_note,
    startDate: DateTime(1980, 1, 1),
    endDate: DateTime(2026, 3, 12),
    color: Color(0xFFF48FB1),
  ),
];

// ─────────────────────────────────────────────────────────────
//  Datenmodell – nicht anfassen!
// ─────────────────────────────────────────────────────────────

class FortnitePassData {
  final String name;
  final IconData icon;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;

  const FortnitePassData({
    required this.name,
    required this.icon,
    required this.startDate,
    required this.endDate,
    required this.color,
  });

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    final total = endDate.difference(startDate).inMilliseconds;
    final elapsed = now.difference(startDate).inMilliseconds;
    return elapsed / total;
  }
}
