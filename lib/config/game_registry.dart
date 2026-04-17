import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//
//  🎮 GAME REGISTRY — Zentrale Spiele-Konfiguration
//  Datei: lib/config/game_registry.dart
//
//  Das ist die wichtigste Konfigurations-Datei in Orbit.
//  Hier wird alles über Spiele und ihre Modi definiert.
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  WIE ORBIT AUFGEBAUT IST (Überblick)                    │
//  │                                                         │
//  │  GameSelectScreen (Startseite)                          │
//  │    ↓ tippt auf ein Spiel                                │
//  │                                                         │
//  │  → Spiel OHNE Hub (hasCustomHub: false)                 │
//  │      ModeSelectScreen → TaskListScreen                  │
//  │                                                         │
//  │  → Spiel MIT Hub (hasCustomHub: true)                   │
//  │      MeinHubScreen (z.B. FortniteHubScreen)             │
//  │        ↓ hat mehrere Buttons                            │
//  │        ├── ModeSelectScreen → TaskListScreen            │
//  │        ├── Shop, Festival, Cosmetics...                 │
//  │        └── weitere eigene Screens                       │
//  └─────────────────────────────────────────────────────────┘
//
//  ✏️  WO WAS EINTRAGEN?
//
//  Neues Spiel (einfach, ohne Hub):
//    1. GameDefinition in games-Liste eintragen
//    2. GameMode-Einträge ergänzen
//    3. JSON-Datei anlegen (assets/data/meinspiel_modus.json)
//    → Fertig! Keine andere Datei anfassen.
//
//  Neues Spiel (komplex, mit eigenem Hub):
//    1. GameDefinition mit hasCustomHub: true eintragen
//    2. Neuen Hub-Screen erstellen (Anleitung: game_select_screen.dart)
//    3. In game_select_screen.dart einen case eintragen
//
// ══════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────
//  GameMode — Ein einzelner Spielmodus
//  Beispiele: "Battle Royale", "Zombies", "Multiplayer"
// ──────────────────────────────────────────────────────────────

class GameMode {
  /// Die ID des Spiels, zu dem dieser Modus gehört.
  /// Muss exakt mit GameDefinition.id übereinstimmen.
  final String gameId;

  /// Angezeigter Name des Modus (z.B. "Battle Royale")
  final String title;

  /// Kurze Beschreibung unter dem Titel
  final String subtitle;

  /// Pfad zur JSON-Datei mit den Quest-IDs für diesen Modus.
  /// Datei muss in assets/data/ liegen.
  /// Aufbau der JSON-Datei → Kommentar am Ende dieser Datei.
  final String assetPath;

  /// Material-Icon für die Modus-Karte.
  /// Alle Icons: https://fonts.google.com/icons
  final IconData icon;

  /// Akzentfarbe der Modus-Karte
  final Color color;

  const GameMode({
    required this.gameId,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
    required this.color,
  });
}

// ──────────────────────────────────────────────────────────────
//  GameDefinition — Ein vollständiges Spiel
//  Jede GameDefinition erscheint als Karte auf dem Startscreen.
// ──────────────────────────────────────────────────────────────

class GameDefinition {
  /// Eindeutige ID des Spiels.
  /// Nur Kleinbuchstaben, keine Leerzeichen.
  /// Beispiele: 'fortnite', 'bo7', 'valorant'
  final String id;

  /// Angezeigter Titel auf dem Startscreen
  final String title;

  /// Kurze Beschreibung unter dem Titel
  final String subtitle;

  /// Hauptfarbe des Icons
  final Color accentColor;

  /// Zweite Farbe für den Icon-Verlauf (meist dunkler)
  final Color secondaryColor;

  /// Material-Icon auf der Spielkarte
  final IconData icon;

  /// false → nur Modi-Liste, kein eigener Hub-Screen
  ///          Tippen öffnet direkt ModeSelectScreen
  ///          Beispiel: BO7
  ///
  /// true  → eigener Hub-Screen mit mehreren Buttons
  ///          Beispiel: Fortnite (Shop, Festival, Cosmetics...)
  ///          ⚠️ Braucht zusätzlich einen case in game_select_screen.dart
  final bool hasCustomHub;

  /// Alle Spielmodi dieses Spiels
  final List<GameMode> modes;

  const GameDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.icon,
    required this.hasCustomHub,
    required this.modes,
  });
}

// ══════════════════════════════════════════════════════════════
//
//  ✏️  HIER SPIELE UND MODI EINTRAGEN
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  NEUES SPIEL hinzufügen → Vorlage am Ende der Liste     │
//  │  MODUS hinzufügen → in modes: [ ... ] des Spiels        │
//  │  SPIEL verstecken → Block auskommentieren (Strg+/)      │
//  └─────────────────────────────────────────────────────────┘
//
// ══════════════════════════════════════════════════════════════

