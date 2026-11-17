import 'dart:convert';

import 'package:http/http.dart' as http;

/// Sugerencia de lugar con coordenadas reales (Nominatim / OpenStreetMap).
/// Gratis, sin API key. Nunca lanza: devuelve lista vacía si falla.
class PlaceSuggestion {
  final String label; // ej. "Alcalá de Henares, Comunidad de Madrid, España"
  final String shortLabel; // ej. "Alcalá de Henares"
  final double lat;
  final double lng;
  const PlaceSuggestion({
    required this.label,
    required this.shortLabel,
    required this.lat,
    required this.lng,
  });
}

/// Geocoding real vía Nominatim (OSM). Uso:
/// - `autocomplete(query)`: para el autocompletado del cuadro "¿Dónde estás?".
/// - `geocodeFirst(query)`: convierte texto libre en coords (pueblos, barrios).
/// - `reverse(lat, lng)`: etiqueta legible desde GPS.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, List<PlaceSuggestion>> _cache = {};

  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {
    // Nominatim exige User-Agent identificable.
    'User-Agent': 'PARTY-App/1.8.3 (com.n3mesis.party)',
    'Accept': 'application/json',
  };

  /// Autocompletado de lugares de verdad (pueblos, barrios, ciudades).
  /// Devuelve máximo [limit] sugerencias ordenadas por importancia.
  Future<List<PlaceSuggestion>> autocomplete(
    String query, {
    int limit = 6,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final key = '${q.toLowerCase()}|$limit';
    if (_cache.containsKey(key)) return _cache[key]!;
    try {
      final uri = Uri.https(_host, '/search', {
        'format': 'jsonv2',
        'q': q,
        'addressdetails': '1',
        'limit': '$limit',
        'countrycodes': 'es',
        'accept-language': 'es',
      });
      final res = await _client.get(uri, headers: _headers).timeout(timeout);
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return const [];
      final out = <PlaceSuggestion>[];
      for (final el in decoded) {
        if (el is! Map) continue;
        final lat = double.tryParse('${el['lat']}');
        final lon = double.tryParse('${el['lon']}');
        if (lat == null || lon == null) continue;
        if (lat.abs() > 90 || lon.abs() > 180) continue;
        final display = '${el['display_name'] ?? ''}'.trim();
        if (display.isEmpty) continue;
        out.add(PlaceSuggestion(
          label: display,
          shortLabel: _shortLabel(el, display),
          lat: lat,
          lng: lon,
        ));
      }
      _cache[key] = out;
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Primera coincidencia para un texto libre. Null si no hay.
  Future<PlaceSuggestion?> geocodeFirst(
    String query, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final list = await autocomplete(query, limit: 1, timeout: timeout);
    return list.isEmpty ? null : list.first;
  }

  /// Etiqueta legible desde coordenadas GPS (barrio/pueblo real).
  Future<String?> reverse(
    double lat,
    double lng, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final uri = Uri.https(_host, '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'zoom': '14',
        'accept-language': 'es',
      });
      final res = await _client.get(uri, headers: _headers).timeout(timeout);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;
      final address = decoded['address'];
      if (address is Map) {
        final parts = <String>[
          '${address['village'] ?? ''}'.trim(),
          '${address['town'] ?? ''}'.trim(),
          '${address['city'] ?? ''}'.trim(),
          '${address['suburb'] ?? ''}'.trim(),
          '${address['municipality'] ?? ''}'.trim(),
        ].where((e) => e.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          // Pueblo primero + ciudad si difiere.
          final first = parts.first;
          final city = '${address['city'] ?? address['town'] ?? ''}'.trim();
          if (city.isNotEmpty && city != first) return '$first, $city';
          return first;
        }
      }
      final display = '${decoded['display_name'] ?? ''}'.trim();
      if (display.isEmpty) return null;
      // Recorta a las 2 primeras partes para que quepa en el cuadro.
      final cut = display.split(',').take(2).join(',').trim();
      return cut.isEmpty ? null : cut;
    } catch (_) {
      return null;
    }
  }

  static String _shortLabel(Map el, String display) {
    try {
      final address = el['address'];
      if (address is Map) {
        for (final k in [
          'village',
          'town',
          'city',
          'suburb',
          'municipality',
          'county'
        ]) {
          final v = '${address[k] ?? ''}'.trim();
          if (v.isNotEmpty) return v;
        }
      }
      final named = '${el['name'] ?? ''}'.trim();
      if (named.isNotEmpty) return named;
    } catch (_) {}
    return display.split(',').first.trim();
  }
}
