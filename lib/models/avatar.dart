import 'dart:convert';

import 'package:flutter/material.dart';

class AvatarData {
  final String baseFace;

  /// Cara base por imagen (foto IA). Ruta tipo `assets/avatars/custom_01.png`.
  /// Null = usar cara vectorial ([baseFace]). Migración: avatares antiguos
  /// no traen este campo y quedan en null sin romper.
  final String? assetPath;
  final String hat;
  final String glasses;
  final String mask;
  final String bgGradientId;
  final int bgColorValue;
  final double hatOffsetX;
  final double hatOffsetY;
  final double hatScale;
  final double glassesOffsetX;
  final double glassesOffsetY;
  final double glassesScale;
  final double maskOffsetX;
  final double maskOffsetY;
  final double maskScale;
  final double faceOffsetX;
  final double faceOffsetY;
  final double faceScale;

  const AvatarData({
    required this.baseFace,
    this.assetPath,
    this.hat = '',
    this.glasses = '',
    this.mask = '',
    this.bgGradientId = 'sunset',
    this.bgColorValue = 0xFFFACC15,
    this.hatOffsetX = 0,
    this.hatOffsetY = 0,
    this.hatScale = 1,
    this.glassesOffsetX = 0,
    this.glassesOffsetY = 0,
    this.glassesScale = 1,
    this.maskOffsetX = 0,
    this.maskOffsetY = 0,
    this.maskScale = 1,
    this.faceOffsetX = 0,
    this.faceOffsetY = 0,
    this.faceScale = 1,
  });

  Color get bgColor => Color(bgColorValue);

  LinearGradient get bgGradient => AvatarOptions.gradientFor(bgGradientId);

  /// True si hay foto IA seleccionada como cara base.
  bool get hasCustomImage => assetPath != null && assetPath!.isNotEmpty;

  /// Ruta efectiva a renderizar: [assetPath] explícito o el PNG del slot
  /// custom ([baseFace] = `custom_XX`). Null = usar vectorial.
  /// La existencia del archivo se resuelve en UI con `errorBuilder`
  /// (fallback a vectorial, nunca crashea).
  String? get resolvedFaceAssetPath {
    if (hasCustomImage) return assetPath;
    return AvatarOptions.assetPathForFaceId(baseFace);
  }

  static double _clampOffset(double v) => v.clamp(-0.5, 0.5).toDouble();
  static double _clampScale(double v) => v.clamp(0.5, 1.5).toDouble();

  static double _parseOffset(dynamic v) {
    if (v is num) return _clampOffset(v.toDouble());
    if (v is String) {
      final d = double.tryParse(v);
      if (d != null) return _clampOffset(d);
    }
    return 0;
  }

  static double _parseScale(dynamic v) {
    if (v is num) return _clampScale(v.toDouble());
    if (v is String) {
      final d = double.tryParse(v);
      if (d != null) return _clampScale(d);
    }
    return 1;
  }

