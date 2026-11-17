import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan.dart';

/// Persistencia local de planes guardados ("Mis Planes").
///
/// Guarda cada plan como JSON en SharedPreferences con una clave única.
/// Nunca lanza.
class SavedPlansService {
  SavedPlansService({this._prefs});

  SharedPreferences? _prefs;

  static const _key = 'plans_saved_plans';
  static const _maxSaved = 50;

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Guarda un plan (sobrescribe si ya existe mismo id).
  Future<void> savePlan(Plan plan) async {
    try {
      final prefs = await _getPrefs();
      final existing = await getSavedPlans();
      // Elimina si ya existe (actualización).
      existing.removeWhere((p) => p.id == plan.id);
      existing.insert(0, plan); // más reciente primero.
      if (existing.length > _maxSaved) {
        existing.removeRange(_maxSaved, existing.length);
      }
      final list = existing.map((p) => jsonEncode(_planToJson(p))).toList();
      await prefs.setStringList(_key, list);
    } catch (_) {}
  }

  /// Devuelve todos los planes guardados, más recientes primero.
  Future<List<Plan>> getSavedPlans() async {
    try {
      final prefs = await _getPrefs();
      final list = prefs.getStringList(_key) ?? <String>[];
      final plans = <Plan>[];
      for (final entry in list) {
        try {
          final decoded = jsonDecode(entry) as Map<String, dynamic>;
          plans.add(_planFromJson(decoded));
        } catch (_) {
          continue;
        }
      }
      return plans;
    } catch (_) {
      return const [];
    }
  }

  /// Elimina un plan guardado por id.
  Future<void> deletePlan(String id) async {
    try {
      final prefs = await _getPrefs();
      final existing = await getSavedPlans();
      existing.removeWhere((p) => p.id == id);
      final list = existing.map((p) => jsonEncode(_planToJson(p))).toList();
      await prefs.setStringList(_key, list);
    } catch (_) {}
  }

  /// Borra todos los planes guardados.
  Future<void> clearAll() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_key);
    } catch (_) {}
  }

  // ----- Serialización -----

  Map<String, dynamic> _planToJson(Plan p) {
    return {
      'id': p.id,
      'title': p.title,
      'summary': p.summary,
      'score': p.score,
      'startTime': p.startTime?.toIso8601String(),
      'endTime': p.endTime?.toIso8601String(),
      'totalDurationMinutes': p.totalDurationMinutes,
      'totalCost': p.totalCost,
      'costPerPerson': p.costPerPerson,
      'difficulty': p.difficulty,
      'transportSummary': p.transportSummary,
      'returnFeasibility': p.returnFeasibility.index,
      'whyRecommended': p.whyRecommended,
      'warnings': p.warnings,
      'sources': p.sources,
      'imageUrl': p.imageUrl,
      'distanceKm': p.distanceKm,
      'savedAt': DateTime.now().toIso8601String(),
      'steps': p.steps.map((s) => {
        'type': s.type.index,
        'title': s.title,
        'startTime': s.startTime?.toIso8601String(),
        'endTime': s.endTime?.toIso8601String(),
        'location': s.location,
        'durationMinutes': s.durationMinutes,
        'cost': s.cost,
        'transport': s.transport,
        'instructions': s.instructions,
      }).toList(),
    };
  }

  Plan _planFromJson(Map<String, dynamic> j) {
    final steps = <PlanStep>[];
    final stepsRaw = j['steps'];
    if (stepsRaw is List) {
      for (final s in stepsRaw) {
        if (s is! Map) continue;
        steps.add(PlanStep(
          type: PlanStepType.values[s['type'] as int? ?? 0],
          title: '${s['title'] ?? ''}',
          startTime: s['startTime'] != null
              ? DateTime.tryParse('${s['startTime']}')
              : null,
          endTime: s['endTime'] != null
              ? DateTime.tryParse('${s['endTime']}')
              : null,
          location: '${s['location'] ?? ''}',
          durationMinutes: (s['durationMinutes'] as num?)?.toInt() ?? 0,
          cost: (s['cost'] as num?)?.toDouble() ?? 0,
          transport: '${s['transport'] ?? ''}',
          instructions: '${s['instructions'] ?? ''}',
        ));
      }
    }
    return Plan(
      id: '${j['id'] ?? ''}',
      title: '${j['title'] ?? 'Plan'}',
      summary: '${j['summary'] ?? ''}',
      score: (j['score'] as num?)?.toDouble() ?? 0,
      startTime: j['startTime'] != null
          ? DateTime.tryParse('${j['startTime']}')
          : null,
      endTime: j['endTime'] != null
          ? DateTime.tryParse('${j['endTime']}')
          : null,
      steps: steps,
      totalDurationMinutes:
          (j['totalDurationMinutes'] as num?)?.toInt() ?? 0,
      totalCost: (j['totalCost'] as num?)?.toDouble() ?? 0,
      costPerPerson: (j['costPerPerson'] as num?)?.toDouble() ?? 0,
      difficulty: '${j['difficulty'] ?? 'facil'}',
      transportSummary: '${j['transportSummary'] ?? ''}',
      returnFeasibility: ReturnFeasibility.values[
          (j['returnFeasibility'] as int?)?.clamp(0, 3) ?? 0],
      whyRecommended: (j['whyRecommended'] as List?)
          ?.whereType<String>()
          .toList() ??
          const [],
      warnings: (j['warnings'] as List?)?.whereType<String>().toList() ??
          const [],
      sources: (j['sources'] as List?)?.whereType<String>().toList() ??
          const [],
      imageUrl: j['imageUrl'] as String?,
      distanceKm: (j['distanceKm'] as num?)?.toDouble(),
    );
  }
}
