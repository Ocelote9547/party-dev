import 'dart:math';

import '../cost_estimator.dart';
import '../intent.dart';
import '../models/models.dart';
import '../personalization.dart';
import '../photo_service.dart';
import '../services/weather_service.dart';
import '../validators/validation.dart';
import 'discovery_engine.dart';
import 'intent_engine.dart';
import 'scoring_engine.dart';
import 'validation_engine.dart';

// Generador de planes (Fase 7): filtra, puntúa y empaqueta candidatos en planes.
// Ahora con conciencia del tiempo meteorológico, horario de apertura y
// franja horaria preferida.
class PlanGenerator {
  // Genera 1-5 planes ordenados por puntuación con diversidad de tipos.
  // [excludeIds]: ids que NO deben salir (vistos/descartados/mostrados).
  // [maxDistanceKm]: tope honesto de cercanía. Lo que esté más lejos se descarta
  // si hay alternativas cerca; si no, se ignora.
  // [weather]: pronóstico para penalizar exteriores bajo lluvia.
  // [plannedStart]: hora prevista de inicio para filtrar por horario de apertura.
  static Future<List<Plan>> generate({
    required UserIntent intent,
    required DiscoveryResult discovered,
    Set<String> seenIds = const {},
    Set<String> excludeIds = const {},
    double? maxDistanceKm,
    DateTime? startTime,
    int groupSize = 2,
    Map<String, double> distancesKm = const {},
    bool useProfile = true,
    WeatherHour? weather,
    DateTime? plannedStart,
  }) async {
    // 1. Contexto temporal y de grupo.
    final now = startTime ?? DateTime.now();
    final planned = plannedStart ?? now;
    final ctx =
        ValidationContext(intent: intent, now: now, groupSize: groupSize);

    // 2. Candidatos válidos (sin distancias: falta de dato no invalida).
    final candidates = discovered.allCandidates;
    final effectiveDistances = Map<String, double>.from(distancesKm);
    if (intent.lat != null && intent.lng != null) {
      for (final c in candidates) {
        final loc = c.location;
        if (loc != null && !effectiveDistances.containsKey(c.id)) {
          effectiveDistances[c.id] =
              _haversineKm(intent.lat!, intent.lng!, loc.lat, loc.lng);
        }
      }
    }
    final valid = ValidationEngine.filter(candidates, ctx,
        distancesKm: effectiveDistances.isEmpty ? null : effectiveDistances);

    // Exclusión dura de ya vistos: rota de verdad en vez de repetir.
    var pool = valid.where((c) => !excludeIds.contains(c.id)).toList();
    if (pool.isEmpty) pool = valid;
    // Tope de cercanía: si hay alternativas cerca, lo lejano fuera.
    if (maxDistanceKm != null && maxDistanceKm.isFinite) {
      final near = pool.where((c) {
        final d = effectiveDistances[c.id];
        if (d == null) return true; // sin dato no excluye
        return d <= maxDistanceKm;
      }).toList();
      if (near.isNotEmpty) pool = near;
    }

    // 3. Pesos y puntuación (con clima, horario y franja horaria).
    final weights = IntentEngine.map(intent);
    var scored = ScoringEngine.scoreAll(pool, weights, intent,
        seenIds: seenIds,
        distancesKm: effectiveDistances,
        weather: weather,
        plannedStart: planned);

    // 3b. Personalización: multiplica por boost del perfil (opt-out).
    if (useProfile) {
      try {
        final profile = await PersonalizationEngine.load();
        scored = [
          for (final s in scored)
            ScoredCandidate(
              candidate: s.candidate,
              scores: {
                ...s.scores,
                'profileBoost':
                    PersonalizationEngine.boostFor(profile, s.candidate),
              },
              total: ((s.total *
                          PersonalizationEngine.boostFor(
                              profile, s.candidate)) *
                      100)
                  .round() /
                  100,
            ),
        ];
        scored.sort((a, b) => b.total.compareTo(a.total));
      } catch (_) {
        // Sin perfil: se conserva el scoring base.
      }
    }

    // 4. Diversidad: evita dos del mismo tipo seguidos si hay alternativa.
    final chosen = _pickDiverse(scored, 5);
    if (chosen.isEmpty) return const [];

    // 5. Empaqueta cada elegido en un Plan con costes REALES afinados.
    final reasons = IntentEngine.describe(intent).take(3).toList();
    final plans = [
      for (final s in chosen)
        _buildPlan(
          s,
          reasons,
          now,
          groupSize,
          intent: intent,
          distanceKm: effectiveDistances[s.candidate.id],
          weather: weather,
          plannedStart: planned,
        ),
    ];

    // 6. Enriquece imageUrl con foto real (Wikimedia), sin bloquear >~4s.
    final byId = {for (final s in chosen) s.candidate.id: s.candidate};
    return _enrichPhotos(plans, byId);
  }

