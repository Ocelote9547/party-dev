import '../intent.dart';
import '../models/models.dart';
import '../services/weather_service.dart';
import 'intent_engine.dart';

/// Candidato con desglose de puntuación por dimensión.
class ScoredCandidate {
  final Candidate candidate;
  final Map<String, double> scores; // por dimensión
  final double total;
  const ScoredCandidate({
    required this.candidate,
    required this.scores,
    required this.total,
  });
}

/// ScoringEngine (Fase 6): puntúa candidatos con funciones puras por dimensión.
class ScoringEngine {
  // Mapa tag (minúsculas) -> nombre de peso en IntentWeights.
  static const Map<String, String> tagToWeight = {
    'naturaleza': 'nature',
    'nature': 'nature',
    'senderismo': 'nature',
    'mirador': 'nature',
    'parque': 'nature',
    'aventura': 'adventure',
    'adventure': 'adventure',
    'ruta': 'adventure',
    'museo': 'culture',
    'monumento': 'culture',
    'cine': 'culture',
    'teatro': 'culture',
    'cultura': 'culture',
    'culture': 'culture',
    'gastronomia': 'food',
    'gastronomía': 'food',
    'food': 'food',
    'fiesta': 'entertainment',
    'entertainment': 'entertainment',
    'eventos': 'entertainment',
    'feria': 'entertainment',
    'deporte': 'sport',
    'sport': 'sport',
    'relax': 'relax',
    'social': 'social',
  };

  /// `intentFit`: +2 si algún tag mapea al top-3 de pesos.
  static double intentFit(Candidate c, IntentWeights weights) {
    final top3 = weights.top(3).toSet();
    for (final raw in c.tags) {
      final tag = raw.toLowerCase().trim();
      final w = tagToWeight[tag];
      if (w != null && top3.contains(w)) return 2;
    }
    return 0;
  }

  /// `groupFit`: ajuste al grupo según `withWhom` y tags.
  static double groupFit(Candidate c, UserIntent intent) {
    final tags = c.tags.map((t) => t.toLowerCase()).toSet();
    switch (intent.withWhom) {
      case WithWhom.amigos:
        if (tags.contains('social') || tags.contains('fiesta')) return 1;
        return 0;
      case WithWhom.familia:
        if (tags.contains('relax') ||
            tags.contains('cultura') ||
            tags.contains('culture')) {
          return 1;
        }
        return 0;
      case WithWhom.pareja:
        if (tags.contains('especial') ||
            tags.contains('romantico') ||
            tags.contains('romántico')) {
          return 0.5;
        }
        return 0;
      case WithWhom.solo:
        if (tags.contains('tranquilo') || tags.contains('relax')) return 0.5;
        return 0;
    }
  }

  /// `timeFit`: +2 si cabe en el slot, +1 si se pasa <=25%, 0 si no.
  static double timeFit(Candidate c, UserIntent intent) {
    final max = intent.timeSlot.maxMinutes;
    if (c.durationMinutes <= max) return 2;
    if (c.durationMinutes <= max * 1.25) return 1;
    return 0;
  }

  /// `budgetFit`: +2 si gratis; +1 si <=50% del tope; +0.5 si entra justo.
  static double budgetFit(Candidate c, UserIntent intent) {
    final cost = c.price;
    if (cost == 0) return 2;
    final max = intent.budgetMaxPerPerson;
    if (cost <= max * 0.5) return 1;
    if (cost <= max) return 0.5;
    return 0;
  }

  /// `locationFit`: +2 si <=5km, +1 si <=15km, 0 si más; +0.5 sin dato.
  static double locationFit(Candidate c, {double? distanceKm}) {
    if (distanceKm == null) return 0.5;
    if (distanceKm <= 5) return 2;
    if (distanceKm <= 15) return 1;
    return 0;
  }

  /// `qualityScore`: rating/5*1.5 + bonus por reseñas + confianza.
  static double qualityScore(Candidate c) {
    return c.rating / 5 * 1.5 +
        (c.reviewCount > 50 ? 0.5 : 0) +
        c.confidence * 1.0;
  }

  /// `noveltyScore`: +2 si nuevo y no visto; -1.5 si visto; 0 resto.
  static double noveltyScore(
    Candidate c,
    IntentWeights weights, {
    Set<String> seenIds = const {},
  }) {
    final tags = c.tags.map((t) => t.toLowerCase()).toSet();
    double base = 0;
    if (seenIds.contains(c.id)) {
      base = -1.5;
    } else if (tags.contains('nuevo') || tags.contains('diferente')) {
      base = 2;
    }
    return base * (1 + weights.novelty / 4);
  }

