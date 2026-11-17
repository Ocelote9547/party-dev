import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/location_service.dart';

void main() {
  group('LocationService', () {
    test('manual guarda texto y approximate=true', () {
      final loc = LocationService.manual('Malasaña, Madrid');
      expect(loc.label, 'Malasaña, Madrid');
      expect(loc.approximate, isTrue);
      expect(loc.lat, isNull);
      expect(loc.lng, isNull);
    });

    test('distanceKm Centro→Retiro ≈ 1.5-2.5km', () {
      // Puerta del Sol → Parque del Retiro (Madrid).
      final km = LocationService.distanceKm(
          40.416775, -3.70379, 40.41526, -3.68454);
      expect(km, isNotNull);
      expect(km!, greaterThanOrEqualTo(1.5));
      expect(km, lessThanOrEqualTo(2.5));
    });

    test('coordenadas inválidas devuelven null sin lanzar', () {
      expect(
          LocationService.distanceKm(
              double.nan, 0, 40.416775, -3.70379),
          isNull);
      expect(
          LocationService.distanceKm(
              double.nan, double.nan, double.nan, double.nan),
          isNull);
      expect(LocationService.distanceKm(100, 0, 0, 0), isNull);
    });
  });
}
