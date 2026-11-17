import '../intent.dart';
import '../models/models.dart';
import 'validation.dart';

/// Valida duración contra el hueco disponible.
class TimeValidator {
  /// INVALID si excede el máximo del [TimeSlot].
  static ValidationResult check(Candidate c, ValidationContext ctx) {
    final int max = ctx.intent.timeSlot.maxMinutes;
    if (c.durationMinutes > max) {
      return ValidationResult.invalid(
          'Excede tiempo: ${c.durationMinutes} > $max min');
    }
    return const ValidationResult.valid();
  }
}

/// Valida coste por persona contra el presupuesto máximo.
class BudgetValidator {
  /// Gratis (0) siempre válido.
  /// Simplificación: se compara [Candidate.price] con el máximo
  /// aunque no sea por persona (fase 5, sin desglose).
  static ValidationResult check(Candidate c, ValidationContext ctx) {
    if (c.price <= 0) return const ValidationResult.valid();
    final double max = ctx.intent.budgetMaxPerPerson;
    if (max.isInfinite) return const ValidationResult.valid();
    final double cost = c.pricePerPerson ? c.price : c.price;
    if (cost > max) {
      return ValidationResult.invalid('Supera presupuesto: $cost > $max');
    }
    return const ValidationResult.valid();
  }
}

/// Valida medio de desplazamiento contra la distancia.
class TransportValidator {
  /// Sin dato de distancia no invalida (falta de dato no es INVALID).
  static ValidationResult check(Candidate c, ValidationContext ctx,
      {double? distanceKm}) {
    if (distanceKm == null) return const ValidationResult.valid();
    final MoveMode mode = ctx.intent.moveMode;
    if (mode == MoveMode.pie && distanceKm > 10) {
      return ValidationResult.invalid('Demasiado lejos a pie: $distanceKm km');
    }
    if (mode == MoveMode.bici && distanceKm > 30) {
      return ValidationResult.invalid('Demasiado lejos en bici: $distanceKm km');
    }
    return const ValidationResult.valid();
  }
}

/// Valida que la ruta exista (inicio, fin y distancia).
class RouteValidator {
  /// INVALID si ruta inexistente. Las circulares siempre
  /// tienen vuelta factible (no requieren retorno aparte).
  static ValidationResult checkPlanRoute(PlanRoute r) {
    if (r.distanceKm <= 0) {
      return const ValidationResult.invalid('Ruta sin distancia');
    }
    if (r.startPoint.isEmpty || r.endPoint.isEmpty) {
      return const ValidationResult.invalid('Ruta sin inicio/fin');
    }
    return const ValidationResult.valid();
  }
}

/// Valida disponibilidad básica del candidato.
class AvailabilityValidator {
  static ValidationResult check(Candidate c, ValidationContext ctx) {
    if (c.tags.contains('cerrado')) {
      return const ValidationResult.invalid('Cerrado');
    }
    // TODO fase 12: parsear openingHours contra ctx.now.
    return const ValidationResult.valid();
  }
}
