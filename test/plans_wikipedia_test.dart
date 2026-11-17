import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:party/plans/sources/wikipedia_source.dart';

Map<String, dynamic> _canned() {
  return {
    'query': {
      'geosearch': [
        {
          'pageid': 1,
          'title': 'Laguna de Zóñar',
          'lat': 37.48,
          'lon': -4.69,
          'dist': 8474,
        },
        {
          'pageid': 2,
          'title': 'Castillo Anzur',
          'lat': 37.38,
          'lon': -4.70,
          'dist': 4888,
        },
        {
          // Artículo, no sitio: se ignora.
          'pageid': 3,
          'title': 'Batalla de Arnisol',
          'lat': 37.38,
          'lon': -4.70,
          'dist': 4888,
        },
        {
          // Estación: ruido, se ignora.
          'pageid': 4,
          'title': 'Estación de Puente Genil',
          'lat': 37.39,
          'lon': -4.75,
          'dist': 8355,
        },
      ],
    },
  };
}

void main() {
  group('WikipediaPlaceSource', () {
    test('lagunas y castillos con enlace verificable', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode(_canned()),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final src = WikipediaPlaceSource(
        lat: 37.41,
        lng: -4.66,
        client: client,
      );
      final places = await src.fetchAll();
      expect(places.length, 2);

      final laguna = places.firstWhere((p) => p.title == 'Laguna de Zóñar');
      expect(laguna.tags, contains('naturaleza'));
      expect(laguna.source, 'wikipedia');
      expect(laguna.sourceUrl, contains('wikipedia.org'));

      final castillo =
          places.firstWhere((p) => p.title == 'Castillo Anzur');
      expect(castillo.tags, contains('cultura'));
    });

    test('error de red devuelve lista vacía', () async {
      final client = MockClient((_) => throw Exception('sin red'));
      final src = WikipediaPlaceSource(
        lat: 37.41,
        lng: -4.66,
        client: client,
      );
      expect(await src.fetchAll(), isEmpty);
    });
  });
}
