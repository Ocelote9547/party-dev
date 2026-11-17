/// Tipo de etapa dentro de un plan completo.
enum PlanStepType {
  start,
  travel,
  activity,
  route,
  food,
  viewpoint,
  rest,
  end,
}

/// Viabilidad de la vuelta al punto de origen. Si es imposible,
/// el plan debe descartarse (INVALID), no solo puntuar bajo.
enum ReturnFeasibility {
  good,
  acceptable,
  bad,
  impossible,
}

class PlanStep {
  final PlanStepType type;
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final String location;
  final int durationMinutes;
  final double cost;
  final String transport; // ej. "8 min andando" o "27 min bus"
  final String instructions;

  const PlanStep({
    required this.type,
    required this.title,
    this.startTime,
    this.endTime,
    this.location = '',
    this.durationMinutes = 0,
    this.cost = 0,
    this.transport = '',
    this.instructions = '',
  });
}

/// Un plan es una experiencia completa, no un lugar suelto.
class Plan {
  final String id;
  final String title;
  final String summary;
  final double score;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<PlanStep> steps;
  final int totalDurationMinutes;
  final double totalCost;
  final double costPerPerson;
  final String difficulty;
  final String transportSummary;
  final ReturnFeasibility returnFeasibility;
  final List<String> whyRecommended;
  final List<String> warnings;
  final List<String> sources;
  final String? imageUrl; // foto elegida para el plan, null = usar picsum
  final double? distanceKm; // haversine usuario→lugar, null = sin dato
  /// Resumen del tiempo previsto (si se consultó).
  final String? weatherSummary;
  /// Código WMO del tiempo (si se consultó).
  final int? weatherCode;
  /// Fecha/hora en que se generó el plan.
  final DateTime? generatedAt;
  /// Nombre personalizado dado por el usuario (para "Mis Planes").
  final String? customName;

  const Plan({
    required this.id,
    required this.title,
    this.summary = '',
    this.score = 0,
    this.startTime,
    this.endTime,
    this.steps = const [],
    this.totalDurationMinutes = 0,
    this.totalCost = 0,
    this.costPerPerson = 0,
    this.difficulty = 'facil',
    this.transportSummary = '',
    this.returnFeasibility = ReturnFeasibility.good,
    this.whyRecommended = const [],
    this.warnings = const [],
    this.sources = const [],
    this.imageUrl,
    this.distanceKm,
    this.weatherSummary,
    this.weatherCode,
    this.generatedAt,
    this.customName,
  });

  /// Copia con campos actualizados (resto inalterado).
  Plan copyWith({
    String? imageUrl,
    double? distanceKm,
    String? weatherSummary,
    int? weatherCode,
    DateTime? generatedAt,
    String? customName,
  }) => Plan(
        id: id,
        title: title,
        summary: summary,
        score: score,
        startTime: startTime,
        endTime: endTime,
        steps: steps,
        totalDurationMinutes: totalDurationMinutes,
        totalCost: totalCost,
        costPerPerson: costPerPerson,
        difficulty: difficulty,
        transportSummary: transportSummary,
        returnFeasibility: returnFeasibility,
        whyRecommended: whyRecommended,
        warnings: warnings,
        sources: sources,
        imageUrl: imageUrl ?? this.imageUrl,
        distanceKm: distanceKm ?? this.distanceKm,
        weatherSummary: weatherSummary ?? this.weatherSummary,
        weatherCode: weatherCode ?? this.weatherCode,
        generatedAt: generatedAt ?? this.generatedAt,
        customName: customName ?? this.customName,
      );
}
