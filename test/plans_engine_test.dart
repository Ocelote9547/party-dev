import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/intent_engine.dart';
import 'package:party/plans/intent.dart';
import 'package:party/plans/models/models.dart';

UserIntent _base({
  WithWhom withWhom = WithWhom.amigos,
  Set<Appetite> appetites = const {Appetite.fiesta},
  TimeSlot timeSlot = TimeSlot.h2_4,
  double minBudget = 0,
  double maxBudget = 40,
  MoveMode moveMode = MoveMode.coche,
}) {
  return UserIntent(
    withWhom: withWhom,
    appetites: appetites,
    timeSlot: timeSlot,
    budgetMinPerPerson: minBudget,
    budgetMaxPerPerson: maxBudget,
    moveMode: moveMode,
  );
}

void main() {
  group('IntentEngine', () {
    test('sorpresa prioriza novedad', () {
      final w = IntentEngine.map(_base(appetites: {Appetite.sorpresa}));
      expect(w.novelty, greaterThanOrEqualTo(2));
      expect(w.top(1).first, 'novelty');
    });

    test('relax prioriza relax y calma con baja fricción', () {
      final w = IntentEngine.map(
          _base(withWhom: WithWhom.familia, appetites: {Appetite.relax}));
      expect(w.relax, greaterThanOrEqualTo(2));
      expect(w.lowFriction, greaterThanOrEqualTo(1));
    });

    test('desconectar sube relax, naturaleza y baja fricción', () {
      final w = IntentEngine.map(
          _base(withWhom: WithWhom.solo, appetites: {Appetite.relax}));
      expect(w.relax, greaterThanOrEqualTo(2));
      expect(w.nature, greaterThanOrEqualTo(1));
      expect(w.lowFriction, greaterThanOrEqualTo(1));
    });

    test('amigos de fiesta es social y diversión', () {
      final w = IntentEngine.map(_base());
      expect(w.social, greaterThanOrEqualTo(2));
      expect(w.entertainment, greaterThanOrEqualTo(2));
    });

    test('noveltyBoost suma novedad y descubrimiento', () {
      final plain = _base(appetites: {Appetite.cultura});
      final boosted = UserIntent(
        withWhom: plain.withWhom,
        appetites: plain.appetites,
        timeSlot: plain.timeSlot,
        budgetMinPerPerson: plain.budgetMinPerPerson,
        budgetMaxPerPerson: plain.budgetMaxPerPerson,
        moveMode: plain.moveMode,
        noveltyBoost: true,
      );
      final w = IntentEngine.map(boosted);
      expect(w.novelty, greaterThanOrEqualTo(2));
      expect(w.discovery, greaterThanOrEqualTo(1));
    });

    test('describe genera bullets legibles', () {
      final bullets =
          IntentEngine.describe(_base(appetites: {Appetite.sorpresa}));
      expect(bullets, contains('Busca novedad'));
    });
  });

  group('Modelos Fase 2', () {
    test('CostBreakdown total y por persona', () {
      const c = CostBreakdown(
        activity: 12,
        transportOutbound: 1.5,
        transportReturn: 1.5,
        food: 10,
        groupSize: 4,
      );
      expect(c.total, 25);
      expect(c.perPerson, 6.25);
    });

    test('BudgetRange gratis es 0..0', () {
      expect(BudgetRange.gratis.minPerPerson, 0);
      expect(BudgetRange.gratis.maxPerPerson, 0);
      expect(BudgetRange.mas80.maxPerPerson, double.infinity);
    });

    test('TimeSlot todo el día cubre 360..720 min', () {
      expect(TimeSlot.todoDia.minMinutes, 360);
      expect(TimeSlot.todoDia.maxMinutes, 720);
    });

    test('Plan por defecto es válido', () {
      const p = Plan(id: 'x', title: 'Prueba');
      expect(p.steps, isEmpty);
      expect(p.returnFeasibility, ReturnFeasibility.good);
    });
  });
}
