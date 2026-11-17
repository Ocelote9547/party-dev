import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AngelesService {
  AngelesService._();
  static final AngelesService instance = AngelesService._();

  static const String _key = 'angeles_assignment';

  Future<void> saveAssignment(
      Map<String, ({String angel, String demon})> assignment) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, Map<String, String>> encodable = {
      for (final e in assignment.entries)
        e.key: {'angel': e.value.angel, 'demon': e.value.demon},
    };
    await prefs.setString(_key, jsonEncode(encodable));
  }

  Future<Map<String, ({String angel, String demon})>?> getAssignment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, ({String angel, String demon})>{};
      for (final entry in decoded.entries) {
        final v = entry.value;
        if (v is Map) {
          final angel = v['angel']?.toString() ?? '';
          final demon = v['demon']?.toString() ?? '';
          if (angel.isNotEmpty && demon.isNotEmpty) {
            result[entry.key] = (angel: angel, demon: demon);
          }
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
