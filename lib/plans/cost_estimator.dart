import 'intent.dart';

/// Estimador de costes reales por persona (Fase costes afinados).
/// Todo redondeado a 0.5 € para que el desglose sea legible en la tarjeta.
/// Nunca lanza.
class CostEstimator {
  const CostEstimator._();

  /// Redondea a 0.5 € (2.33 -> 2.5).
  static double roundHalf(double v) {
    if (!v.isFinite || v <= 0) return 0;
    return (v * 2).round() / 2.0;
  }

  /// Transporte IDA por persona según medio y distancia (km, haversine).
  /// - pie/bici propia: 0
  /// - patinete alquiler: 1 € desbloqueo + 0.25 €/min (~15km/h)
  /// - coche propio: 0.22 €/km + 2 € parking si >5km, dividido entre grupo
  /// - bus-metro: billete sencillo 2.5 € (bono estimado 1.5 € si <=5km)
  /// - taxi: 1.3 €/km + 3 bajada, mín 5 €, dividido entre grupo
  /// - tren/cercanías: 3.5 € (<=30km) / 8 € (>30km)
  static double transportOneWay({
    required MoveMode mode,
    required double distanceKm,
    required int groupSize,
  }) {
    try {
      final g = groupSize <= 0 ? 1 : groupSize;
      final d = distanceKm.isFinite ? distanceKm.clamp(0, 300) : 5.0;
      switch (mode) {
        case MoveMode.pie:
        case MoveMode.bici:
          return 0;
        case MoveMode.patinete:
          if (d <= 0.5) return 0; // propio
          final minutes = d / 15 * 60;
          return roundHalf(1 + minutes * 0.25);
        case MoveMode.coche:
          if (d <= 0.5) return 0;
          return roundHalf((d * 0.22 + (d > 5 ? 2 : 0)) / g);
        case MoveMode.transporte:
          return d <= 5 ? 1.5 : 2.5;
        case MoveMode.indiferente:
          // Estimación neutra: mitad a pie/metro.
          return d <= 2 ? 0 : 1.5;
      }
    } catch (_) {
      return 0;
    }
  }

  /// Comida estimada por persona según duración y presupuesto.
  /// - <=90 min: 0 (no da tiempo)
  /// - 90-180 min: tapa/bebida 5 € (3 € si presupuesto bajo)
  /// - 180-300 min: comida ligera 12 € (8 € si bajo)
  /// - >300 min: comida completa 18 € (12 € si bajo)
  static double food({
    required int durationMinutes,
    required double budgetMaxPerPerson,
  }) {
    try {
      final low = budgetMaxPerPerson.isFinite && budgetMaxPerPerson <= 15;
      if (durationMinutes <= 90) return 0;
      if (durationMinutes <= 180) return low ? 3 : 5;
      if (durationMinutes <= 300) return low ? 8 : 12;
      return low ? 12 : 18;
    } catch (_) {
      return 0;
    }
  }

  /// Coste total por persona = actividad + transporte ida/vuelta + comida.
  /// `activityPrice` ya viene por persona desde el Candidate.
  static ({double activity, double transport, double food, double total})
      breakdown({
    required double activityPrice,
    required MoveMode mode,
    required double distanceKm,
    required int durationMinutes,
    required double budgetMaxPerPerson,
    required int groupSize,
  }) {
    final act = activityPrice.isFinite && activityPrice > 0
        ? roundHalf(activityPrice)
        : 0.0;
    final oneWay = transportOneWay(
      mode: mode,
      distanceKm: distanceKm,
      groupSize: groupSize,
    );
    final transport = roundHalf(oneWay * 2);
    final f = food(
      durationMinutes: durationMinutes,
      budgetMaxPerPerson: budgetMaxPerPerson,
    );
    return (
      activity: act,
      transport: transport,
      food: f,
      total: roundHalf(act + transport + f),
    );
  }

  /// Etiqueta corta: "Gratis" / "12 € aprox." / "12 € (act 8 + transp 0 + comida 4)".
  static String label(double total) =>
      total <= 0 ? 'Gratis' : '${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)} € aprox.';

  static String detail({
    required double activity,
    required double transport,
    required double food,
  }) {
    if (activity <= 0 && transport <= 0 && food <= 0) return 'Plan gratis';
    return 'Act ${activity.toStringAsFixed(activity % 1 == 0 ? 0 : 1)} € · '
        'Transp ${transport.toStringAsFixed(transport % 1 == 0 ? 0 : 1)} € · '
        'Comida ${food.toStringAsFixed(food % 1 == 0 ? 0 : 1)} €';
  }
}
