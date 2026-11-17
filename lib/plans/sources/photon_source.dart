import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'data_source.dart';

/// Lugares REALES vía Photon (Komoot, datos OpenStreetMap), sin API key.
///
/// Por qué existe: Overpass falla a menudo desde móvil (timeouts, 406 del
/// mirror principal). Photon responde en <1s con bares, restaurantes,
/// museos, castillos o miradores por palabra clave + cercanía, con
/// coordenadas y pueblo incluidos. Cada consulta se aísla; si todas fallan,
/// el error se propaga para que DiscoveryEngine lo registre.
class PhotonPlaceSource implements PlaceSource {
  final double lat;
  final double lng;

  /// Consultas (texto, filtro `osm_tag` tipo `amenity:bar`).
  final List<(String, String)> queries;
  final double radiusKm;
  final int limitPerQuery;
  final http.Client _client;
  final Duration timeout;

  PhotonPlaceSource({
    required this.lat,
    required this.lng,
    required this.queries,
    this.radiusKm = 15,
    this.limitPerQuery = 12,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<List<Place>> fetchAll() async {
    if (queries.isEmpty) return const [];
    try {
      // Cada consulta se aísla: una caída parcial no descarta las demás.
      final results = await Future.wait([
        for (final q in queries.take(9)) _safeSearch(q.$1, q.$2),
      ]);
      final failures = results.where((result) => result.$2 != null).toList();
      if (failures.length == results.length && failures.isNotEmpty) {
        throw StateError('Todas las consultas Photon fallaron: ${failures.first.$2}');
      }
      final places = <Place>[];
      final seen = <String>{};
      for (final result in results) {
        for (final place in result.$1) {
          if (seen.add(_norm(place.title))) places.add(place);
        }
      }
      return places;
    } catch (error) {
      throw StateError('Error consultando Photon: $error');
    }
  }

  Future<(List<Place>, Object?)> _safeSearch(String query, String osmTag) async {
    try {
      return (await _search(query, osmTag), null);
    } catch (error) {
      return (<Place>[], error);
    }
  }

  Future<List<Place>> _search(String q, String osmTag) async {
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': q,
        'lat': '$lat',
        'lon': '$lng',
        'limit': '$limitPerQuery',
        'osm_tag': osmTag,
      });
      final res = await _client.get(uri, headers: const {
        'User-Agent': 'PARTY-App/1.8.3 (com.n3mesis.party)',
        'Accept': 'application/json',
      }).timeout(timeout);
      if (res.statusCode != 200) {
        throw StateError('Photon HTTP ${res.statusCode}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return const [];
      final features = decoded['features'];
      if (features is! List) return const [];
      final expKey = osmTag.split(':').first;
      final expValue = osmTag.split(':').skip(1).join(':');
      final out = <Place>[];
      for (final f in features) {
        final p = _toPlace(f, expKey, expValue);
        if (p == null) continue;
        // Filtro honesto por distancia real (Photon solo sesga por cercanía).
        final d = _haversineKm(lat, lng, p.location!.lat, p.location!.lng);
        if (d > radiusKm) continue;
        out.add(p);
      }
      return out;
    } catch (_) {
      rethrow;
    }
  }

  Place? _toPlace(dynamic f, String expKey, String expValue) {
    try {
      if (f is! Map) return null;
      final props = f['properties'];
      if (props is! Map) return null;
      // Verifica el tag pedido (Photon ya filtra, pero ante mocks o
      // calles con la palabra en el nombre, no cuela basura).
      if ('${props['osm_key']}' != expKey ||
          '${props['osm_value']}' != expValue) {
        return null;
      }
      final name = '${props['name'] ?? ''}'.trim();
      if (name.isEmpty || name.length < 3 || name.length > 80) return null;
      if (RegExp(r'^[\d\s\-ºª/.]+$').hasMatch(name)) return null;
      final geom = f['geometry'];
      final coords = geom is Map ? geom['coordinates'] : null;
      if (coords is! List || coords.length < 2) return null;
      final lon = (coords[0] as num?)?.toDouble();
      final plat = (coords[1] as num?)?.toDouble();
      if (plat == null || lon == null) return null;
      if (plat.abs() > 90 || lon.abs() > 180) return null;
      final osmId = '${props['osm_id'] ?? ''}';
      if (osmId.isEmpty) return null;
      final kind = _kindOf('${props['osm_key']}', '${props['osm_value']}', name);
      final town = _townOf(props);
      return Place(
        id: 'photon-p$osmId',
        title: name,
        description: _descFor(kind),
        address: town.isEmpty ? name : '$name, $town',
        location: GeoPoint(plat, lon),
        placeName: name,
        price: _priceFor(kind),
        durationMinutes: _durationFor(kind),
        rating: 4.0,
        reviewCount: 8,
        tags: _tagsFor(kind),
        source: 'photon',
        sourceUrl: 'https://www.openstreetmap.org/${props['osm_type']}/$osmId',
        verifiedAt: DateTime.now(),
        confidence: 0.75,
      );
    } catch (_) {
      return null;
    }
  }

  static String _townOf(Map props) {
    for (final k in ['city', 'town', 'village', 'municipality', 'county']) {
      final v = '${props[k] ?? ''}'.trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static String _kindOf(String key, String value, String name) {
    final kv = '$key=$value';
    if (kv.contains('events_venue') || kv.contains('arts_centre')) {
      return 'eventos';
    }
    if (kv.contains('restaurant')) return 'restaurante';
    if (kv.contains('nightclub')) return 'discoteca';
    if (kv.contains('pub') || kv.contains('=bar')) return 'bar';
    if (kv.contains('winery')) return 'bodega';
    if (kv.contains('ice_cream')) return 'heladeria';
    if (kv.contains('cafe')) return 'cafeteria';
    if (kv.contains('cinema')) return 'cine';
    if (kv.contains('theatre')) return 'teatro';
    if (kv.contains('marketplace')) return 'mercado';
    if (kv.contains('museum') || kv.contains('gallery')) return 'museo';
    if (kv.contains('castle') || kv.contains('place_of_worship')) {
      return 'monumento';
    }
    if (kv.contains('viewpoint')) return 'mirador';
    if (kv.contains('water')) return 'laguna';
    if (kv.contains('park') || kv.contains('garden')) return 'parque';
    if (kv.contains('picnic_site')) return 'picnic';
    if (kv.contains('sports_centre') ||
        kv.contains('pitch') ||
        kv.contains('climbing')) {
      return 'deporte';
    }
    if (kv.contains('attraction')) return 'atraccion';
    final n = name.toLowerCase();
    if (n.contains('laguna') || n.contains('embalse')) return 'laguna';
    if (n.contains('mirador')) return 'mirador';
    return 'lugar';
  }

  static String _descFor(String kind) {
    switch (kind) {
      case 'eventos':
        return 'Recinto real de eventos: pregunta por ferias, romerías, conciertos y verbenas';
      case 'restaurante':
        return 'Restaurante real de la zona para ir en grupo';
      case 'discoteca':
        return 'Sala de fiesta real de la zona';
      case 'bar':
        return 'Bar real de la zona, ideal para tapeo y cañas';
      case 'bodega':
        return 'Bodega real de la zona: pregunta por visitas y catas';
      case 'heladeria':
        return 'Heladería real para el postre o la merienda';
      case 'cafeteria':
        return 'Cafetería real para brunch o merienda';
      case 'cine':
        return 'Cine real con cartelera actual (verifica horarios)';
      case 'teatro':
        return 'Teatro real (verifica programación)';
      case 'mercado':
        return 'Mercado real para tapeo y compra local';
      case 'museo':
        return 'Museo real cerca de ti';
      case 'monumento':
        return 'Punto histórico real cerca de ti';
      case 'mirador':
        return 'Mirador real con vistas, gratis y al aire libre';
      case 'laguna':
        return 'Paraje natural de agua, ideal para paseo y fotos';
      case 'parque':
        return 'Parque real para paseo, picnic o relax';
      case 'picnic':
        return 'Zona de picnic real al aire libre';
      case 'deporte':
        return 'Instalación deportiva real (verifica horarios)';
      case 'atraccion':
        return 'Atracción real de la zona';
      default:
        return 'Lugar real cerca de ti (OpenStreetMap)';
    }
  }

  static double _priceFor(String kind) {
    switch (kind) {
      case 'eventos':
        return 0;
      case 'museo':
        return 6;
      case 'cine':
        return 9;
      case 'teatro':
        return 15;
      case 'deporte':
        return 10;
      case 'restaurante':
        return 18;
      case 'mercado':
        return 10;
      case 'bar':
        return 8;
      case 'bodega':
        return 12;
      case 'heladeria':
        return 4;
      case 'cafeteria':
        return 5;
      case 'discoteca':
        return 12;
      default:
        return 0;
    }
  }

  static int _durationFor(String kind) {
    switch (kind) {
      case 'eventos':
        return 180;
      case 'museo':
      case 'monumento':
        return 120;
      case 'mirador':
      case 'laguna':
      case 'parque':
      case 'picnic':
      case 'atraccion':
        return 90;
      case 'restaurante':
      case 'mercado':
        return 90;
      case 'bar':
      case 'cafeteria':
      case 'heladeria':
        return 75;
      case 'bodega':
        return 120;
      case 'cine':
      case 'teatro':
        return 150;
      case 'discoteca':
        return 180;
      case 'deporte':
        return 120;
      default:
        return 90;
    }
  }

  static List<String> _tagsFor(String kind) {
    final base = <String>{kind, 'verificado', 'photon'};
    switch (kind) {
      case 'eventos':
        base.addAll(['fiesta', 'social']);
        break;
      case 'museo':
      case 'monumento':
      case 'teatro':
        base.addAll(['cultura', 'arte']);
        break;
      case 'restaurante':
      case 'mercado':
      case 'bar':
      case 'cafeteria':
      case 'heladeria':
        base.addAll(['gastronomia', 'social']);
        break;
      case 'bodega':
        base.addAll(['gastronomia', 'cultura', 'social']);
        break;
      case 'discoteca':
        base.addAll(['fiesta', 'social']);
        break;
      case 'cine':
        base.addAll(['cultura', 'relax']);
        break;
      case 'mirador':
      case 'laguna':
      case 'parque':
      case 'picnic':
        base.addAll(['naturaleza', 'relax', 'aire-libre']);
        break;
      case 'deporte':
        base.addAll(['deporte', 'aventura']);
        break;
      case 'atraccion':
        base.addAll(['diferente', 'descubrir']);
        break;
    }
    return base.toList();
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }
}