  // Foto real por plan en paralelo con timeout global: si falla, imageUrl
  // queda null y PlanMock.fromPlan usa picsum como fallback.
  static Future<List<Plan>> _enrichPhotos(
    List<Plan> plans,
    Map<String, Candidate> byId,
  ) async {
    if (plans.isEmpty) return plans;
    const perCall = Duration(milliseconds: 2500);
    const global = Duration(seconds: 4);
    final service = PhotoService();
    try {
      final futures = [
        for (final p in plans)
          () async {
            try {
              final id = p.id.startsWith('plan_')
                  ? p.id.substring('plan_'.length)
                  : p.id;
              final c = byId[id];
              final lat = c?.location?.lat;
              final lng = c?.location?.lng;
              var query = (c?.placeName ?? c?.title ?? '').trim();
              if (query.isEmpty) {
                query = p.steps
                    .map((s) => s.location.trim())
                    .firstWhere((l) => l.isNotEmpty, orElse: () => '');
              }
              if (query.isEmpty) query = p.title;
              if (query.trim().isEmpty) return p;
              final url = await service
                  .fetchPhotoUrl(
                      query: query, lat: lat, lng: lng, timeout: perCall)
                  .timeout(perCall);
              if (url == null || url.isEmpty) return p;
              return p.copyWith(imageUrl: url);
            } catch (_) {
              return p;
            }
          }(),
      ];
      return await Future.wait(futures).timeout(global, onTimeout: () => plans);
    } catch (_) {
      return plans;
    }
  }

