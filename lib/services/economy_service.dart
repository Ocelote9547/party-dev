import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'streak_service.dart';

class EconomyService {
  EconomyService._();
  static final EconomyService instance = EconomyService._();

  // Keys
  static const String _coinsKey = 'coins';
  static const String _playCountKey = 'play_count';
  static const String _unlockedGamesKey = 'unlocked_games';
  static const String _unlockedPacksKey = 'unlocked_packs';
  static const String _favoriteGamesKey = 'favorite_games';

  // Locks para evitar doble cobro por doble tap rápido.
  final Set<String> _pendingGamePurchases = {};
  final Set<String> _pendingPackPurchases = {};

  // ---------------------------------------------------------------------------
  // Definición de juegos
  // ---------------------------------------------------------------------------

  /// IDs canónicos (sin acentos, mayúsculas, underscores).
  static const List<String> allGameIds = [
    'ADIVINA',
    'TABU',
    'MIMICA',
    'YO_NUNCA',
    'VERDAD_O_RETO',
    'PUEBLO_DUERME',
    'IMPOSTOR',
    'ES_UN_10',
    'DEBATE',
    'QUIEN_ES_MAS',
    'QUIEN_SOY',
    'ESPIA',
    'MATAR_CASAR_BESAR',
    'SECRETOS',
    'LA_MASCARA_INFILTRADA',
    'DIBUJA_Y_ADIVINA',
    'BOMBA',
    'ALIENIGENA',
    'YO_NUNCA_LOBO',
    'DOS_PALABRAS',
    'HISTORIA_COLECTIVA',
  ];

  /// Todos gratis excepto los 5 extra (solo por compra).
  static const Set<String> initialUnlocked = {
    'ADIVINA',
    'TABU',
    'MIMICA',
    'YO_NUNCA',
    'VERDAD_O_RETO',
    'PUEBLO_DUERME',
    'IMPOSTOR',
    'ES_UN_10',
    'DEBATE',
    'QUIEN_SOY',
    'ESPIA',
    'MATAR_CASAR_BESAR',
    'DIBUJA_Y_ADIVINA',
    'YO_NUNCA_LOBO',
    'DOS_PALABRAS',
    'HISTORIA_COLECTIVA',
  };

  /// Sin desbloqueos por partidas: los 5 extra son solo por compra.
  static const Set<String> unlockAt3 = {};

  /// Sin desbloqueos por partidas.
  static const Set<String> unlockAt6 = {};

  /// Extra no esencial: solo por compra con monedas.
  static const Set<String> exclusiveGames = {
    'QUIEN_ES_MAS',
    'SECRETOS',
    'LA_MASCARA_INFILTRADA',
    'BOMBA',
    'ALIENIGENA',
  };

  /// Precio de cada extra si se quiere desbloquear con monedas.
  static const Map<String, int> gamePrices = {
    'LA_MASCARA_INFILTRADA': 120,
    'LA_MASCARA': 120, // alias
    'DIBUJA_Y_ADIVINA': 80,
    'DIBUJA': 80, // alias
    'BOMBA': 80,
    'ALIENIGENA': 100,
    'ALIEN': 100, // alias
    'QUIEN_ES_MAS': 90,
    'SECRETOS': 90,
    // fallback para el resto si se quiere comprar
    'IMPOSTOR': 60,
    'ES_UN_10': 60,
    'DEBATE': 60,
    'QUIEN_SOY': 60,
    'ESPIA': 60,
    'MATAR_CASAR_BESAR': 60,
  };

