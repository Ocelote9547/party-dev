import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'geocoding_service.dart';
import 'user_location.dart';

// Resultado con error legible para mostrar en UI (SnackBar visible).
class LocationResult {
  final UserLocation? location;
  final String? error; // null = ok
  const LocationResult({this.location, this.error});
  bool get ok => location != null;
}

// Servicio de ubicación: nunca lanza, devuelve null si falla.
class LocationService {
  const LocationService._();

  static String _labelFromPlacemark(Placemark p) {
    final parts = <String>[
      if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      if ((p.locality ?? '').trim().isNotEmpty)
        p.locality!.trim()
      else if ((p.administrativeArea ?? '').trim().isNotEmpty)
        p.administrativeArea!.trim(),
    ].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? 'Ubicación aproximada' : parts.join(', ');
  }

  static Future<LocationResult> _fetch({
    required LocationAccuracy accuracy,
    required Duration timeLimit,
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationResult(
          error: 'GPS desactivado: activa la ubicación del móvil y reintenta.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          error: 'Permiso denegado: permite la ubicación para usar el GPS.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error: 'Permiso bloqueado: actívalo en Ajustes > Aplicaciones > PARTY > Ubicación.',
        );
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      ).timeout(timeLimit);
      String label = 'Ubicación aproximada';
      try {
        // geocoding ^5.0.0: API agrupada en la clase `Geocoding`
        // (antes función top-level `placemarkFromCoordinates`).
        final marks = await Geocoding()
            .placemarkFromCoordinates(
              pos.latitude,
              pos.longitude,
            )
            .timeout(const Duration(seconds: 6));
        if (marks.isNotEmpty) label = _labelFromPlacemark(marks.first);
      } catch (_) {
        // Sin red para geocoding nativo: prueba Nominatim (OSM).
        try {
          final rev = await GeocodingService()
              .reverse(pos.latitude, pos.longitude)
              .timeout(const Duration(seconds: 6));
          if (rev != null && rev.isNotEmpty) label = rev;
        } catch (_) {}
      }
      return LocationResult(
        location: UserLocation(label: label, lat: pos.latitude, lng: pos.longitude),
      );
    } catch (_) {
      return const LocationResult(
        error: 'No se pudo obtener la ubicación. Revisa GPS/permiso o escribe tu pueblo manualmente.',
      );
    }
  }

  // Ubicación EXACTA (GPS alta precisión, timeout 12s).
  static Future<LocationResult> requestExactDetailed() => _fetch(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

  // Ubicación APROXIMADA (baja precisión, rápida, timeout 10s).
  static Future<LocationResult> requestApproximateDetailed() => _fetch(
        accuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

  // Pide permiso y devuelve barrio/ciudad aproximados, o null si falla.
  static Future<UserLocation?> requestApproximate() async {
    final r = await requestApproximateDetailed();
    return r.location;
  }

  // Exacta legacy (null si falla).
  static Future<UserLocation?> requestExact() async {
    final r = await requestExactDetailed();
    return r.location;
  }

  // Entrada manual sin coordenadas.
  static UserLocation manual(String text) {
    try {
      return UserLocation(label: text, approximate: true);
    } catch (_) {
      return const UserLocation(label: '', approximate: true);
    }
  }

  // Haversine en km; null si datos inválidos. Nunca lanza.
  static double? distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    try {
      final coords = [lat1, lng1, lat2, lng2];
      if (coords.any((c) => c.isNaN || c.isInfinite)) return null;
      if (lat1.abs() > 90 ||
          lat2.abs() > 90 ||
          lng1.abs() > 180 ||
          lng2.abs() > 180) {
        return null;
      }
      const earthKm = 6371.0;
      final dLat = _toRad(lat2 - lat1);
      final dLng = _toRad(lng2 - lng1);
      final a = math.pow(math.sin(dLat / 2), 2) +
          math.cos(_toRad(lat1)) *
              math.cos(_toRad(lat2)) *
              math.pow(math.sin(dLng / 2), 2);
      final c = 2 * math.asin(math.sqrt(a.toDouble()));
      return earthKm * c;
    } catch (_) {
      return null;
    }
  }

  // Grados a radianes.
  static double _toRad(double deg) => deg * math.pi / 180.0;
}
