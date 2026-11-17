import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/discovery_engine.dart';
import 'package:party/plans/engines/plan_generator.dart';
import 'package:party/plans/intent.dart';
import 'package:party/plans/models/models.dart';
import 'package:party/plans/photo_service.dart';
import 'package:party/plans/sources/curated_routes.dart';
import 'package:party/plans/sources/data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Datos: fotos Wikimedia, rutas curadas y generador con lat/lng.
void main() {
  group('plans_v2_data', () {
    test('photo service no lanza con query absurda (null o URL)', () async {
      final svc = PhotoService();
      final url = await svc.fetchPhotoUrl(
        query: 'zzqqxx-no-existe-123456789',
        timeout: const Duration(seconds: 8),
      );
      // Null (sin resultados/fallo) o URL http válida.
      expect(url == null || url.startsWith('http'), isTrue);
    });

    test('curated routes no vacías y con sourceUrl', () {
      expect(CuratedRoutes.all.length, greaterThanOrEqualTo(8));
      for (final r in CuratedRoutes.all) {
        expect(r.title.isNotEmpty, isTrue);
        expect(r.startPoint.isNotEmpty, isTrue);
        expect(r.endPoint.isNotEmpty, isTrue);
        expect(r.sourceUrl, isNotNull);
        expect(r.sourceUrl!, startsWith('http'));
      }
      // Enchufable como RouteSource sin tocar DiscoveryEngine.
      const src = CuratedRouteSource();
      expect(src, isA<RouteSource>());
    });

    test('generator acepta intent con lat/lng sin romper', () async {
      SharedPreferences.setMockInitialValues({});
      const intent = UserIntent(
        withWhom: WithWhom.amigos,
        appetites: {Appetite.naturaleza},
        timeSlot: TimeSlot.h2_4,
        budgetMinPerPerson: 0,
        budgetMaxPerPerson: 40,
        moveMode: MoveMode.pie,
        lat: 40.41,
        lng: -3.70,
        locationLabel: 'Madrid',
      );
      const place = Place(
        id: 'mad-1',
        title: 'Mirador',
        description: 'Vistas',
        location: GeoPoint(40.42, -3.69),
        durationMinutes: 60,
        tags: ['naturaleza'],
      );
      final discovered = DiscoveryResult(
        places: const [place],
        routes: CuratedRoutes.all.take(2).toList(),
      );
      final plans = await PlanGenerator.generate(
        intent: intent,
        discovered: discovered,
        useProfile: false,
      );
      expect(plans, isNotEmpty);
      // Con perfil activado tampoco rompe (try/catch interno).
      final plansProfile = await PlanGenerator.generate(
        intent: intent,
        discovered: discovered,
      );
      expect(plansProfile, isNotEmpty);
    });
  });
}