  AvatarData copyWith({
    String? baseFace,
    String? assetPath,
    bool clearAssetPath = false,
    String? hat,
    String? glasses,
    String? mask,
    String? bgGradientId,
    int? bgColorValue,
    Color? bgColor,
    double? hatOffsetX,
    double? hatOffsetY,
    double? hatScale,
    double? glassesOffsetX,
    double? glassesOffsetY,
    double? glassesScale,
    double? maskOffsetX,
    double? maskOffsetY,
    double? maskScale,
    double? faceOffsetX,
    double? faceOffsetY,
    double? faceScale,
  }) {
    return AvatarData(
      baseFace: baseFace ?? this.baseFace,
      assetPath: clearAssetPath ? null : (assetPath ?? this.assetPath),
      hat: hat ?? this.hat,
      glasses: glasses ?? this.glasses,
      mask: mask ?? this.mask,
      bgGradientId: bgGradientId ?? this.bgGradientId,
      bgColorValue: bgColorValue ?? bgColor?.toInt32() ?? this.bgColorValue,
      hatOffsetX: hatOffsetX != null ? _clampOffset(hatOffsetX) : this.hatOffsetX,
      hatOffsetY: hatOffsetY != null ? _clampOffset(hatOffsetY) : this.hatOffsetY,
      hatScale: hatScale != null ? _clampScale(hatScale) : this.hatScale,
      glassesOffsetX: glassesOffsetX != null ? _clampOffset(glassesOffsetX) : this.glassesOffsetX,
      glassesOffsetY: glassesOffsetY != null ? _clampOffset(glassesOffsetY) : this.glassesOffsetY,
      glassesScale: glassesScale != null ? _clampScale(glassesScale) : this.glassesScale,
      maskOffsetX: maskOffsetX != null ? _clampOffset(maskOffsetX) : this.maskOffsetX,
      maskOffsetY: maskOffsetY != null ? _clampOffset(maskOffsetY) : this.maskOffsetY,
      maskScale: maskScale != null ? _clampScale(maskScale) : this.maskScale,
      faceOffsetX: faceOffsetX != null ? _clampOffset(faceOffsetX) : this.faceOffsetX,
      faceOffsetY: faceOffsetY != null ? _clampOffset(faceOffsetY) : this.faceOffsetY,
      faceScale: faceScale != null ? _clampScale(faceScale) : this.faceScale,
    );
  }

  /// Resetea offset/scale de un accesorio.
  AvatarData centered(String which) {
    switch (which) {
      case 'hat':
        return copyWith(hatOffsetX: 0, hatOffsetY: 0, hatScale: 1);
      case 'glasses':
        return copyWith(glassesOffsetX: 0, glassesOffsetY: 0, glassesScale: 1);
      case 'mask':
        return copyWith(maskOffsetX: 0, maskOffsetY: 0, maskScale: 1);
      case 'face':
        return copyWith(faceOffsetX: 0, faceOffsetY: 0, faceScale: 1);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() => {
        'baseFace': baseFace,
        if (assetPath != null && assetPath!.isNotEmpty) 'assetPath': assetPath,
        'hat': hat,
        'glasses': glasses,
        'mask': mask,
        'bgGradientId': bgGradientId,
        'bgColorValue': bgColorValue,
        'hatOffsetX': hatOffsetX,
        'hatOffsetY': hatOffsetY,
        'hatScale': hatScale,
        'glassesOffsetX': glassesOffsetX,
        'glassesOffsetY': glassesOffsetY,
        'glassesScale': glassesScale,
        'maskOffsetX': maskOffsetX,
        'maskOffsetY': maskOffsetY,
        'maskScale': maskScale,
        'faceOffsetX': faceOffsetX,
        'faceOffsetY': faceOffsetY,
        'faceScale': faceScale,
      };

  factory AvatarData.fromJson(Map<String, dynamic> json) {
    // Migración: si existe bgGradientId lo usamos, si no inferimos de bgColorValue o default.
    String gradientId = json['bgGradientId'] as String? ?? '';
    if (gradientId.isEmpty || !AvatarOptions.bgGradients.containsKey(gradientId)) {
      final legacyColor = json['bgColorValue'] as int?;
      if (legacyColor != null) {
        gradientId = AvatarOptions.gradientIdForColorValue(legacyColor);
      } else {
        gradientId = 'sunset';
      }
    }
    // Migración baseFace: si era emoji legacy, mapea a nuevo id vectorial.
    final rawFace = json['baseFace'] as String? ?? AvatarOptions.baseFaces.first;
    final migratedFace = AvatarOptions.migrateFaceId(rawFace);
    // Migración assetPath: avatares antiguos no lo traen -> null (vectorial).
    final rawAsset = json['assetPath'] as String?;
    final assetPath = (rawAsset != null && rawAsset.isNotEmpty) ? rawAsset : null;
    return AvatarData(
      baseFace: migratedFace,
      assetPath: assetPath,
      hat: json['hat'] as String? ?? '',
      glasses: json['glasses'] as String? ?? '',
      mask: json['mask'] as String? ?? '',
      bgGradientId: gradientId,
      bgColorValue: json['bgColorValue'] as int? ?? AvatarOptions.gradientFor(gradientId).colors.first.toARGB32(),
      hatOffsetX: _parseOffset(json['hatOffsetX']),
      hatOffsetY: _parseOffset(json['hatOffsetY']),
      hatScale: _parseScale(json['hatScale']),
      glassesOffsetX: _parseOffset(json['glassesOffsetX']),
      glassesOffsetY: _parseOffset(json['glassesOffsetY']),
      glassesScale: _parseScale(json['glassesScale']),
      maskOffsetX: _parseOffset(json['maskOffsetX']),
      maskOffsetY: _parseOffset(json['maskOffsetY']),
      maskScale: _parseScale(json['maskScale']),
      faceOffsetX: _parseOffset(json['faceOffsetX']),
      faceOffsetY: _parseOffset(json['faceOffsetY']),
      faceScale: _parseScale(json['faceScale']),
    );
  }

  /// Migración desde JSON antiguo (campos faltantes -> defaults).
  static AvatarData migrate(Map<String, dynamic> json) {
    return AvatarData.fromJson(json);
  }

  String toJsonString() => jsonEncode(toJson());

  factory AvatarData.fromJsonString(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AvatarData.fromJson(map);
    } catch (_) {
      return AvatarData(baseFace: AvatarOptions.baseFaces.first);
    }
  }

  /// Helpers para convertir offsets normalizados a píxeles.
  /// La referencia es 60px = 0.5 normalizado => ±30px límite editor.
  static double offsetToPixels(double normalized, double size) {
    return normalized * 60 * (size / 110);
  }
}

/// Forma geométrica base vectorial.
enum AvatarFaceShape { round, square, cat, robot }

/// Identidad vectorial: IconData + color + forma.
class AvatarFace {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final AvatarFaceShape shape;
  const AvatarFace({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.shape,
  });
}

/// Catálogo de opciones de avatar.
class AvatarOptions {
  AvatarOptions._();

