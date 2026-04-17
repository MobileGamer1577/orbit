import 'dart:convert';

/// Universelles Modell für alle Fortnite-Cosmetic-Typen
class CosmeticItem {
  final String id;
  final String name;
  final String typeDisplay;
  final String typeValue;
  final String rarityValue;
  final String? imageUrl;
  final String? description;
  final String? introduction;  // "Introduced in Chapter X, Season Y."
  final String? addedDate;     // ISO 8601
  final String? lastSeen;      // ISO 8601
  final String? setName;
  final String? seriesName;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.typeDisplay,
    required this.typeValue,
    required this.rarityValue,
    this.imageUrl,
    this.description,
    this.introduction,
    this.addedDate,
    this.lastSeen,
    this.setName,
    this.seriesName,
  });

  // ── JSON (für Hive-Speicherung) ──────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'typeDisplay': typeDisplay,
    'typeValue': typeValue,
    'rarityValue': rarityValue,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (description != null) 'description': description,
    if (introduction != null) 'introduction': introduction,
    if (addedDate != null) 'addedDate': addedDate,
    if (lastSeen != null) 'lastSeen': lastSeen,
    if (setName != null) 'setName': setName,
    if (seriesName != null) 'seriesName': seriesName,
  };

  factory CosmeticItem.fromJson(Map<String, dynamic> j) => CosmeticItem(
    id:           (j['id']          as String?) ?? '',
    name:         (j['name']        as String?) ?? '',
    typeDisplay:  (j['typeDisplay'] as String?) ?? '',
    typeValue:    (j['typeValue']   as String?) ?? '',
    rarityValue:  (j['rarityValue'] as String?) ?? 'common',
    imageUrl:     j['imageUrl']    as String?,
    description:  j['description'] as String?,
    introduction: j['introduction'] as String?,
    addedDate:    j['addedDate']   as String?,
    lastSeen:     j['lastSeen']    as String?,
    setName:      j['setName']     as String?,
    seriesName:   j['seriesName']  as String?,
  );

  String toJsonString() => jsonEncode(toJson());

  // ── Hilfsmethode: Set-Name aus API-Text extrahieren ──────
  // "Part of the Rowdy Reputation set." → "Rowdy Reputation"
  static String? _parseSetName(Map<dynamic, dynamic>? set_) {
    if (set_ == null) return null;
    // Versuche erst den sauberen value-Feld
    final value = set_['value'] as String?;
    final text  = set_['text']  as String?;
    // text wie "Part of the Rowdy Reputation set." aufräumen
    if (text != null && text.isNotEmpty) {
      var name = text.trim();
      if (name.toLowerCase().startsWith('part of the ')) {
        name = name.substring('part of the '.length);
      }
      if (name.toLowerCase().endsWith(' set.')) {
        name = name.substring(0, name.length - ' set.'.length);
      } else if (name.endsWith('.')) {
        name = name.substring(0, name.length - 1);
      }
      name = name.trim();
      if (name.isNotEmpty) return name;
    }
    return (value != null && value.isNotEmpty) ? value : null;
  }

  // ── API-Parser ───────────────────────────────────────────

  factory CosmeticItem.fromBrApi(Map<String, dynamic> j) {
    final imgs   = j['images']       as Map<String, dynamic>?;
    final type   = j['type']         as Map<String, dynamic>?;
    final rarity = j['rarity']       as Map<String, dynamic>?;
    final set_   = j['set']          as Map<String, dynamic>?;
    final series = j['series']       as Map<String, dynamic>?;
    final intro  = j['introduction'] as Map<String, dynamic>?;
    final hist   = j['shopHistory']  as List?;

    return CosmeticItem(
      id:           (j['id']          as String?) ?? '',
      name:         (j['name']        as String?) ?? '',
      typeDisplay:  (type?['displayValue']  as String?) ?? '',
      typeValue:    (type?['value']         as String?) ?? '',
      rarityValue:  (rarity?['value']       as String?) ?? 'common',
      imageUrl:     (imgs?['featured']      as String?)
                 ?? (imgs?['icon']          as String?)
                 ?? (imgs?['smallIcon']     as String?),
      description:  j['description']        as String?,
      introduction: intro?['text']          as String?,
      addedDate:    j['added']              as String?,
      lastSeen:     (hist != null && hist.isNotEmpty) ? hist.last as String? : null,
      setName:      _parseSetName(set_),
      seriesName:   series?['text']         as String?,
    );
  }

  factory CosmeticItem.fromTrackApi(Map<String, dynamic> j) {
    final title  = (j['title']  as String?) ?? '';
    final artist = (j['artist'] as String?) ?? '';
    return CosmeticItem(
      id:          (j['id']    as String?) ?? '',
      name:        artist.isNotEmpty ? '$title – $artist' : title,
      typeDisplay: 'Jam Track',
      typeValue:   'track',
      rarityValue: 'epic',
      imageUrl:    j['albumArt'] as String?,
      addedDate:   j['added']   as String?,
    );
  }

  factory CosmeticItem.fromInstrumentApi(Map<String, dynamic> j) {
    final imgs = j['images'] as Map<String, dynamic>?;
    final type = j['type']   as Map<String, dynamic>?;
    return CosmeticItem(
      id:          (j['id']   as String?) ?? '',
      name:        (j['name'] as String?) ?? '',
      typeDisplay: (type?['displayValue'] as String?) ?? 'Instrument',
      typeValue:   (type?['value']        as String?) ?? 'instrument',
      rarityValue: 'rare',
      imageUrl:    (imgs?['featured'] as String?)
                ?? (imgs?['small']    as String?)
                ?? (imgs?['icon']     as String?),
      addedDate:   j['added'] as String?,
    );
  }

  factory CosmeticItem.fromCarApi(Map<String, dynamic> j) {
    final imgs   = j['images'] as Map<String, dynamic>?;
    final rarity = j['rarity'] as Map<String, dynamic>?;
    return CosmeticItem(
      id:          (j['id']   as String?) ?? '',
      name:        (j['name'] as String?) ?? '',
      typeDisplay: 'Car Body',
      typeValue:   'car',
      rarityValue: (rarity?['value'] as String?) ?? 'uncommon',
      imageUrl:    (imgs?['featured'] as String?)
                ?? (imgs?['small']    as String?)
                ?? (imgs?['icon']     as String?),
      addedDate:   j['added'] as String?,
    );
  }

  factory CosmeticItem.fromLegoApi(Map<String, dynamic> j) {
    final imgs = j['images'] as Map<String, dynamic>?;
    final type = j['type']   as Map<String, dynamic>?;
    return CosmeticItem(
      id:          (j['id']   as String?) ?? '',
      name:        (j['name'] as String?) ?? '',
      typeDisplay: (type?['displayValue'] as String?) ?? 'LEGO',
      typeValue:   (type?['value']        as String?) ?? 'lego',
      rarityValue: 'uncommon',
      imageUrl:    (imgs?['featured'] as String?)
                ?? (imgs?['small']    as String?)
                ?? (imgs?['icon']     as String?),
      addedDate:   j['added'] as String?,
    );
  }

  factory CosmeticItem.fromBeanApi(Map<String, dynamic> j) {
    final imgs = j['images'] as Map<String, dynamic>?;
    return CosmeticItem(
      id:          (j['id']   as String?) ?? '',
      name:        (j['name'] as String?) ?? '',
      typeDisplay: 'Bean',
      typeValue:   'bean',
      rarityValue: 'rare',
      imageUrl:    (imgs?['featured'] as String?)
                ?? (imgs?['small']    as String?)
                ?? (imgs?['icon']     as String?),
      addedDate:   j['added'] as String?,
    );
  }
}
