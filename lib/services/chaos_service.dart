import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'economy_service.dart';

/// Item de la cola de Modo Caos.
class ChaosQueueItem {
  final String id;
  final String title;
  final String emoji;
  final String category;
  final String mode;
  final int durationSeconds;

  const ChaosQueueItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.category,
    required this.mode,
    required this.durationSeconds,
  });

  String get durationLabel {
    if (durationSeconds < 60) return '${durationSeconds}s';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (s == 0) return '$m min';
    return '${m}m ${s}s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'category': category,
        'mode': mode,
        'duration': durationSeconds,
      };

  factory ChaosQueueItem.fromJson(Map<String, dynamic> json) {
    return ChaosQueueItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🎮',
      category: json['category'] as String? ?? 'GRUPO',
      mode: json['mode'] as String? ?? 'Clásico',
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 90,
    );
  }
}

/// Servicio que genera y persiste la cola de 5 juegos del Modo Caos.
class ChaosService {
  ChaosService._();
  static final ChaosService instance = ChaosService._();

  static const String queueKey = 'chaos_queue';

  static const List<String> modes = [
    'Clásico',
    'Rápido',
    'Extremo',
    'Fiesta',
  ];

  static const List<int> durations = [60, 90, 120, 180, 240];

  final Random _random = Random();

  /// Catálogo completo (títulos canónicos usados en games_screen).
  /// id normalizado -> metadatos.
  static const Map<String, Map<String, String>> catalog = {
    'IMPOSTOR': {'title': 'IMPOSTOR', 'emoji': '🕵️', 'category': 'MENTIRA'},
    'PUEBLO_DUERME': {'title': 'PUEBLO DUERME', 'emoji': '🌙', 'category': 'GRUPO'},
    'ADIVINA': {'title': 'ADIVINA', 'emoji': '🧠', 'category': 'PALABRAS'},
    'ES_UN_10': {'title': 'ES UN 10 PERO...', 'emoji': '🔟', 'category': 'RETO'},
    'DEBATE': {'title': 'DEBATE', 'emoji': '💬', 'category': 'OPINIÓN'},
    'QUIEN_ES_MAS': {'title': 'QUIÉN ES MÁS', 'emoji': '👀', 'category': 'GRUPO'},
    'TABU': {'title': 'TABÚ', 'emoji': '🚫', 'category': 'PALABRAS'},
    'YO_NUNCA': {'title': 'YO NUNCA', 'emoji': '🤫', 'category': 'GRUPO'},
    'MIMICA': {'title': 'MÍMICA', 'emoji': '🎭', 'category': 'RETO'},
    'QUIEN_SOY': {'title': '¿QUIÉN SOY?', 'emoji': '🎭', 'category': 'GRUPO'},
    'ESPIA': {'title': '¿QUIÉN ES EL ESPIA?', 'emoji': '🕵️', 'category': 'MENTIRA'},
    'VERDAD_O_RETO': {'title': 'VERDAD O RETO', 'emoji': '🎲', 'category': 'RETO'},
    'MATAR_CASAR_BESAR': {'title': 'MATAR, CASAR, BESAR', 'emoji': '💋', 'category': 'GRUPO'},
    'SECRETOS': {'title': 'SECRETOS', 'emoji': '🕵️', 'category': 'MENTIRA'},
    'LA_MASCARA_INFILTRADA': {'title': 'LA MÁSCARA INFILTRADA', 'emoji': '🎭', 'category': 'MENTIRA'},
    'DIBUJA_Y_ADIVINA': {'title': 'DIBUJA Y ADIVINA', 'emoji': '🎨', 'category': 'PALABRAS'},
    'BOMBA': {'title': 'BOMBA', 'emoji': '💣', 'category': 'PALABRAS'},
    'LA_ENSALADA': {'title': 'LA ENSALADA', 'emoji': '🥗', 'category': 'PALABRAS'},
    'ALIENIGENA': {'title': 'ALIENÍGENA', 'emoji': '👽', 'category': 'MENTIRA'},
    'YO_TENGO_UN_AMIGO': {'title': 'YO TENGO UN AMIGO', 'emoji': '👥', 'category': 'GRUPO'},
    'YO_NUNCA_EQUIPOS': {'title': 'YO NUNCA EQUIPOS', 'emoji': '🤫', 'category': 'GRUPO'},
    'APT_COREANO': {'title': 'APT COREANO', 'emoji': '🖐️', 'category': 'RETO'},
    'YO_NUNCA_LOBO': {'title': 'YO NUNCA LOBO', 'emoji': '🐺', 'category': 'GRUPO'},
    'ANGELES_Y_DEMONIOS': {'title': 'ANGELES Y DEMONIOS', 'emoji': '👼', 'category': 'MENTIRA'},
  };

  String _randomMode() => modes[_random.nextInt(modes.length)];

  int _randomDuration() => durations[_random.nextInt(durations.length)];

  ChaosQueueItem _buildItem(String normalizedId) {
    final meta = catalog[normalizedId];
    final title = meta?['title'] ?? normalizedId;
    final emoji = meta?['emoji'] ?? '🎮';
    final category = meta?['category'] ?? 'GRUPO';
    return ChaosQueueItem(
      id: normalizedId,
      title: title,
      emoji: emoji,
      category: category,
      mode: _randomMode(),
      durationSeconds: _randomDuration(),
    );
  }

  /// Genera una cola aleatoria de 5 juegos de los desbloqueados,
  /// sin repetir juego seguido. Guarda en SharedPreferences `chaos_queue`.
  Future<List<ChaosQueueItem>> generateQueue({int count = 5}) async {
    final unlocked = await EconomyService.instance.getUnlockedGames();
    // Filtrar solo ids que están en catálogo.
    List<String> candidates = unlocked.where((id) => catalog.containsKey(id)).toList();

    // Fallback: si por alguna razón no hay candidatos (ej. prefs corruptas),
    // usar todos los desbloqueados iniciales o todo el catálogo.
    if (candidates.isEmpty) {
      final initial = EconomyService.initialUnlocked.where((id) => catalog.containsKey(id)).toList();
      if (initial.isNotEmpty) {
        candidates = initial;
      } else {
        candidates = catalog.keys.toList();
      }
    }

    // Si solo hay 1 juego desbloqueado, no podemos evitar repetición,
    // pero intentamos no repetir seguido (si count>1, alternar imposible).
    final result = <ChaosQueueItem>[];
    String? lastId;
    for (int i = 0; i < count; i++) {
      String picked;
      if (candidates.length == 1) {
        picked = candidates.first;
      } else {
        // Intentar hasta 20 veces evitar repetir el anterior.
        int attempts = 0;
        do {
          picked = candidates[_random.nextInt(candidates.length)];
          attempts++;
        } while (picked == lastId && attempts < 20);
      }
      result.add(_buildItem(picked));
      lastId = picked;
    }

    await saveQueue(result);
    return result;
  }

  Future<void> saveQueue(List<ChaosQueueItem> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(queueKey, json);
  }

  Future<List<ChaosQueueItem>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => ChaosQueueItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(queueKey);
  }

  Future<bool> hasQueue() async {
    final q = await loadQueue();
    return q.isNotEmpty;
  }
}
