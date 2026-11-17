import 'dart:convert';

import 'package:http/http.dart' as http;

// Fotos reales vía Wikimedia Commons (gratis, sin clave).
// Si falla (red, timeout, sin resultados), devuelve null y el
// llamador usa fallback picsum.
class PhotoService {
  // Caché en memoria: clave query+coords -> url o null.
  final Map<String, String?> _cache = {};
  final http.Client _client;

  PhotoService({http.Client? client}) : _client = client ?? http.Client();

  // Busca foto: con coords usa geosearch, si no búsqueda por título.
  Future<String?> fetchPhotoUrl({
    required String query,
    double? lat,
    double? lng,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    final key = '${q.toLowerCase()}|${lat?.toStringAsFixed(3)}|'
        '${lng?.toStringAsFixed(3)}';
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final uri = _buildUri(query: q, lat: lat, lng: lng);
      final res = await _client.get(uri).timeout(timeout);
      if (res.statusCode != 200) {
        _cache[key] = null;
        return null;
      }
      final url = _parseFirstThumb(res.body);
      _cache[key] = url;
      return url;
    } catch (_) {
      // Fallo total -> null (el llamador usa fallback).
      _cache[key] = null;
      return null;
    }
  }

  // Construye la URL del API público de Commons.
  Uri _buildUri({required String query, double? lat, double? lng}) {
    const base = {
      'action': 'query',
      'format': 'json',
      'prop': 'pageimages',
      'pithumbsize': '800',
      'pilimit': '5',
      'origin': '*', // CORS para web
    };
    if (lat != null && lng != null) {
      return Uri.https('commons.wikimedia.org', '/w/api.php', {
        ...base,
        'generator': 'geosearch',
        'ggscoord': '$lat|$lng',
        'ggsradius': '5000',
        'ggslimit': '5',
        'ggsnamespace': '6',
      });
    }
    return Uri.https('commons.wikimedia.org', '/w/api.php', {
      ...base,
      'titles': query,
    });
  }

  // Extrae el primer thumbnail http(s) de la respuesta.
  String? _parseFirstThumb(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final pages = (decoded['query'] as Map?)?['pages'];
    if (pages is! Map) return null;
    for (final entry in pages.values) {
      if (entry is! Map) continue;
      final thumb = (entry['thumbnail'] as Map?)?['source'];
      if (thumb is String && thumb.startsWith('http')) return thumb;
    }
    return null;
  }
}
