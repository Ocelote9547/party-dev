import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/discovery_engine.dart';
import 'package:party/plans/models/models.dart';
import 'package:party/plans/sources/mock_source.dart';

void main() {
  group('Fuentes mock (Fase 4)', () {
    test('MockPlaceSource devuelve lista no vacía', () async {
      final places = await MockPlaceSource().fetchAll();
      expect(places, isNotEmpty);
    });

    test('MockRouteSource devuelve lista no vacía', () async {
      final routes = await MockRouteSource().fetchAll();
      expect(routes, isNotEmpty);
    });

    test('MockActivitySource devuelve lista no vacía', () async {
      final activities = await MockActivitySource().fetchAll();
      expect(activities, isNotEmpty);
    });

    test('todo Place tiene id/title no vacíos', () async {
      final places = await MockPlaceSource().fetchAll();
      for (final p in places) {
        expect(p.id, isNotEmpty);
        expect(p.title, isNotEmpty);
      }
    });
  });

  group('DiscoveryEngine', () {
    test('discover() agrega places, routes y activities', () async {
      final engine = DiscoveryEngine(
        places: MockPlaceSource(),
        routes: MockRouteSource(),
        activities: MockActivitySource(),
      );
      final result = await engine.discover();
      expect(result.places, isNotEmpty);
      expect(result.routes, isNotEmpty);
      expect(result.activities, isNotEmpty);
      // allCandidates agrega lugares + rutas + actividades.
      expect(
        result.allCandidates.length,
        result.places.length +
            result.routes.length +
            result.activities.length,
      );
      expect(
        result.allCandidates.where((c) => c.type == CandidateType.route),
        isNotEmpty,
      );
    });
  });
}
