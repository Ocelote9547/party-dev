import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/models.dart';

// Perfil de preferencias del usuario (FASE 11).
// Guarda afinidad por tag (0..1) e historiales de ids.
class UserPreferenceProfile {
  // Afinidad por tag: 0 = evita, 1 = le encanta.
  final Map<String, double> tagAffinity;
  final List<String> seenIds;
  final List<String> likedIds;
  final List<String> dislikedIds;
  final List<String> completedIds;

  const UserPreferenceProfile({
    this.tagAffinity = const {},
    this.seenIds = const [],
    this.likedIds = const [],
    this.dislikedIds = const [],
    this.completedIds = const [],
  });

  // Crea una copia con los campos indicados sustituidos.
  UserPreferenceProfile copyWith({
    Map<String, double>? tagAffinity,
    List<String>? seenIds,
    List<String>? likedIds,
    List<String>? dislikedIds,
    List<String>? completedIds,
  }) {
    return UserPreferenceProfile(
      tagAffinity: tagAffinity ?? this.tagAffinity,
      seenIds: seenIds ?? this.seenIds,
      likedIds: likedIds ?? this.likedIds,
      dislikedIds: dislikedIds ?? this.dislikedIds,
      completedIds: completedIds ?? this.completedIds,
    );
  }

  // Serializa a mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'tagAffinity': tagAffinity,
      'seenIds': seenIds,
      'likedIds': likedIds,
      'dislikedIds': dislikedIds,
      'completedIds': completedIds,
    };
  }

  // Reconstruye desde un mapa JSON (tolera valores numéricos).
  factory UserPreferenceProfile.fromJson(Map<String, dynamic> json) {
    final rawAffinity = json['tagAffinity'];
    final affinity = <String, double>{};
    if (rawAffinity is Map) {
      for (final entry in rawAffinity.entries) {
        final value = entry.value;
        if (value is num) {
          affinity[entry.key.toString()] = value.toDouble().clamp(0.0, 1.0);
        }
      }
    }
    return UserPreferenceProfile(
      tagAffinity: affinity,
      seenIds: _stringList(json['seenIds']),
      likedIds: _stringList(json['likedIds']),
      dislikedIds: _stringList(json['dislikedIds']),
      completedIds: _stringList(json['completedIds']),
    );
  }

  // Convierte un valor JSON en lista de strings (vacía si no válido).
  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

// Motor de personalización: persiste y aplica el perfil (FASE 11).
class PersonalizationEngine {
  // Clave usada en SharedPreferences.
  static const _key = 'user_preference_profile';

  // Carga el perfil guardado o uno vacío si no existe o es inválido.
  static Future<UserPreferenceProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const UserPreferenceProfile();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserPreferenceProfile.fromJson(decoded);
    } catch (_) {
      // JSON corrupto: se reinicia a perfil vacío.
      return const UserPreferenceProfile();
    }
  }

  // Guarda el perfil completo en SharedPreferences.
  static Future<void> save(UserPreferenceProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }

  // Aprende: liked +0.1, disliked -0.1 (clamp 0..1); registra seen.
  static UserPreferenceProfile learn(
    UserPreferenceProfile p, {
    List<String> likedTags = const [],
    List<String> dislikedTags = const [],
    List<String> seenIds = const [],
  }) {
    final affinity = Map<String, double>.from(p.tagAffinity);
    // Sube afinidad de tags gustados (base 0.5 si son nuevos).
    for (final tag in likedTags) {
      final current = affinity[tag] ?? 0.5;
      affinity[tag] = (current + 0.1).clamp(0.0, 1.0).toDouble();
    }
    // Baja afinidad de tags rechazados (base 0.5 si son nuevos).
    for (final tag in dislikedTags) {
      final current = affinity[tag] ?? 0.5;
      affinity[tag] = (current - 0.1).clamp(0.0, 1.0).toDouble();
    }
    // Acumula vistos sin duplicados, manteniendo el orden.
    final seen = <String>[...p.seenIds];
    for (final id in seenIds) {
      if (!seen.contains(id)) seen.add(id);
    }
    return p.copyWith(tagAffinity: affinity, seenIds: seen);
  }

  // Multiplicador 0.8..1.2 según afinidad media de los tags del candidato.
  static double boostFor(UserPreferenceProfile p, Candidate c) {
    if (c.tags.isEmpty) return 1.0;
    var sum = 0.0;
    for (final tag in c.tags) {
      sum += p.tagAffinity[tag] ?? 0.5;
    }
    final avg = sum / c.tags.length;
    return (0.8 + avg * 0.4).clamp(0.8, 1.2).toDouble();
  }

  // Añade un plan a completedIds (load+save, sin duplicados).
  static Future<void> recordCompleted(String planId) async {
    final current = await load();
    if (current.completedIds.contains(planId)) return;
    await save(
      current.copyWith(completedIds: [...current.completedIds, planId]),
    );
  }
}