  /// Normaliza títulos a IDs: quita acentos, pasa a mayúsculas, reemplaza
  /// cualquier secuencia no alfanumérica por "_", limpia bordes.
  static String normalizeGameId(String raw) {
    String s = raw.toUpperCase().trim();
    // Reemplazar acentos comunes
    const accentMap = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
      '¿': '',
      '?': '',
      '¡': '',
      '!': '',
    };
    for (final e in accentMap.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    // Reemplazar cualquier char distinto de A-Z0-9 por _
    s = s.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'^_+|_+$'), '');
    s = s.replaceAll(RegExp(r'__+'), '_');

    // Alias para compatibilidad
    const aliases = {
      'ES_UN_10_PERO': 'ES_UN_10',
      'QUIEN_ES_EL_ESPIA': 'ESPIA',
      'LA_MASCARA': 'LA_MASCARA_INFILTRADA',
      'DIBUJA': 'DIBUJA_Y_ADIVINA',
    };
    if (aliases.containsKey(s)) return aliases[s]!;
    return s;
  }

  // ---------------------------------------------------------------------------
  // Coins
  // ---------------------------------------------------------------------------

  Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_coinsKey)) {
      await prefs.setInt(_coinsKey, 100);
      return 100;
    }
    return prefs.getInt(_coinsKey) ?? 100;
  }

  Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_coinsKey) ?? 100;
    await prefs.setInt(_coinsKey, current + amount);
  }

  /// Intenta gastar [amount] monedas. Devuelve true si tenía suficientes.
  Future<bool> spendCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_coinsKey) ?? 100;
    if (current < amount) return false;
    await prefs.setInt(_coinsKey, current - amount);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Play count
  // ---------------------------------------------------------------------------

  Future<int> getPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playCountKey) ?? 0;
  }

  Future<void> incrementPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_playCountKey) ?? 0;
    await prefs.setInt(_playCountKey, current + 1);
  }

  /// Llamar solo al completar una partida real (gameOver).
  /// Otorga +10 monedas y verifica desbloqueos automaticos.
  /// Evita duplicado: incrementPlayCount ya no otorga monedas por si solo.
  /// También registra racha diaria vía StreakService.
  Future<void> onGameCompleted() async {
    await incrementPlayCount();
    await addCoins(10);
    await checkAutoUnlocks();
    try {
      await StreakService.instance.recordPlay();
    } catch (_) {}
  }

  /// Expone recordPlay para uso directo desde UI si se necesita.
  Future<int> recordPlayForStreak() => StreakService.instance.recordPlay();

  // ---------------------------------------------------------------------------
  // Unlocked games
  // ---------------------------------------------------------------------------

  // Para probar desbloqueado: flutter run --dart-define=UNLOCK_ALL=true
  Future<Set<String>> getUnlockedGames() async {
    // Comando terminal UNLOCK_ALL: si se pasa --dart-define=UNLOCK_ALL=true, desbloquear todo
    if (const String.fromEnvironment('UNLOCK_ALL') == 'true') {
      return allGameIds.toSet();
    }
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_unlockedGamesKey)) {
      // primera vez: inicializar con los 6 gratis
      await prefs.setString(_unlockedGamesKey, jsonEncode(initialUnlocked.toList()));
      // Devolver copia mutable: initialUnlocked es const y no debe mutarse.
      return Set<String>.of(initialUnlocked);
    }
    final raw = prefs.getString(_unlockedGamesKey);
    if (raw == null || raw.isEmpty) return Set<String>.of(initialUnlocked);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return Set<String>.of(initialUnlocked);
      final list = decoded.whereType<String>().toList();
      // normalizar por si hay títulos viejos
      return list.map(normalizeGameId).toSet();
    } catch (_) {
      return Set<String>.of(initialUnlocked);
    }
  }

  Future<bool> isGameUnlocked(String gameIdOrTitle) async {
    final id = normalizeGameId(gameIdOrTitle);
    final unlocked = await getUnlockedGames();
    return unlocked.contains(id);
  }

  Future<void> unlockGame(String idOrTitle) async {
    final id = normalizeGameId(idOrTitle);
    final prefs = await SharedPreferences.getInstance();
    final unlocked = await getUnlockedGames();
    unlocked.add(id);
    await prefs.setString(_unlockedGamesKey, jsonEncode(unlocked.toList()));
  }

  /// Desbloquea automáticamente según playCount. Idempotente.
  Future<void> checkAutoUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final playCount = prefs.getInt(_playCountKey) ?? 0;
    final unlocked = await getUnlockedGames();
    bool changed = false;
    if (playCount >= 3) {
      for (final id in unlockAt3) {
        if (unlocked.add(id)) changed = true;
      }
    }
    if (playCount >= 6) {
      for (final id in unlockAt6) {
        if (unlocked.add(id)) changed = true;
      }
    }
    if (changed) {
      await prefs.setString(_unlockedGamesKey, jsonEncode(unlocked.toList()));
    }
  }

  /// Compra un juego exclusivo (o cualquier juego) por monedas.
  /// Devuelve true si la compra tuvo éxito.
  Future<bool> purchaseGame(String idOrTitle) async {
    final id = normalizeGameId(idOrTitle);
    if (_pendingGamePurchases.contains(id)) return false;
    _pendingGamePurchases.add(id);
    try {
      // si ya está desbloqueado, no cobrar
      if (await isGameUnlocked(id)) return true;
      final price = gamePrices[id] ?? 80;
      final ok = await spendCoins(price);
      if (!ok) return false;
      await unlockGame(id);
      return true;
    } finally {
      _pendingGamePurchases.remove(id);
    }
  }

  int priceForGame(String idOrTitle) {
    final id = normalizeGameId(idOrTitle);
    return gamePrices[id] ?? 80;
  }

  // ---------------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------------

  Future<Set<String>> getFavoriteGames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoriteGamesKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().map(normalizeGameId).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<bool> isFavorite(String idOrTitle) async {
    final id = normalizeGameId(idOrTitle);
    final fav = await getFavoriteGames();
    return fav.contains(id);
  }

  Future<void> setFavorite(String idOrTitle, bool favorite) async {
    final id = normalizeGameId(idOrTitle);
    final prefs = await SharedPreferences.getInstance();
    final fav = await getFavoriteGames();
    final changed = favorite ? fav.add(id) : fav.remove(id);
    if (changed) {
      await prefs.setString(_favoriteGamesKey, jsonEncode(fav.toList()));
    } else if (favorite && !fav.contains(id)) {
      // asegurar persistencia si fue primer favorito
      await prefs.setString(_favoriteGamesKey, jsonEncode(fav.toList()));
    } else if (!favorite) {
      // si ya no estaba, igual asegurar escritura para consistencia
      await prefs.setString(_favoriteGamesKey, jsonEncode(fav.toList()));
    }
  }

  Future<bool> toggleFavorite(String idOrTitle) async {
    final id = normalizeGameId(idOrTitle);
    final prefs = await SharedPreferences.getInstance();
    final fav = await getFavoriteGames();
    final wasFav = fav.contains(id);
    if (wasFav) {
      fav.remove(id);
    } else {
      fav.add(id);
    }
    await prefs.setString(_favoriteGamesKey, jsonEncode(fav.toList()));
    return !wasFav;
  }

  // ---------------------------------------------------------------------------
  // Packs cosméticos (para Avatar)
  // ---------------------------------------------------------------------------

  Future<Set<String>> getUnlockedPacks() async {
    if (const String.fromEnvironment('UNLOCK_ALL') == 'true') {
      return {
        'pack_hats',
        'pack_glasses',
        'pack_masks',
        'pack_faces',
        'pack_hats_premium',
        'pack_colors',
        'pack_golden',
      };
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_unlockedPacksKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> isPackUnlocked(String packId) async {
    final packs = await getUnlockedPacks();
    return packs.contains(packId);
  }

  Future<void> unlockPack(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    final packs = await getUnlockedPacks();
    packs.add(packId);
    await prefs.setString(_unlockedPacksKey, jsonEncode(packs.toList()));
  }

  Future<bool> purchasePack(String packId, int price) async {
    if (_pendingPackPurchases.contains(packId)) return false;
    _pendingPackPurchases.add(packId);
    try {
      if (await isPackUnlocked(packId)) return true;
      final ok = await spendCoins(price);
      if (!ok) return false;
      await unlockPack(packId);
      return true;
    } finally {
      _pendingPackPurchases.remove(packId);
    }
  }

  /// Desbloquea todos los juegos y pone 500 monedas (truco PARTY 25x).
  /// También usado por UNLOCK_ALL.
  Future<void> debugUnlockAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, 500);
    await prefs.setString(_unlockedGamesKey, jsonEncode(allGameIds));
    // Desbloquear packs conocidos
    const allPacks = [
      'pack_hats',
      'pack_glasses',
      'pack_masks',
      'pack_faces',
      'pack_hats_premium',
      'pack_colors',
      'pack_golden',
      'pack_extras',
    ];
    await prefs.setString(_unlockedPacksKey, jsonEncode(allPacks));
  }

  // Para testing / debug
  Future<void> resetEconomy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, 100);
    await prefs.setInt(_playCountKey, 0);
    await prefs.setString(_unlockedGamesKey, jsonEncode(initialUnlocked.toList()));
    await prefs.remove(_unlockedPacksKey);
  }
}
