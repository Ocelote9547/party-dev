import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar.dart';

class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  static String _keyFor(String playerName) => 'avatar_${playerName.trim()}';

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<AvatarData?> getAvatar(String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(playerName));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AvatarData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Synchronous helper for widgets that already have prefs cached.
  /// Prefer async version when possible.
  AvatarData? getAvatarSync(SharedPreferences prefs, String playerName) {
    final raw = prefs.getString(_keyFor(playerName));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AvatarData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAvatar(String playerName, AvatarData avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(playerName), jsonEncode(avatar.toJson()));
  }

  Future<void> saveAvatarSync(SharedPreferences prefs, String playerName, AvatarData avatar) async {
    await prefs.setString(_keyFor(playerName), jsonEncode(avatar.toJson()));
  }

  Future<Map<String, AvatarData>> getAllAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, AvatarData>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('avatar_')) {
        final name = key.substring('avatar_'.length);
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          result[name] = AvatarData.fromJson(map);
        } catch (_) {}
      }
    }
    return result;
  }

  Future<void> deleteAvatar(String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(playerName));
  }

  /// Crea un avatar por defecto estable basado en el nombre (sin random para testabilidad).
  AvatarData defaultAvatarFor(String playerName) {
    final faces = AvatarOptions.baseFaces;
    int hash = 0;
    for (final c in playerName.codeUnits) {
      hash = (hash * 31 + c) % 100000;
    }
    final face = faces[hash % faces.length];
    final gradientId = AvatarOptions.bgGradientIds[hash % AvatarOptions.bgGradientIds.length];
    final gradient = AvatarOptions.gradientFor(gradientId);
    return AvatarData(
      baseFace: face,
      bgGradientId: gradientId,
      bgColorValue: gradient.colors.first.toARGB32(),
    );
  }

  Future<AvatarData> getOrCreateAvatar(String playerName) async {
    final existing = await getAvatar(playerName);
    if (existing != null) return existing;
    final def = defaultAvatarFor(playerName);
    await saveAvatar(playerName, def);
    return def;
  }
}