  // 12 identidades vectoriales con IconData + color + forma.
  static const List<AvatarFace> faceCatalog = [
    AvatarFace(id: 'astronaut', name: 'Astronauta', icon: Icons.rocket_launch, color: Color(0xFF42A5F5), shape: AvatarFaceShape.round),
    AvatarFace(id: 'ninja', name: 'Ninja', icon: Icons.shield, color: Color(0xFF546E7A), shape: AvatarFaceShape.square),
    AvatarFace(id: 'fox', name: 'Zorro', icon: Icons.pets, color: Color(0xFFFF8C42), shape: AvatarFaceShape.cat),
    AvatarFace(id: 'panda', name: 'Panda', icon: Icons.cruelty_free, color: Color(0xFF424242), shape: AvatarFaceShape.robot),
    AvatarFace(id: 'lion', name: 'León', icon: Icons.pets, color: Color(0xFFFFB74D), shape: AvatarFaceShape.round),
    AvatarFace(id: 'robot', name: 'Robot', icon: Icons.smart_toy, color: Color(0xFF78909C), shape: AvatarFaceShape.square),
    AvatarFace(id: 'ghost', name: 'Fantasma', icon: Icons.face, color: Color(0xFFB39DDB), shape: AvatarFaceShape.cat),
    AvatarFace(id: 'alien', name: 'Alien', icon: Icons.bug_report, color: Color(0xFF66BB6A), shape: AvatarFaceShape.robot),
    AvatarFace(id: 'wizard', name: 'Mago', icon: Icons.auto_fix_high, color: Color(0xFF7E57C2), shape: AvatarFaceShape.round),
    AvatarFace(id: 'pirate', name: 'Pirata', icon: Icons.sailing, color: Color(0xFF8D6E63), shape: AvatarFaceShape.square),
    AvatarFace(id: 'explorer', name: 'Explorador', icon: Icons.explore, color: Color(0xFF26A69A), shape: AvatarFaceShape.cat),
    AvatarFace(id: 'hero', name: 'Héroe', icon: Icons.stars, color: Color(0xFFFF7043), shape: AvatarFaceShape.robot),
    // Fallbacks dorados para los slots premium (no salen en el selector
    // vectorial: solo se usan si el PNG custom_13/14 aún no existe).
    AvatarFace(id: 'gold_hero', name: 'Héroe Dorado', icon: Icons.emoji_events, color: Color(0xFFFFD700), shape: AvatarFaceShape.round),
    AvatarFace(id: 'gold_legend', name: 'Leyenda Dorada', icon: Icons.workspace_premium, color: Color(0xFFFFB300), shape: AvatarFaceShape.square),
  ];

