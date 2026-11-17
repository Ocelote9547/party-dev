import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'data_source.dart';

/// Fuente de rutas de senderismo reales vía Overpass API (OpenStreetMap).
///
/// Solo devuelve relaciones `route=hiking|foot` existentes, con enlace
/// verificable a openstreetmap.org. Sin API key. Si no hay red o no hay
/// resultados, devuelve lista vacía (el DiscoveryEngine hace fallback).
class OverpassRouteSource implements RouteSource {
  final double lat;
  final double lng;
  final double radiusKm;
  final http.Client _client;
  final Duration timeout;

  OverpassRouteSource({
    required this.lat,
    required this.lng,
    this.radiusKm = 30,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  // Mirrors en rotación: el principal falla a menudo desde móvil
  // (406/timeouts); se prueba el siguiente sin romper nada.
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  String _buildQuery() {
    final r = (radiusKm * 1000).round().clamp(1000, 50000);
    // Senderismo + BTT/bici + caballo: en los pueblos hay muchísimas
    // rutas ciclistas y ecuestres mapeadas que con solo hiking|foot no salían.
    return '[out:json][timeout:25];'
        '('
        'relation["route"~"hiking|foot|bicycle|mtb|horse"](around:$r,$lat,$lng);'
        ');'
        'out tags center 30;';
  }

  Future<http.Response> _post(String query) async {
    final clock = Stopwatch()..start();
    final perEndpointBudget =
        Duration(microseconds: timeout.inMicroseconds ~/ _endpoints.length);
    Object? lastError;

    for (final endpoint in _endpoints) {
      final remaining = timeout - clock.elapsed;
      if (remaining.inMicroseconds <= 0) break;
      final attemptTimeout = remaining.compareTo(perEndpointBudget) < 0
          ? remaining
          : perEndpointBudget;
      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: {'data': query},
            )
            .timeout(attemptTimeout);
        if (response.statusCode == 200) return response;
        lastError = StateError('HTTP ${response.statusCode} en $endpoint');
      } catch (error) {
        lastError = error;
      }
    }

    throw StateError(
      'Overpass rutas: tiempo agotado o mirrors no disponibles'
      '${lastError == null ? '' : ' ($lastError)'}',
    );
  }

  @override
  Future<List<PlanRoute>> fetchAll() async {
    try {
      final res = await _post(_buildQuery());
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Respuesta JSON de Overpass no válida');
      }
      final elements = decoded['elements'];
      if (elements is! List) {
        throw const FormatException('Overpass no devolvió una lista de elementos');
      }
      final routes = <PlanRoute>[];
      final seenNames = <String>{};
      for (final el in elements) {
        if (el is! Map<String, dynamic>) continue;
        if (el['type'] != 'relation') continue;
        final tags = el['tags'];
        if (tags is! Map) continue;
        final name = (tags['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (seenNames.contains(key)) continue; // evita duplicados OSM
        seenNames.add(key);
        final id = 'overpass-r${el['id']}';
        final distanceKm = _parseDistance(tags['distance']);
        final from = (tags['from'] ?? '').toString();
        final to = (tags['to'] ?? '').toString();
        final roundtrip =
            (tags['roundtrip'] ?? '').toString().toLowerCase() == 'yes';
        double? centerLat;
        double? centerLng;
        final center = el['center'];
        if (center is Map) {
          final clat = (center['lat'] as num?)?.toDouble();
          final clng = (center['lon'] as num?)?.toDouble();
          if (clat != null && clng != null) {
            centerLat = clat;
            centerLng = clng;
          }
        }
        final routeKind = (tags['route'] ?? '').toString().toLowerCase();
        routes.add(PlanRoute(
          id: id,
          title: name,
          description: _descForKind(routeKind),
          startPoint: from,
          endPoint: to,
          distanceKm: distanceKm,
          durationMinutes: distanceKm > 0
              ? (distanceKm / _speedFor(routeKind) * 60)
                  .round()
                  .clamp(30, 480)
              : 90,
          difficulty: _difficultyFor(tags['sac_scale']?.toString() ?? ''),
          surfaceType: 'sendero',
          circular: roundtrip,
          returnToStart: roundtrip,
          source: 'overpass',
          sourceUrl: 'https://www.openstreetmap.org/relation/${el['id']}',
          verifiedAt: DateTime.now(),
          centerLat: centerLat,
          centerLng: centerLng,
        ));
        if (routes.length >= 15) break;
      }
      // Primero las que traen distancia verificada (tiempos honestos);
      // las estimadas (90 min por defecto) después.
      routes.sort((a, b) {
        final da = a.distanceKm > 0 ? 0 : 1;
        final db = b.distanceKm > 0 ? 0 : 1;
        return da.compareTo(db);
      });
      return routes;
    } catch (error) {
      throw StateError('Error consultando Overpass (rutas): $error');
    }
  }

  /// Parsea "12", "12.5", "12,5 km" → km. 0 si no hay dato (el validador
  /// decide; no se inventa distancia).
  static double _parseDistance(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) {
      final v = raw.toDouble();
      return (v >= 0.3 && v <= 150) ? v : 0;
    }
    final m =
        RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(raw.toString());
    if (m == null) return 0;
    final v = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
    return (v >= 0.3 && v <= 150) ? v : 0;
  }

  static String _descForKind(String routeKind) {
    switch (routeKind) {
      case 'bicycle':
        return 'Ruta ciclista real cerca de ti, verificada en OpenStreetMap';
      case 'mtb':
        return 'Ruta de BTT real cerca de ti, verificada en OpenStreetMap';
      case 'horse':
        return 'Ruta ecuestre real cerca de ti, verificada en OpenStreetMap';
      default:
        return 'Ruta de senderismo verificada en OpenStreetMap';
    }
  }

  /// Velocidad media honesta por tipo (bici 15, caballo 6, a pie 4 km/h).
  static double _speedFor(String routeKind) {
    switch (routeKind) {
      case 'bicycle':
      case 'mtb':
        return 15;
      case 'horse':
        return 6;
      default:
        return 4;
    }
  }

  static String _difficultyFor(String sacScale) {
    switch (sacScale.toLowerCase()) {
      case 'hiking':
        return 'facil';
      case 'mountain_hiking':
        return 'media';
      case 'demanding_mountain_hiking':
      case 'alpine_hiking':
      case 'demanding_alpine_hiking':
      case 'difficult_alpine_hiking':
        return 'alta';
      default:
        return 'media';
    }
  }
}
