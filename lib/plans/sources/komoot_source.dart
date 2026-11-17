import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'data_source.dart';

/// Rutas reales vía Komoot (sin API key, endpoint público de búsqueda).
///
/// Komoot es la plataforma de rutas más popular en Europa: tiene
/// senderismo, BTT, ciclismo y trail running. Su API pública de
/// búsqueda devuelve rutas con distancia, duración, dificultad,
/// elevación y enlace verificable. Si falla la consulta, el error se
/// propaga para que DiscoveryEngine lo registre.
class KomootRouteSource implements RouteSource {
  final double lat;
  final double lng;
  final double radiusKm;
  final String sport; // hike, mtb, tour, trailrun, etc.
  final http.Client _client;
  final Duration timeout;

  KomootRouteSource({
    required this.lat,
    required this.lng,
    this.radiusKm = 30,
    this.sport = 'hike',
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<List<PlanRoute>> fetchAll() async {
    try {
      // Sport mapping: hike, mtb, tour, trailrun, running, etc.
      final uri = Uri.https('www.komoot.com', '/api/v007/tours/', {
        'sport': sport,
        'lat': '$lat',
        'lon': '$lng',
        'max_distance': '${(radiusKm * 1000).round()}',
        'sort': 'rating',
        'limit': '15',
      });
      final res = await _client.get(uri, headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
        'Accept': 'application/json',
      }).timeout(timeout);
      if (res.statusCode != 200) {
        throw StateError('Komoot HTTP ${res.statusCode}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return const [];
      final tours = decoded['tours'];
      if (tours is! List) return const [];
      final routes = <PlanRoute>[];
      final seen = <String>{};
      for (final t in tours) {
        if (t is! Map) continue;
        final name = '${t['name'] ?? ''}'.trim();
        if (name.isEmpty || name.length < 3) continue;
        if (!seen.add(name.toLowerCase())) continue;
        final distanceKm = ((t['distance'] as num?)?.toDouble() ?? 0) / 1000.0;
        final durationMin = (t['duration'] as num?)?.toInt() ?? 0;
        final elevation = (t['elevation_up'] as num?)?.toInt() ?? 0;
        final difficulty = _difficultyFrom(t);
        final id = 'komoot-${t['id'] ?? name}';
        final centerLat = (t['start_point'] is Map)
            ? (t['start_point']['lat'] as num?)?.toDouble()
            : null;
        final centerLng = (t['start_point'] is Map)
            ? (t['start_point']['lon'] as num?)?.toDouble()
            : null;
        routes.add(PlanRoute(
          id: id,
          title: name,
          description: _descFor(sport, distanceKm, elevation),
          startPoint: '${t['start_point']?['name'] ?? ''}'.trim(),
          endPoint: '${t['end_point']?['name'] ?? ''}'.trim(),
          distanceKm: distanceKm > 0.3 && distanceKm < 150 ? distanceKm : 0,
          durationMinutes: durationMin > 0
              ? (durationMin / 60).round().clamp(30, 480)
              : (distanceKm > 0
                  ? (distanceKm / _speedFor(sport) * 60).round().clamp(30, 480)
                  : 90),
          elevationGain: elevation,
          difficulty: difficulty,
          surfaceType: _surfaceFor(sport),
          circular: t['type'] == 'tour_circular' || t['type'] == 'loop',
          returnToStart: t['type'] == 'tour_circular' || t['type'] == 'loop',
          centerLat: centerLat,
          centerLng: centerLng,
          source: 'komoot',
          sourceUrl:
              'https://www.komoot.com/tour/${t['id'] ?? ''}',
          verifiedAt: DateTime.now(),
        ));
        if (routes.length >= 15) break;
      }
      return routes;
    } catch (error) {
      throw StateError('Error consultando Komoot: $error');
    }
  }

  static String _difficultyFrom(Map t) {
    final diff = (t['difficulty'] ?? '').toString().toLowerCase();
    if (diff.contains('difficult') || diff.contains('hard')) return 'alta';
    if (diff.contains('intermediate') || diff.contains('medium')) {
      return 'media';
    }
    return 'facil';
  }

  static String _surfaceFor(String sport) {
    switch (sport) {
      case 'mtb':
        return 'sendero';
      case 'tour':
        return 'carretera';
      default:
        return 'sendero';
    }
  }

  static String _descFor(String sport, double distKm, int elev) {
    final elevStr = elev > 0 ? ' · +${elev}m desnivel' : '';
    switch (sport) {
      case 'mtb':
        return 'Ruta de BTT real de Komoot$elevStr';
      case 'tour':
        return 'Ruta ciclista real de Komoot$elevStr';
      case 'trailrun':
        return 'Ruta de trail running real de Komoot$elevStr';
      default:
        return 'Ruta de senderismo real de Komoot$elevStr';
    }
  }

  static double _speedFor(String sport) {
    switch (sport) {
      case 'mtb':
      case 'tour':
        return 15;
      case 'trailrun':
        return 8;
      default:
        return 4;
    }
  }
}
