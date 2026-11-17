import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'data_source.dart';

/// Busca eventos y noticias locales reales en internet sin API key.
///
/// Usa motores de búsqueda públicos y RSS para encontrar ferias, romerías,
/// conciertos, mercados y eventos culturales cerca de [lat]/[lng].
/// Cada resultado se convierte en un [Candidate] de tipo `event`.
/// Si falla la red o no hay resultados, devuelve lista vacía. Nunca lanza.
class NewsEventsSource implements PlaceSource {
  final double lat;
  final double lng;
  final double radiusKm;
  final String locationLabel;
  final http.Client _client;
  final Duration timeout;

  NewsEventsSource({
    required this.lat,
    required this.lng,
    this.radiusKm = 50,
    this.locationLabel = '',
    http.Client? client,
    this.timeout = const Duration(seconds: 4),
  }) : _client = client ?? http.Client();

  @override
  Future<List<Place>> fetchAll() async {
    try {
      // Queries de eventos típicos en pueblos y ciudades.
      final queries = [
        'feria romeria eventos $_townName',
        'eventos culturales $_townName',
        'discoteca fiesta halloween $_townName',
        'eventos hoy manana $_townName',
      ];

      final places = <Place>[];
      final seen = <String>{};

      final results = await Future.wait([
        for (final q in queries) _searchWeb(q),
      ]);
      for (final found in results) {
        for (final p in found) {
          if (seen.add(p.title.toLowerCase())) places.add(p);
        }
      }

      return places;
    } catch (_) {
      return const [];
    }
  }

  /// Búsqueda web ligera vía DuckDuckGo HTML (sin clave API).
  Future<List<Place>> _searchWeb(String query) async {
    try {
      final uri = Uri.https('html.duckduckgo.com', '/html/', {
        'q': query,
      });
      final res = await _client.get(uri, headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
        'Accept': 'text/html',
      }).timeout(timeout);
      if (res.statusCode != 200) return const [];
      return _parseDuckDuckGo(res.body);
    } catch (_) {
      return const [];
    }
  }

  List<Place> _parseDuckDuckGo(String html) {
    final places = <Place>[];
    // Extraer resultados de DuckDuckGo con expresiones regulares simples.
    final resultRegex = RegExp(
      r'class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    final matches = resultRegex.allMatches(html);
    for (final m in matches.take(5)) {
      final url = m.group(1) ?? '';
      final titleRaw = m.group(2) ?? '';
      // Quitar etiquetas HTML del título.
      final title = titleRaw.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      if (title.isEmpty || title.length < 5 || title.length > 80) continue;
      // Construir una descripción honesta.
      final description =
          'Evento encontrado en internet: $title. Verifica fecha y horario antes de ir.';
      places.add(Place(
        id: 'news-${_norm(title)}',
        title: title,
        description: description,
        address: 'Consulta en internet',
        location: GeoPoint(lat, lng), // Sin coords precisas, usamos la del usuario
        placeName: title,
        price: 0,
        durationMinutes: 120,
        rating: 3.5,
        reviewCount: 0,
        tags: ['eventos', 'fiesta', 'social', 'internet'],
        source: 'news_events',
        sourceUrl: url.startsWith('http') ? url : 'https://duckduckgo.com/?q=$url',
        verifiedAt: DateTime.now(),
        confidence: 0.4,
      ));
    }
    return places;
  }

  /// Nombre aproximado de la localidad para las queries de búsqueda.
  String get _townName {
    if (locationLabel.trim().isNotEmpty) return locationLabel.trim();
    return 'mi zona';
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .trim();
}
