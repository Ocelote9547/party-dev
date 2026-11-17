import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'data_source.dart';

/// Sitios de interés REALES vía Wikipedia (geosearch), sin API key.
///
/// Cubre lo que OSM a veces no tiene como POI visitable: castillos,
/// lagunas, ermitas, iglesias, museos o yacimientos (p. ej. Laguna de
/// Zóñar, Castillo Anzur). Radio máximo del API: 10 km. Si falla,
/// devuelve lista vacía. Nunca lanza.
class WikipediaPlaceSource implements PlaceSource {
  final double lat;
  final double lng;
  final double radiusKm;
  final http.Client _client;
  final Duration timeout;

  WikipediaPlaceSource({
    required this.lat,
    required this.lng,
    this.radiusKm = 10,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<List<Place>> fetchAll() async {
    try {
      final meters = (radiusKm * 1000).round().clamp(500, 10000);
      final uri = Uri.https('es.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'list': 'geosearch',
        'gscoord': '$lat|$lng',
        'gsradius': '$meters',
        'gslimit': '20',
        'format': 'json',
        'formatversion': '2',
      });
      final res = await _client.get(uri, headers: const {
        'User-Agent': 'PARTY-App/1.8.3 (com.n3mesis.party)',
        'Accept': 'application/json',
      }).timeout(timeout);
      if (res.statusCode != 200) {
        throw StateError('Wikipedia HTTP ${res.statusCode}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return const [];
      final query = decoded['query'];
      final geosearch = query is Map ? query['geosearch'] : null;
      if (geosearch is! List) return const [];
      final places = <Place>[];
      final seen = <String>{};
      for (final g in geosearch) {
        final p = _toPlace(g);
        if (p == null) continue;
        if (!seen.add(p.title.toLowerCase())) continue;
        places.add(p);
        if (places.length >= 12) break;
      }
      return places;
    } catch (error) {
      throw StateError('Error consultando Wikipedia: $error');
    }
  }

  Place? _toPlace(dynamic g) {
    try {
      if (g is! Map) return null;
      final title = '${g['title'] ?? ''}'.trim();
      if (title.isEmpty || title.length < 3 || title.length > 80) return null;
      // Ruido: estaciones, batallas (artículos, no sitios) y anexos.
      final low = title.toLowerCase();
      if (low.startsWith('estación de') ||
          low.startsWith('batalla de') ||
          low.startsWith('anexo:') ||
          low.contains('desambiguación')) {
        return null;
      }
      final plat = (g['lat'] as num?)?.toDouble();
      final plon = (g['lon'] as num?)?.toDouble();
      if (plat == null || plon == null) return null;
      if (plat.abs() > 90 || plon.abs() > 180) return null;
      final pageId = '${g['pageid'] ?? title}';
      final kind = _kindOf(low);
      return Place(
        id: 'wiki-p$pageId',
        title: title,
        description: _descFor(kind),
        address: title,
        location: GeoPoint(plat, plon),
        placeName: title,
        price: kind == 'museo' ? 6.0 : 0.0,
        durationMinutes: _durationFor(kind),
        rating: 4.4,
        reviewCount: 10,
        tags: _tagsFor(kind),
        source: 'wikipedia',
        sourceUrl:
            'https://es.wikipedia.org/wiki/${Uri.encodeComponent(title.replaceAll(' ', '_'))}',
        verifiedAt: DateTime.now(),
        confidence: 0.8,
      );
    } catch (_) {
      return null;
    }
  }

  static String _kindOf(String low) {
    if (low.contains('museo')) return 'museo';
    if (low.contains('castillo') ||
        low.contains('fortaleza') ||
        low.contains('alcazaba') ||
        low.contains('muralla') ||
        low.contains('torre') ||
        low.contains('iglesia') ||
        low.contains('ermita') ||
        low.contains('catedral') ||
        low.contains('parroquia') ||
        low.contains('convento') ||
        low.contains('santuario') ||
        low.contains('monasterio') ||
        low.contains('yacimiento') ||
        low.contains('conjunto arqueológico') ||
        low.contains('necrópolis')) {
      return 'monumento';
    }
    if (low.contains('laguna') ||
        low.contains('embalse') ||
        low.contains('sierra') ||
        low.contains('parque natural') ||
        low.contains('río') ||
        low.contains('cascada') ||
        low.contains('mirador') ||
        low.contains('cueva') ||
        low.contains('gruta')) {
      return 'naturaleza';
    }
    if (low.contains('teatro')) return 'teatro';
    return 'lugar';
  }

  static String _descFor(String kind) {
    switch (kind) {
      case 'museo':
        return 'Museo con artículo en Wikipedia: verifica horarios antes de ir';
      case 'monumento':
        return 'Punto histórico con artículo en Wikipedia, ideal para visitar';
      case 'naturaleza':
        return 'Paraje natural con artículo en Wikipedia: paseo y fotos';
      case 'teatro':
        return 'Teatro histórico (verifica programación)';
      default:
        return 'Sitio de interés cercano con artículo en Wikipedia';
    }
  }

  static int _durationFor(String kind) {
    switch (kind) {
      case 'museo':
      case 'naturaleza':
        return 120;
      case 'monumento':
        return 90;
      case 'teatro':
        return 150;
      default:
        return 60;
    }
  }

  static List<String> _tagsFor(String kind) {
    final base = <String>{kind, 'verificado', 'wikipedia'};
    switch (kind) {
      case 'museo':
        base.addAll(['cultura', 'arte']);
        break;
      case 'monumento':
        base.addAll(['cultura', 'arte', 'historia']);
        break;
      case 'naturaleza':
        base.addAll(['naturaleza', 'relax', 'aire-libre']);
        break;
      case 'teatro':
        base.addAll(['cultura', 'arte']);
        break;
      default:
        base.addAll(['diferente', 'descubrir']);
        break;
    }
    return base.toList();
  }
}
