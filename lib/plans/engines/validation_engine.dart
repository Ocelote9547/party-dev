import '../intent.dart';
import '../models/models.dart';
import '../validators/validation.dart';
import '../validators/validators.dart';

/// Motor de validación dura (fase 5): filtra, no puntúa bajo.
class ValidationEngine {
  /// Filtra candidatos: cualquiera INVALID se elimina (no puntúa bajo).
  static List<Candidate> filter(List<Candidate> candidates,
      ValidationContext ctx,
      {Map<String, double>? distancesKm}) {
    return candidates.where((Candidate c) {
      if (!TimeValidator.check(c, ctx).valid) return false;
      if (!BudgetValidator.check(c, ctx).valid) return false;
      final double? d = distancesKm?[c.id];
      if (!TransportValidator.check(c, ctx, distanceKm: d).valid) return false;
      if (!AvailabilityValidator.check(c, ctx).valid) return false;
      return true;
    }).toList();
  }

  /// Valida un Plan completo: tiempo, presupuesto, vuelta imposible => INVALID.
  static ValidationResult validatePlan(Plan plan, ValidationContext ctx) {
    if (plan.returnFeasibility == ReturnFeasibility.impossible) {
      return const ValidationResult.invalid('Vuelta imposible');
    }
    final int max = ctx.intent.timeSlot.maxMinutes;
    if (plan.totalDurationMinutes > max) {
      return ValidationResult.invalid(
          'Plan excede tiempo: ${plan.totalDurationMinutes} > $max min');
    }
    final double budgetMax = ctx.intent.budgetMaxPerPerson;
    if (!budgetMax.isInfinite && plan.costPerPerson > budgetMax) {
      return ValidationResult.invalid(
          'Plan supera presupuesto: ${plan.costPerPerson} > $budgetMax');
    }
    return const ValidationResult.valid();
  }
}