class GameRegistry {
  /// Alle Spiele — Reihenfolge = Reihenfolge auf dem Startscreen.
  static const List<GameDefinition> games = [
    // ┌─────────────────────────────────────────────────────┐
    // │ SPIEL 1: Fortnite (mit eigenem Hub-Screen)          │
    // └─────────────────────────────────────────────────────┘
    GameDefinition(
      id: 'fortnite',
      title: 'Fortnite',
      subtitle: 'Aufträge • Season-Countdown • Item-Shop',
      accentColor: Color(0xFF00D4FF),
      secondaryColor: Color(0xFF0070FF),
      icon: Icons.bolt,
      hasCustomHub: true,
      // ↑ Hat FortniteHubScreen — Navigation in game_select_screen.dart
      modes: [
        GameMode(
          gameId: 'fortnite',
          title: 'Battle Royale',
          subtitle: 'Aufträge für Battle Royale',
          assetPath: 'assets/data/fortnite_br.json',
          icon: Icons.layers,
          color: Color(0xFF00D4FF),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'Fortnite Reload',
          subtitle: 'Aufträge für Reload',
          assetPath: 'assets/data/fortnite_reload.json',
          icon: Icons.restart_alt,
          color: Color(0xFF00C8A0),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'Ballistic',
          subtitle: 'Aufträge für Ballistic',
          assetPath: 'assets/data/fortnite_ballistic.json',
          icon: Icons.music_note,
          color: Color(0xFFF48FB1),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'LEGO Fortnite',
          subtitle: 'Aufträge für LEGO Fortnite',
          assetPath: 'assets/data/fortnite_lego.json',
          icon: Icons.extension,
          color: Color(0xFFFFD600),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'Delulu',
          subtitle: 'Aufträge für Delulu',
          assetPath: 'assets/data/fortnite_delulu.json',
          icon: Icons.auto_awesome,
          color: Color(0xFFFF81E0),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'Blitz Royale',
          subtitle: 'Aufträge für Blitz Royale',
          assetPath: 'assets/data/fortnite_blitz_royale.json',
          icon: Icons.flash_on,
          color: Color(0xFFFFC107),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'OG',
          subtitle: 'Aufträge für OG Fortnite',
          assetPath: 'assets/data/fortnite_og.json',
          icon: Icons.history,
          color: Color(0xFF9C6FFF),
        ),
        GameMode(
          gameId: 'fortnite',
          title: 'Kreativ',
          subtitle: 'Wöchentliche Aufträge für Kreativ-Inseln',
          assetPath: 'assets/data/fortnite_kreativ.json',
          icon: Icons.palette,
          color: Color(0xFFFF6B35),
        ),
      ],
    ),

    // ┌─────────────────────────────────────────────────────┐
    // │ SPIEL 2: Call of Duty: BO7 (direkt zu Modi)         │
    // └─────────────────────────────────────────────────────┘
    GameDefinition(
      id: 'bo7',
      title: 'Call of Duty: BO7',
      subtitle: 'Steam Erfolge • PlayStation Trophäen • Modi',
      accentColor: Color(0xFFFF6B35),
      secondaryColor: Color(0xFFCC2200),
      icon: Icons.military_tech,
      hasCustomHub: false,
      // ↑ Kein Hub — Tippen öffnet direkt ModeSelectScreen
      modes: [
        GameMode(
          gameId: 'bo7',
          title: 'Koop & Endspiel',
          subtitle: 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)',
          assetPath: 'assets/data/bo7_koop_endspiel.json',
          icon: Icons.handshake,
          color: Color(0xFF4CAF50),
        ),
        GameMode(
          gameId: 'bo7',
          title: 'Mehrspieler',
          subtitle: 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)',
          assetPath: 'assets/data/bo7_mp.json',
          icon: Icons.sports_esports,
          color: Color(0xFFFF6B35),
        ),
        GameMode(
          gameId: 'bo7',
          title: 'Zombies',
          subtitle: 'Erfolge • Weekly-Aufgaben (Soon) • Tarnungen (Soon)',
          assetPath: 'assets/data/bo7_zombies.json',
          icon: Icons.bug_report,
          color: Color(0xFF76FF03),
        ),
        GameMode(
          gameId: 'bo7',
          title: 'Warzone',
          subtitle: 'Weekly-Aufgaben (Soon) • Visitenkarten (Soon)',
          assetPath: 'assets/data/bo7_warzone.json',
          icon: Icons.public,
          color: Color(0xFF00B0FF),
        ),
      ],
    ),

    // ══════════════════════════════════════════════════════
    // ✏️  NEUES SPIEL HIER EINFÜGEN
    //
    // ── VARIANTE A: Einfaches Spiel (nur Quest-Listen) ────
    //
    // GameDefinition(
    //   id: 'valorant',                    // eindeutige ID
    //   title: 'Valorant',                 // Titel auf Startscreen
    //   subtitle: 'Agenten • Ränge',       // Kurzbeschreibung
    //   accentColor: Color(0xFFFF4655),    // Spielfarbe
    //   secondaryColor: Color(0xFF8B0000), // dunklere Zweitfarbe
    //   icon: Icons.gps_fixed,             // Material-Icon
    //   hasCustomHub: false,               // ← EINFACH: direkt zu Modi
    //   modes: [
    //     GameMode(
    //       gameId: 'valorant',            // muss = id oben sein
    //       title: 'Unranked',
    //       subtitle: 'Normale Matches',
    //       assetPath: 'assets/data/valorant_unranked.json',
    //       icon: Icons.sports_esports,
    //       color: Color(0xFFFF4655),
    //     ),
    //     // weitere Modi hier...
    //   ],
    // ),
    //
    // ── VARIANTE B: Spiel mit eigenem Hub-Screen ──────────
    //
    // GameDefinition(
    //   id: 'minecraft',
    //   title: 'Minecraft',
    //   subtitle: 'Crafting • Achievements • Welten',
    //   accentColor: Color(0xFF4CAF50),
    //   secondaryColor: Color(0xFF1B5E20),
    //   icon: Icons.grid_on,
    //   hasCustomHub: true,                // ← KOMPLEX: braucht Hub-Screen
    //   modes: [                           //   → Anleitung: game_select_screen.dart
    //     GameMode(
    //       gameId: 'minecraft',
    //       title: 'Survival',
    //       subtitle: 'Achievements für Survival',
    //       assetPath: 'assets/data/minecraft_survival.json',
    //       icon: Icons.forest,
    //       color: Color(0xFF4CAF50),
    //     ),
    //   ],
    // ),
    // ══════════════════════════════════════════════════════
  ];

  // ──────────────────────────────────────────────────────────
  //  Hilfsmethoden — nicht ändern
  // ──────────────────────────────────────────────────────────

  /// Gibt ein Spiel anhand seiner ID zurück.
  static GameDefinition byId(String id) {
    return games.firstWhere(
      (g) => g.id == id,
      orElse: () => throw ArgumentError(
        'GameRegistry: Kein Spiel mit ID "$id" gefunden.\n'
        'Ist das Spiel in der games-Liste eingetragen?',
      ),
    );
  }

  /// Gibt alle Modi eines Spiels zurück.
  static List<GameMode> modesFor(String gameId) {
    return byId(gameId).modes;
  }
}