  // Haversine inline en km entre dos puntos.
  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(a.clamp(0.0, 1.0)));
  }

  // Recorre ordenados; difiere los del mismo tipo si queda otro distinto.
  static List<ScoredCandidate> _pickDiverse(
      List<ScoredCandidate> scored, int max) {
    if (scored.isEmpty) return const [];
    if (scored.length == 1) return [scored.single];
    final picked = <ScoredCandidate>[];
    final deferred = <ScoredCandidate>[];
    for (var i = 0; i < scored.length; i++) {
      final s = scored[i];
      if (picked.isNotEmpty && s.candidate.type == picked.last.candidate.type) {
        var hasAlt = false;
        for (var j = i + 1; j < scored.length; j++) {
          if (scored[j].candidate.type != picked.last.candidate.type) {
            hasAlt = true;
            break;
          }
        }
        if (hasAlt) {
          deferred.add(s);
          continue;
        }
      }
      picked.add(s);
      if (picked.length >= max) break;
    }
    for (final s in deferred) {
      if (picked.length >= max) break;
      picked.add(s);
    }
    return picked;
  }

  // Construye un Plan con pasos sequenciales desde [now] y costes
  // REALES por persona: actividad + transporte + comida.
  static Plan _buildPlan(
    ScoredCandidate s,
    List<String> reasons,
    DateTime now,
    int groupSize, {
    required UserIntent intent,
    double? distanceKm,
    WeatherHour? weather,
    DateTime? plannedStart,
  }) {
    final c = s.candidate;
    final g = groupSize <= 0 ? 1 : groupSize;
    final dist = (distanceKm != null && distanceKm.isFinite)
        ? distanceKm.clamp(0, 300).toDouble()
        : 5.0;

    final est = CostEstimator.breakdown(
      activityPrice: c.price,
      mode: intent.moveMode,
      distanceKm: dist,
      durationMinutes: c.durationMinutes,
      budgetMaxPerPerson: intent.budgetMaxPerPerson,
      groupSize: g,
    );
    final foodMinutes = est.food > 0 ? 45 : 0;

    final start = plannedStart ?? now;
    var cursor = start;
    final steps = <PlanStep>[];

    // Salida.
    final startEnd = cursor.add(const Duration(minutes: 15));
    steps.add(PlanStep(
      type: PlanStepType.start,
      title: 'Salida',
      startTime: cursor,
      endTime: startEnd,
      durationMinutes: 15,
      transport: _transportLabel(intent.moveMode, dist),
      cost: est.transport / 2,
    ));
    cursor = startEnd;

    // Actividad principal.
    final mainEnd = cursor.add(Duration(minutes: c.durationMinutes));
    steps.add(PlanStep(
      type: PlanStepType.activity,
      title: c.title,
      startTime: cursor,
      endTime: mainEnd,
      location: c.address,
      durationMinutes: c.durationMinutes,
      cost: est.activity,
      instructions: c.description,
    ));
    cursor = mainEnd;

    // Comida si el estimador la prevé (planes largos).
    if (est.food > 0) {
      final foodEnd = cursor.add(Duration(minutes: foodMinutes));
      steps.add(PlanStep(
        type: PlanStepType.food,
        title: 'Comida',
        startTime: cursor,
        endTime: foodEnd,
        durationMinutes: foodMinutes,
        cost: est.food,
      ));
      cursor = foodEnd;
    }

    // Regreso.
    final endEnd = cursor.add(const Duration(minutes: 15));
    steps.add(PlanStep(
      type: PlanStepType.end,
      title: 'Regreso',
      startTime: cursor,
      endTime: endEnd,
      durationMinutes: 15,
      transport: _transportLabel(intent.moveMode, dist),
      cost: est.transport / 2,
    ));
    cursor = endEnd;

    final breakdown = CostBreakdown(
      activity: est.activity * g,
      transportOutbound: (est.transport / 2) * g,
      transportReturn: (est.transport / 2) * g,
      food: est.food * g,
      groupSize: g,
    );

    final tags = c.tags.map((t) => t.toLowerCase()).toSet();
    final warnings =
        tags.contains('reserva') ? const ['Requiere reserva'] : const <String>[];

    // Añade aviso de tiempo si es adverso y el lugar es de exterior.
    final badWeather =
        weather != null && WeatherService.isBadWeather(weather.weatherCode);
    final outdoorWarning = <String>[];
    if (badWeather && c is Place && (c.isOutdoorOnly || !c.isIndoor)) {
      outdoorWarning.add('Tiempo adverso previsto: ${weather.description}');
    }
    final allWarnings = [...warnings, ...outdoorWarning];

    var totalMinutes = 0;
    for (final st in steps) {
      totalMinutes += st.durationMinutes;
    }

    final transportSummary =
        '${_transportLabel(intent.moveMode, dist)} · ${CostEstimator.label(est.total)} '
        '(${CostEstimator.detail(activity: est.activity, transport: est.transport, food: est.food)})';

    return Plan(
      id: 'plan_${c.id}',
      title: c.title,
      summary: c.description,
      score: s.total,
      startTime: start,
      endTime: cursor,
      steps: steps,
      totalDurationMinutes: totalMinutes,
      totalCost: breakdown.total,
      costPerPerson: est.total,
      difficulty: c.difficulty,
      transportSummary: transportSummary,
      returnFeasibility: ReturnFeasibility.good,
      whyRecommended: reasons,
      warnings: allWarnings,
      sources: [c.source],
      distanceKm: (distanceKm != null && distanceKm.isFinite) ? distanceKm : null,
      weatherSummary: weather != null
          ? '${weather.emoji} ${weather.description}, ${weather.temperatureC.toStringAsFixed(0)}°C, ${weather.precipitationProbability}% lluvia'
          : null,
      weatherCode: weather?.weatherCode,
      generatedAt: now,
    );
  }

  static String _transportLabel(MoveMode mode, double distKm) {
    final d = distKm <= 0
        ? 'en el sitio'
        : distKm < 1
            ? 'a ${distKm.toStringAsFixed(1)} km'
            : 'a ${distKm.toStringAsFixed(distKm < 10 ? 1 : 0)} km';
    final t = _etaLabel(mode, distKm);
    switch (mode) {
      case MoveMode.pie:
        return 'A pie $d$t';
      case MoveMode.bici:
        return 'En bici $d$t';
      case MoveMode.patinete:
        return 'En patinete $d$t';
      case MoveMode.coche:
        return 'En coche $d$t';
      case MoveMode.transporte:
        return 'En bus/metro $d$t';
      case MoveMode.indiferente:
        return 'Desplazamiento $d$t';
    }
  }

  static String _etaLabel(MoveMode mode, double distKm) {
    if (distKm <= 0.2) return '';
    final double kmh;
    switch (mode) {
      case MoveMode.pie:
        kmh = 5;
        break;
      case MoveMode.bici:
      case MoveMode.patinete:
        kmh = 15;
        break;
      case MoveMode.coche:
        kmh = 70;
        break;
      case MoveMode.transporte:
        kmh = 40;
        break;
      case MoveMode.indiferente:
        kmh = 30;
        break;
    }
    final mins = (distKm / kmh * 60).round();
    if (mins < 1) return '';
    if (mins < 60) return ' · ~$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? ' · ~$h h' : ' · ~$h h $m min';
  }
}