  static const List<String> baseFaces = [
    'astronaut',
    'ninja',
    'fox',
    'panda',
    'lion',
    'robot',
    'ghost',
    'alien',
    'wizard',
    'pirate',
    'explorer',
    'hero',
  ];

  /// 14 slots de caras por asset (fotos IA).
  /// Resuelven a `assets/avatars/<id>.png`. Si el archivo no existe,
  /// la UI hace fallback al vectorial (ver [faceFor] y `AvatarFaceView`).
  /// Los slots `custom_13`/`custom_14` son dorados premium (Pack Dorado).
  static const List<String> customFaceIds = [
    'custom_01',
    'custom_02',
    'custom_03',
    'custom_04',
    'custom_05',
    'custom_06',
    'custom_07',
    'custom_08',
    'custom_09',
    'custom_10',
    'custom_11',
    'custom_12',
    'custom_13',
    'custom_14',
  ];

  /// Nombres visibles para los 14 slots custom.
  static const Map<String, String> customFaceNames = {
    'custom_01': 'Héroe',
    'custom_02': 'Ninja',
    'custom_03': 'Zorra',
    'custom_04': 'Panda',
    'custom_05': 'León',
    'custom_06': 'Robot',
    'custom_07': 'Fantasma',
    'custom_08': 'Alien',
    'custom_09': 'Maga',
    'custom_10': 'Pirata',
    'custom_11': 'Exploradora',
    'custom_12': 'Leyenda',
    'custom_13': 'Héroe Dorado',
    'custom_14': 'Leyenda Dorada',
  };

  /// Slots dorados premium: se compran aparte (Pack Dorado).
  static const List<String> goldenFaceIds = [
    'custom_13',
    'custom_14',
  ];

  /// True si [id] es un slot de foto IA (`custom_XX`).
  static bool isCustomFaceId(String id) => customFaceIds.contains(id);

  /// True si [id] es un avatar dorado premium.
  /// Acepta tanto el slot (`custom_13`) como la ruta del asset.
  static bool isGoldenFaceId(String id) {
    if (goldenFaceIds.contains(id)) return true;
    final file = id.split('/').last;
    final slot = file.contains('.') ? file.substring(0, file.lastIndexOf('.')) : file;
    return goldenFaceIds.contains(slot);
  }

  /// True si los dorados están bloqueados (falta el Pack Dorado).
  static bool isGoldenFaceLocked(Set<String> unlockedPacks) =>
      !unlockedPacks.contains('pack_golden');

  /// Ruta del PNG para un slot custom. No verifica existencia en disco
  /// (la verificación es async vía AssetManifest o `errorBuilder` en UI).
  static String assetPathForCustomId(String id) => 'assets/avatars/$id.png';

  /// Devuelve la ruta del asset para [faceId] si es slot custom, null si no.
  static String? assetPathForFaceId(String faceId) {
    if (isCustomFaceId(faceId)) return assetPathForCustomId(faceId);
    return null;
  }

  /// Nombre visible: custom -> nombre del slot, vectorial -> nombre catálogo.
  static String faceNameFor(String id) {
    if (isCustomFaceId(id)) return customFaceNames[id] ?? id;
    return faceFor(id).name;
  }

  /// Mapeo legacy emoji -> nuevo id para migración.
  static const Map<String, String> _legacyEmojiToId = {
    '😀': 'astronaut',
    '😎': 'ninja',
    '🤩': 'fox',
    '🥳': 'panda',
    '😇': 'lion',
    '🤖': 'robot',
    '👾': 'ghost',
    '🦊': 'alien',
    '🐼': 'wizard',
    '🦁': 'pirate',
    '🐶': 'explorer',
    '👻': 'hero',
  };