// ══════════════════════════════════════════════════════════════
//
//  📄 JSON-DATEIEN ANLEGEN — Kurzanleitung
//
//  Jeder Modus braucht zwei Dinge:
//  1. Eine Struktur-Datei  →  assets/data/meinspiel_modus.json
//  2. Texte eintragen in  →  assets/data/quests_database.json
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  STRUKTUR-DATEI (meinspiel_modus.json)                  │
//  │                                                         │
//  │  Normale Aufträge:                                      │
//  │  {                                                      │
//  │    "phases": [{                                         │
//  │      "type": "normal",                                  │
//  │      "label": { "de": "Woche 1", "en": "Week 1" },     │
//  │      "quests": ["mein_w1_01", "mein_w1_02"]            │
//  │    }]                                                   │
//  │  }                                                      │
//  │                                                         │
//  │  Meilensteine (mehrstufig, z.B. 20 Phasen):             │
//  │  {                                                      │
//  │    "phases": [{                                         │
//  │      "type": "milestone",                               │
//  │      "label": { "de": "Meilensteine", "en": "..." },   │
//  │      "quests": [                                        │
//  │        { "phases": ["ms_01_p01", "ms_01_p02", ...] }   │
//  │      ]                                                  │
//  │    }]                                                   │
//  │  }                                                      │
//  └─────────────────────────────────────────────────────────┘
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  QUESTS_DATABASE.JSON — Texte zu den IDs               │
//  │                                                         │
//  │  "mein_w1_01": {                                        │
//  │    "de": {                                              │
//  │      "title": "Eliminiere 5 Spieler",                   │
//  │      "description": "Woche 1 • 15k XP • 0/5"           │
//  │    },                                                   │
//  │    "en": {                                              │
//  │      "title": "Eliminate 5 players",                    │
//  │      "description": "Week 1 • 15k XP • 0/5"            │
//  │    }                                                    │
//  │  }                                                      │
//  └─────────────────────────────────────────────────────────┘
//
//  ⚠️  WICHTIG: assets/data/ ist in pubspec.yaml eingetragen —
//      neue Dateien dort werden automatisch eingebunden.
//
// ══════════════════════════════════════════════════════════════