  /// `weatherFit`: +2 si interior o tiempo apto para exterior;
  /// -2 si solo-exterior y tiempo adverso; +1 si interior y llueve (bonus).
  static double weatherFit(Candidate c, WeatherHour? weather) {
    if (weather == null) return 0.5; // sin dato: neutro
    final isPlace = c is Place;
    final isIndoor = isPlace ? c.isIndoor : false;
    final isOutdoorOnly = isPlace ? c.isOutdoorOnly : false;

    final bad = WeatherService.isBadWeather(weather.weatherCode);
    if (isOutdoorOnly && bad) return -2; // mirador/laguna bajo tormenta: fuera
    if (isIndoor && bad) return 1; // museo/cine bajo lluvia: bonus
    if (!isIndoor && !isOutdoorOnly && bad) return 0; // mixto bajo lluvia: neutro
    return 0.5; // tiempo bueno: neutro-leve
  }

  /// `openingHoursFit`: +1 si abierto en la hora prevista, -1 si cerrado.
  /// Si no hay datos de horario, neutro (0).
  static double openingHoursFit(Candidate c, DateTime? plannedStart) {
    if (plannedStart == null) return 0;
    final isPlace = c is Place;
    if (!isPlace || c.openingHours == null || c.openingHours!.isEmpty) return 0;
    // Parsing simplificado: "10:00-22:00" -> abre a las 10, cierra a las 22.
    final oh = c.openingHours!;
    final parts = oh.split('-');
    if (parts.length != 2) return 0;
    final open = _parseTime(parts[0].trim());
    final close = _parseTime(parts[1].trim());
    if (open == null || close == null) return 0;
    final hour = plannedStart.hour;
    final plannedMinutes = hour * 60 + plannedStart.minute;
    if (plannedMinutes >= open * 60 && plannedMinutes <= close * 60) return 1;
    return -1; // cerrado en esa hora
  }

  static int? _parseTime(String t) {
    try {
      final hp = t.split(':');
      if (hp.length < 2) return null;
      return int.parse(hp[0]);
    } catch (_) {
      return null;
    }
  }

  /// `timeOfDayFit`: +1 si la franja coincide con la preferida.
  static double timeOfDayFit(Candidate c, UserIntent intent, DateTime? start) {
    if (start == null || intent.timeOfDay == TimeOfDayPreference.indiferente) {
      return 0;
    }
    final hour = start.hour;
    final pref = intent.timeOfDay;
    final inRange = hour >= pref.startHour && hour < pref.endHour;
    return inRange ? 1 : -0.5;
  }

  /// `frictionScore`: penalización positiva que SE RESTA del total.
  static double frictionScore(Candidate c, {double? distanceKm}) {
    var f = 0.0;
    final tags = c.tags.map((t) => t.toLowerCase()).toSet();
    if (tags.contains('reserva')) f += 1;
    if (c.difficulty.toLowerCase() == 'alta') f += 1;
    if (distanceKm != null && distanceKm > 20) f += 0.5;
    return f;
  }

  /// Puntúa candidatos. Funciones puras por dimensión, testeables por separado.
  ///
  /// [weather]: pronóstico para penalizar exteriores bajo lluvia.
  /// [plannedStart]: hora prevista de inicio para filtrar por horario de apertura.
  static List<ScoredCandidate> scoreAll(
    List<Candidate> candidates,
    IntentWeights weights,
    UserIntent intent, {
    Set<String> seenIds = const {},
    Map<String, double> distancesKm = const {},
    WeatherHour? weather,
    DateTime? plannedStart,
  }) {
    final out = <ScoredCandidate>[];
    for (final c in candidates) {
      final dist = distancesKm[c.id];
      final iFit = intentFit(c, weights);
      final gFit = groupFit(c, intent);
      final tFit = timeFit(c, intent);
      final bFit = budgetFit(c, intent);
      final lFit = locationFit(c, distanceKm: dist);
      final qScore = qualityScore(c);
      final nScore = noveltyScore(c, weights, seenIds: seenIds);
      final fScore = frictionScore(c, distanceKm: dist);
      final wFit = weatherFit(c, weather);
      final oFit = openingHoursFit(c, plannedStart);
      final todFit = timeOfDayFit(c, intent, plannedStart);
      final raw =
          gFit + iFit + tFit + bFit + lFit + qScore + nScore - fScore +
          wFit + oFit + todFit;
      final total = (raw * 100).round() / 100;
      out.add(ScoredCandidate(
        candidate: c,
        scores: {
          'intentFit': iFit,
          'groupFit': gFit,
          'timeFit': tFit,
          'budgetFit': bFit,
          'locationFit': lFit,
          'qualityScore': qScore,
          'noveltyScore': nScore,
          'frictionScore': fScore,
          'weatherFit': wFit,
          'openingHoursFit': oFit,
          'timeOfDayFit': todFit,
        },
        total: total,
      ));
    }
    out.sort((a, b) => b.total.compareTo(a.total));
    return out;
  }
}