  static String migrateFaceId(String raw) {
    if (baseFaces.contains(raw)) return raw;
    if (isCustomFaceId(raw)) return raw;
    if (_legacyEmojiToId.containsKey(raw)) return _legacyEmojiToId[raw]!;
    // Si raw contiene emoji o es desconocido, fallback determinista por hash
    // Detecta si parece emoji (fuera de ascii a-z)
    if (raw.isEmpty) return baseFaces.first;
    final isAsciiId = RegExp(r'^[a-z_]+$').hasMatch(raw);
    if (!isAsciiId) {
      // mapea por hash simple a uno de los 12
      final hash = raw.codeUnits.fold<int>(0, (p, c) => (p * 31 + c) % 100000);
      return baseFaces[hash % baseFaces.length];
    }
    return baseFaces.first;
  }

  static AvatarFace faceFor(String id) {
    // Slots dorados sin PNG: fallback dorado (nunca crashea).
    if (isGoldenFaceId(id)) {
      final goldId = id.contains('custom_14') ? 'gold_legend' : 'gold_hero';
      for (final f in faceCatalog) {
        if (f.id == goldId) return f;
      }
    }
    // Slots custom sin PNG: fallback vectorial determinista (nunca crashea).
    if (isCustomFaceId(id)) {
      final idx = customFaceIds.indexOf(id);
      // Los 12 primeros mapean a los 12 vectoriales base; los dorados
      // ya se resolvieron arriba.
      return faceCatalog[idx % 12];
    }
    for (final f in faceCatalog) {
      if (f.id == id) return f;
    }
    return faceCatalog[0];
  }

  // Sombreros: 16 emoji + 8 vectoriales (24 total contando vacío)
  static const List<String> hats = [
    '', // ninguno
    '🎩',
    '👑',
    '🎓',
    '🧢',
    '⛑️',
    '🎀',
    '👒',
    '🪖',
    '🎧',
    '👨‍🎤',
    '🥳',
    '🎃',
    '🎄',
    '🪶',
    '⛩️',
    '🦊',
    'icon:school',
    'icon:military_tech',
    'icon:emoji_events',
    'icon:star',
    'icon:shield',
    'icon:local_fire_department',
    'icon:diamond',
    'icon:auto_awesome',
  ];

  // Gafas: 14 emoji + 8 vectoriales (24 total)
  static const List<String> glasses = [
    '',
    '🕶️',
    '👓',
    '🥽',
    '🤓',
    '😎',
    '🥸',
    '🤩',
    '🧐',
    '😍',
    '🥺',
    '😏',
    '🤨',
    '🧑‍🎤',
    'icon:visibility',
    'icon:remove_red_eye',
    'icon:search',
    'icon:center_focus_strong',
    'icon:light_mode',
    'icon:dark_mode',
    'icon:flare',
    'icon:verified',
  ];

  // Máscaras: 12 emoji + 8 vectoriales (24 total)
  static const List<String> masks = [
    '',
    '😷',
    '🥷',
    '🤠',
    '🦸',
    '👺',
    '🎭',
    '🤡',
    '👻',
    '🤖',
    '👽',
    '🦁',
    'icon:face',
    'icon:theater_comedy',
    'icon:health_and_safety',
    'icon:sentiment_very_satisfied',
    'icon:pets',
    'icon:bug_report',
    'icon:skull',
    'icon:heart_broken',
  ];

  // Colores sólidos legacy (mantenidos para migración)
  static const List<Color> bgColors = [
    Color(0xFFFACC15),
    Color(0xFF22C55E),
    Color(0xFF46B8E8),
    Color(0xFF25E6D0),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ];

