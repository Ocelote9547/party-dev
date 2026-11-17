import 'package:shared_preferences/shared_preferences.dart';

class PlayerStorage {
  static const _playersKey = 'party_players';

  final SharedPreferences _prefs;

  PlayerStorage(this._prefs);

  Future<List<String>> loadPlayers() async {
    final stored = _prefs.getStringList(_playersKey);
    return stored ?? [];
  }

  Future<void> savePlayers(List<String> players) async {
    await _prefs.setStringList(_playersKey, players);
  }
}