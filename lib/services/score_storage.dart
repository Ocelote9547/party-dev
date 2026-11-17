import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ScoreStorage {
  final SharedPreferences _prefs;
  ScoreStorage(this._prefs);

  Map<String, int> loadScores() {
    final raw = _prefs.getString('player_scores');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, int>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is int) {
          result[key] = value;
        } else if (value is num) {
          result[key] = value.toInt();
        }
        // valores no numéricos se ignoran (dato corrupto)
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveScores(Map<String, int> scores) async {
    await _prefs.setString('player_scores', jsonEncode(scores));
  }

  Future<void> addGameScores(Map<String, int> gameScores) async {
    final all = loadScores();
    for (final entry in gameScores.entries) {
      all[entry.key] = (all[entry.key] ?? 0) + entry.value;
    }
    await saveScores(all);
  }

  Future<void> resetScores() async {
    await _prefs.remove('player_scores');
  }
}