  // 14 fondos degradados
  static const Map<String, LinearGradient> bgGradients = {
    'sunset': LinearGradient(
      colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B), Color(0xFFFFD67A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'ocean': LinearGradient(
      colors: [Color(0xFF2193B0), Color(0xFF6DD5ED), Color(0xFF9BE8FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'forest': LinearGradient(
      colors: [Color(0xFF134E5E), Color(0xFF71B280), Color(0xFFA8E063)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'volcano': LinearGradient(
      colors: [Color(0xFF200122), Color(0xFF6F0000), Color(0xFFF37335)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'cyber': LinearGradient(
      colors: [Color(0xFF8A2BE2), Color(0xFF00FFFF), Color(0xFF007CF0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'candy': LinearGradient(
      colors: [Color(0xFFFF6A88), Color(0xFFFF99AC), Color(0xFFF8C3CD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'midnight': LinearGradient(
      colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'aurora': LinearGradient(
      colors: [Color(0xFF00F260), Color(0xFF0575E6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'peach': LinearGradient(
      colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'ice': LinearGradient(
      colors: [Color(0xFF8E9EAB), Color(0xFFEFF2F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'lava': LinearGradient(
      colors: [Color(0xFFFF512F), Color(0xFFF09819)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'galaxy': LinearGradient(
      colors: [Color(0xFF360033), Color(0xFF0B486B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'mint': LinearGradient(
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'dusk': LinearGradient(
      colors: [Color(0xFF2C3E50), Color(0xFFFD746C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  static const List<String> bgGradientIds = [
    'sunset',
    'ocean',
    'forest',
    'volcano',
    'cyber',
    'candy',
    'midnight',
    'aurora',
    'peach',
    'ice',
    'lava',
    'galaxy',
    'mint',
    'dusk',
  ];

  static LinearGradient gradientFor(String id) {
    return bgGradients[id] ?? bgGradients['sunset']!;
  }

  /// Mapea un color legacy al gradiente más cercano (por hash simple).
  static String gradientIdForColorValue(int colorValue) {
    final idx = colorValue % bgGradientIds.length;
    // Usar hash del color para elegir gradiente determinista
    // Normalizar índice positivo
    final safeIdx = idx.abs() % bgGradientIds.length;
    return bgGradientIds[safeIdx];
  }

  /// Los 6 primeros de cada categoría son gratis, el resto requiere compra.
  static const int freeCount = 6;

  static bool isHatLocked(int index, Set<String> unlockedPacks) {
    if (index < freeCount) return false;
    return !unlockedPacks.contains('pack_hats');
  }

  static bool isGlassesLocked(int index, Set<String> unlockedPacks) {
    if (index < freeCount) return false;
    return !unlockedPacks.contains('pack_glasses');
  }

  static bool isMaskLocked(int index, Set<String> unlockedPacks) {
    if (index < freeCount) return false;
    return !unlockedPacks.contains('pack_masks');
  }

  static bool isFaceLocked(int index, Set<String> unlockedPacks) {
    if (index < freeCount) return false;
    return !unlockedPacks.contains('pack_faces');
  }

  // Helpers vectoriales
  static bool isVector(String value) => value.startsWith('icon:');

  static IconData? iconFor(String value) {
    if (!isVector(value)) return null;
    final id = value.substring(5);
    switch (id) {
      case 'school':
        return Icons.school;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'shield':
        return Icons.shield;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'diamond':
        return Icons.diamond;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'visibility':
        return Icons.visibility;
      case 'remove_red_eye':
        return Icons.remove_red_eye;
      case 'search':
        return Icons.search;
      case 'center_focus_strong':
        return Icons.center_focus_strong;
      case 'light_mode':
        return Icons.light_mode;
      case 'dark_mode':
        return Icons.dark_mode;
      case 'flare':
        return Icons.flare;
      case 'verified':
        return Icons.verified;
      case 'face':
        return Icons.face;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      case 'pets':
        return Icons.pets;
      case 'bug_report':
        return Icons.bug_report;
      case 'skull':
        return Icons.heart_broken;
      case 'heart_broken':
        return Icons.heart_broken;
      default:
        return Icons.help_outline;
    }
  }

  static String labelFor(String value) {
    if (value.isEmpty) return '—';
    if (isVector(value)) {
      final id = value.substring(5);
      return id.replaceAll('_', ' ');
    }
    return value;
  }
}

extension _ColorExt on Color {
  int toInt32() {
    return toARGB32();
  }
}
