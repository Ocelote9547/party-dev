import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/validation_engine.dart';
import 'package:party/plans/intent.dart';
import 'package:party/plans/models/models.dart';
import 'package:party/plans/validators/validation.dart';
import 'package:party/plans/validators/validators.dart';

UserIntent _intent({
  TimeSlot slot = TimeSlot.h30_60,
  double maxBudget = 15,
  MoveMode mode = MoveMode.pie,
}) {
  return UserIntent(
    withWhom: WithWhom.amigos,
    appetites: const {Appetite.cultura},
    timeSlot: slot,
    budgetMinPerPerson: 0,
    budgetMaxPerPerson: maxBudget,
    moveMode: mode,
  );
}

ValidationContext _ctx(UserIntent i) =>
    ValidationContext(intent: i, now: DateTime(2026, 9, 13, 12));

Candidate _candidate({
  String id = 'c1',
  int duration = 60,
  double price = 10,
  bool perPerson = true,
  List<String> tags = const [],
}) {
  return Candidate(
    id: id,
    type: CandidateType.place,
    title: 'T $id',
    durationMinutes: duration,
    price: price,
    pricePerPerson: perPerson,
    tags: tags,
  );
}

void main() {
  group('Fase 5 Validation', () {
    test('candidato que excede tiempo => INVALID', () {
      final ctx = _ctx(_intent(slot: TimeSlot.h30_60));
      final c = _candidate(duration: 120);
      expect(TimeValidator.check(c, ctx).valid, isFalse);
    });

    test('gratis siempre válido en budget', () {
      final ctx = _ctx(_intent(maxBudget: 0));
      final c = _candidate(price: 0);
      expect(BudgetValidator.check(c, ctx).valid, isTrue);
      // Caro con tope 0 => INVALID.
      expect(BudgetValidator.check(_candidate(price: 5), ctx).valid, isFalse);
    });

    test('sin dato de distancia no invalida transporte', () {
      final ctx = _ctx(_intent(mode: MoveMode.pie));
      final c = _candidate();
      expect(TransportValidator.check(c, ctx).valid, isTrue);
      expect(
          TransportValidator.check(c, ctx, distanceKm: 50).valid, isFalse);
      // Bici tolera hasta 30.
      final ctxBici = _ctx(_intent(mode: MoveMode.bici));
      expect(TransportValidator.check(c, ctxBici, distanceKm: 20).valid,
          isTrue);
    });

    test('ruta sin inicio/fin => INVALID', () {
      const bad = PlanRoute(id: 'r1', title: 'R', distanceKm: 5);
      expect(RouteValidator.checkPlanRoute(bad).valid, isFalse);
      const ok = PlanRoute(
          id: 'r2',
          title: 'R',
          startPoint: 'A',
          endPoint: 'B',
          distanceKm: 5);
      expect(RouteValidator.checkPlanRoute(ok).valid, isTrue);
    });

    test('plan con vuelta imposible => INVALID', () {
      final ctx = _ctx(_intent(slot: TimeSlot.h2_4));
      const p = Plan(
          id: 'p1',
          title: 'P',
          totalDurationMinutes: 60,
          costPerPerson: 5,
          returnFeasibility: ReturnFeasibility.impossible);
      expect(ValidationEngine.validatePlan(p, ctx).valid, isFalse);
    });

    test('plan válido pasa', () {
      final ctx = _ctx(_intent(slot: TimeSlot.h2_4, maxBudget: 40));
      const p = Plan(
          id: 'p2',
          title: 'P',
          totalDurationMinutes: 120,
          costPerPerson: 10,
          returnFeasibility: ReturnFeasibility.good);
      expect(ValidationEngine.validatePlan(p, ctx).valid, isTrue);
    });

    test('filter elimina INVALID y conserva válidos', () {
      final ctx = _ctx(_intent(slot: TimeSlot.h30_60, maxBudget: 15));
      final list = [
        _candidate(id: 'ok', duration: 45, price: 10),
        _candidate(id: 'largo', duration: 300, price: 5),
        _candidate(id: 'cerrado', duration: 30, tags: const ['cerrado']),
      ];
      final out = ValidationEngine.filter(list, ctx);
      expect(out.map((e) => e.id), contains('ok'));
      expect(out.map((e) => e.id), isNot(contains('largo')));
      expect(out.map((e) => e.id), isNot(contains('cerrado')));
    });
  });
}
