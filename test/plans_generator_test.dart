import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/discovery_engine.dart';
import 'package:party/plans/engines/plan_generator.dart';
import 'package:party/plans/intent.dart';
import 'package:party/plans/models/models.dart';

// Mocks variados: gratis, medio y largo (con comida + reserva).
List<Place> _mockPlaces() => const [
      Place(
        id: 'p1',
        type: CandidateType.place,
        title: 'Mirador',
        description: 'Vistas gratis',
        price: 0,
        durationMinutes: 60,
        rating: 4.5,
        reviewCount: 100,
        tags: ['naturaleza'],
      ),
      Place(
        id: 'p2',
        type: CandidateType.cultural,
        title: 'Museo',
        description: 'Arte local',
        price: 10,
        durationMinutes: 90,
        rating: 4.0,
        reviewCount: 60,
        tags: ['cultura', 'reserva'],
      ),
      Place(
        id: 'p3',
        type: CandidateType.restaurant,
        title: 'Ruta foodie',
        description: 'Tapeo largo',
        price: 20,
        durationMinutes: 150,
        rating: 4.8,
        reviewCount: 200,
        tags: ['gastronomia'],
      ),
    ];

UserIntent _intent() => const UserIntent(
      withWhom: WithWhom.amigos,
      appetites: {Appetite.fiesta},
      timeSlot: TimeSlot.h2_4,
      budgetMinPerPerson: 0,
      budgetMaxPerPerson: 40,
      moveMode: MoveMode.pie,
    );

void main() {
  group('Fase 7 PlanGenerator', () {
    test('genera 1-5 planes ordenados con pasos y costes coherentes',
        () async {
      final discovered = DiscoveryResult(places: _mockPlaces());
      final now = DateTime(2026, 9, 13, 12);
      const groupSize = 2;
      final plans = await PlanGenerator.generate(
        intent: _intent(),
        discovered: discovered,
        startTime: now,
        groupSize: groupSize,
      );

      // 1-5 planes.
      expect(plans.length, greaterThanOrEqualTo(1));
      expect(plans.length, lessThanOrEqualTo(5));

      // Orden descendente por score.
      for (var i = 0; i < plans.length - 1; i++) {
        expect(plans[i].score, greaterThanOrEqualTo(plans[i + 1].score));
      }

      for (final p in plans) {
        // Pasos no vacíos con horarios secuenciales.
        expect(p.steps, isNotEmpty);
        expect(p.startTime, now);
        expect(p.endTime, isNotNull);
        var cursor = p.startTime!;
        for (final st in p.steps) {
          expect(st.startTime, cursor);
          expect(st.endTime!.isAfter(st.startTime!), isTrue);
          cursor = st.endTime!;
        }
        expect(p.endTime, cursor);
        // Coste por persona coherente con el total.
        expect(p.costPerPerson, closeTo(p.totalCost / groupSize, 0.001));
        expect(p.sources, isNotEmpty);
      }

      // El largo incluye comida; el de reserva avisa.
      final long =
          plans.where((p) => p.id == 'plan_p3').toList();
      if (long.isNotEmpty) {
        expect(long.single.steps.any((s) => s.title == 'Comida'), isTrue);
      }
      expect(plans.any((p) => p.warnings.contains('Requiere reserva')),
          isTrue);
    });
  });
}
