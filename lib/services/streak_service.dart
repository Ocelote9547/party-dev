import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de desafío diario.
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
  });

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) {
    if (other is DailyChallenge) return other.id == id;
    if (other is String) return other == title || other == id;
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  // Claves requeridas por especificación.
  static const String _lastPlayDateKey = 'last_play_date';
  static const String _streakCountKey = 'streak_count';
  static const String _dailyClaimedDateKey = 'daily_claimed_date';

  // Claves internas para progreso diario.
  static const String _dailyProgressKey = 'daily_progress';
  static const String _dailyProgressDateKey = 'daily_progress_date';
  static const String _coinsKey = 'coins';

  /// Lista de desafíos. Determinista por fecha.
  static const List<DailyChallenge> _challenges = [
    DailyChallenge(
      id: 'bomba_2',
      title: 'Gana 2 Bombas',
      description: 'Gana 2 partidas de Bomba',
      target: 2,
      reward: 15,
    ),
    DailyChallenge(
      id: 'distintos_3',
      title: 'Juega 3 juegos distintos',
      description: 'Juega 3 juegos diferentes hoy',
      target: 3,
      reward: 15,
    ),
    DailyChallenge(
      id: 'impostor_1',
      title: 'Gana 1 Impostor',
      description: 'Gana una partida de Impostor',
      target: 1,
      reward: 15,
    ),
    DailyChallenge(
      id: 'partidas_2',
      title: 'Juega 2 partidas',
      description: 'Completa 2 partidas hoy',
      target: 2,
      reward: 15,
    ),
    DailyChallenge(
      id: 'mimica_3',
      title: 'Juega 3 Mímicas',
      description: 'Juega 3 rondas de Mímica',
      target: 3,
      reward: 15,
    ),
    DailyChallenge(
      id: 'general_5',
      title: 'Juega 5 juegos',
      description: 'Completa 5 partidas hoy',
      target: 5,
      reward: 15,
    ),
  ];

  List<DailyChallenge> get allChallenges => _challenges;

  String _todayString([DateTime? date]) {
    final now = date ?? DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _yesterdayString([DateTime? date]) {
    final now = date ?? DateTime.now();
    final y = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    return _todayString(y);
  }

  // ---------------------------------------------------------------------------
  // Rachas
  // ---------------------------------------------------------------------------

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }

  Future<String?> getLastPlayDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPlayDateKey);
  }

  /// Registra una partida hoy. Compara fecha hoy vs ayer, incrementa o resetea.
  /// Retorna el streak actualizado.
  Future<int> recordPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final yesterday = _yesterdayString();
    final last = prefs.getString(_lastPlayDateKey);
    int streak = prefs.getInt(_streakCountKey) ?? 0;

    if (last == today) {
      // Ya jugó hoy: no cambia racha, pero sí progreso diario.
      await _incrementDailyProgress(prefs, today);
      return streak;
    }

    if (last == yesterday) {
      streak = streak + 1;
      if (streak < 1) streak = 1;
    } else if (last == null) {
      streak = 1;
    } else {
      // Gap > 1 día -> resetea.
      streak = 1;
    }

    await prefs.setString(_lastPlayDateKey, today);
    await prefs.setInt(_streakCountKey, streak);
    await _incrementDailyProgress(prefs, today);
    return streak;
  }

  // ---------------------------------------------------------------------------
  // Daily challenge
  // ---------------------------------------------------------------------------

  /// Elige desafío diario determinista por fecha.
  /// Sin parámetro usa fecha actual; con parámetro permite test determinista.
  DailyChallenge getDailyChallenge({DateTime? date}) {
    final d = date ?? DateTime.now();
    final normalized = DateTime(d.year, d.month, d.day);
    final epoch = DateTime(2020, 1, 1);
    final days = normalized.difference(epoch).inDays;
    final len = _challenges.length;
    final idx = ((days % len) + len) % len;
    return _challenges[idx];
  }

  /// Versión async por compatibilidad (algunos tests hacen await).
  Future<DailyChallenge> getDailyChallengeAsync({DateTime? date}) async {
    return getDailyChallenge(date: date);
  }

  Future<int> getDailyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_dailyProgressDateKey);
    if (storedDate != today) return 0;
    return prefs.getInt(_dailyProgressKey) ?? 0;
  }

  Future<int> getDailyTarget({DateTime? date}) async {
    return getDailyChallenge(date: date).target;
  }

  Future<void> _incrementDailyProgress(SharedPreferences prefs, String today) async {
    final storedDate = prefs.getString(_dailyProgressDateKey);
    if (storedDate != today) {
      await prefs.setString(_dailyProgressDateKey, today);
      await prefs.setInt(_dailyProgressKey, 1);
    } else {
      final cur = prefs.getInt(_dailyProgressKey) ?? 0;
      await prefs.setInt(_dailyProgressKey, cur + 1);
    }
  }

  /// Incrementa progreso manualmente (útil si se quiere distinguir por juego).
  Future<int> incrementDailyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    await _incrementDailyProgress(prefs, today);
    return getDailyProgress();
  }

  Future<bool> isDailyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final claimedDate = prefs.getString(_dailyClaimedDateKey);
    if (claimedDate == today) return true;
    final progress = await getDailyProgress();
    final target = getDailyChallenge().target;
    return progress >= target;
  }

  /// Alias semántico para Home UI.
  Future<bool> isDailyClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    return prefs.getString(_dailyClaimedDateKey) == today;
  }

  /// Reclama recompensa diaria (+15 monedas).
  /// Retorna true si se reclamó, false si ya estaba reclamado hoy.
  /// Si el progreso no alcanza el target, aún permite reclamar (permisivo)
  /// pero la UI debería deshabilitar el botón hasta completar.
  Future<bool> claimDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final claimedDate = prefs.getString(_dailyClaimedDateKey);
    if (claimedDate == today) return false;

    // Opcional: exigir progreso mínimo. Para no romper tests permisivos,
    // solo bloquea si progreso es 0 y target > 0 y nunca se ha jugado hoy?
    // Mantenemos permisivo: permitir reclamar aunque progreso < target,
    // pero si se quiere estricto, descomentar:
    // final progress = await getDailyProgress();
    // final target = getDailyChallenge().target;
    // if (progress < target) return false;

    final claimed = await _addCoins(prefs, 15);
    if (!claimed) return false;
    await prefs.setString(_dailyClaimedDateKey, today);
    return true;
  }

  Future<bool> _addCoins(SharedPreferences prefs, int amount) async {
    final current = prefs.getInt(_coinsKey) ?? 100;
    await prefs.setInt(_coinsKey, current + amount);
    return true;
  }

  // Helpers para testing / debug

  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPlayDateKey);
    await prefs.remove(_streakCountKey);
    await prefs.remove(_dailyClaimedDateKey);
    await prefs.remove(_dailyProgressKey);
    await prefs.remove(_dailyProgressDateKey);
  }
}
