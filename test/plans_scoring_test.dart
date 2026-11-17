import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/intent_engine.dart';
import 'package:party/plans/engines/scoring_engine.dart';
import 'package:party/plans/intent.dart';
import 'package:party/plans/models/models.dart';

// Candidato base con valores neutros para aislar cada dimensión.
Candidate _cand({
  required String id,
  double price = 10,
  int duration = 120,
  double rating = 3,
  int reviews = 10,
  double confidence = 0.5,
  String difficulty = 'facil',
  List<String> tags = const ['cultura'],
}) {
  return Candidate(
    id: id,
    type: CandidateType.cultural,
    title: id,
    price: price,
    durationMinutes: duration,
    rating: rating,
    reviewCount: reviews,
    confidence: confidence,
    difficulty: difficulty,
    tags: tags,
  );
}

// Intención base con presupuesto y slot controlables.
UserIntent _intent({
  WithWhom withWhom = WithWhom.amigos,
  TimeSlot slot = TimeSlot.h2_4,
  double maxBudget = 40,
}) {
  return UserIntent(
    withWhom: withWhom,
    appetites: const {Appetite.fiesta},
    timeSlot: slot,
    budgetMinPerPerson: 0,
    budgetMaxPerPerson: maxBudget,
    moveMode: MoveMode.coche,
  );
}

void main() {
  group('ScoringEngine', () {
    test('gratis gana con presupuesto ajustado', () {
      final intent = _intent(maxBudget: 10);
      final weights = IntentEngine.map(intent);
      final gratis = _cand(id: 'gratis', price: 0);
      final pago = _cand(id: 'pago', price: 10);
      final res = ScoringEngine.scoreAll([pago, gratis], weights, intent);
      expect(res.first.candidate.id, 'gratis');
      expect(res.first.scores['budgetFit'], 2);
    });

    test('cercano gana al lejano con mismos datos', () {
      final intent = _intent();
      final weights = IntentEngine.map(intent);
      final a = _cand(id: 'cerca');
      final b = _cand(id: 'lejos');
      final res = ScoringEngine.scoreAll(
        [b, a],
        weights,
        intent,
        distancesKm: {'cerca': 2, 'lejos': 30},
      );
      expect(res.first.candidate.id, 'cerca');
      expect(res.first.scores['locationFit'], 2);
      expect(res.last.scores['locationFit'], 0);
    });

    test('visto penaliza frente a no visto con novelty alta', () {
      final intent = _intent();
      final weights = IntentEngine.map(intent)..novelty = 4;
      final visto = _cand(id: 'visto', tags: ['nuevo']);
      final nuevo = _cand(id: 'nuevo', tags: ['nuevo']);
      final res = ScoringEngine.scoreAll(
        [visto, nuevo],
        weights,
        intent,
        seenIds: {'visto'},
      );
      expect(res.first.candidate.id, 'nuevo');
      expect(res.last.scores['noveltyScore'], lessThan(0));
      expect(res.first.scores['noveltyScore'], greaterThan(0));
    });

    test('orden descendente garantizado', () {
      final intent = _intent();
      final weights = IntentEngine.map(intent);
      final list = [
        _cand(id: 'c1', price: 30, rating: 1),
        _cand(id: 'c2', price: 0, rating: 5, reviews: 100),
        _cand(id: 'c3', price: 5, rating: 3),
      ];
      final res = ScoringEngine.scoreAll(list, weights, intent);
      for (var i = 0; i < res.length - 1; i++) {
        expect(res[i].total, greaterThanOrEqualTo(res[i + 1].total));
      }
    });

    test('dimensiones documentadas en scores', () {
      final intent = _intent();
      final weights = IntentEngine.map(intent);
      final res = ScoringEngine.scoreAll([_cand(id: 'x')], weights, intent);
      expect(
        res.single.scores.keys,
        containsAll([
          'intentFit',
          'groupFit',
          'timeFit',
          'budgetFit',
          'locationFit',
          'qualityScore',
          'noveltyScore',
          'frictionScore',
        ]),
      );
    });
  });
}
