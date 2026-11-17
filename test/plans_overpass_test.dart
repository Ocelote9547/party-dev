import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:party/plans/sources/overpass_source.dart';

Map<String, dynamic> _cannedResponse() {
  return {
    'elements': [
      {
        'type': 'relation',
        'id': 12345,
        'tags': {
          'name': 'Senda del Genaro',
          'distance': '12,5',
          'sac_scale': 'mountain_hiking',
          'from': 'Cercedilla',
          'to': 'Navacerrada',
          'roundtrip': 'no',
        },
        'center': {'lat': 40.74, 'lon': -4.0},
      },
      {
        'type': 'relation',
        'id': 67890,
        'tags': {'name': 'Paseo del Río'},
        'center': {'lat': 40.4, 'lon': -3.7},
      },
      {
        'type': 'node', // se ignora: no es relation
        'id': 111,
        'tags': {'name': 'No es ruta'},
      },
      {
        'type': 'relation',
        'id': 22222,
        'tags': {}, // sin nombre: se ignora
      },
    ],
  };
}

void main() {
  group('OverpassRouteSource', () {
    test('parsea rutas reales con distancia y dificultad', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode(_cannedResponse()),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final src = OverpassRouteSource(lat: 40.4, lng: -3.7, client: client);
      final routes = await src.fetchAll();
      expect(routes.length, 2);

      final first = routes.firstWhere((r) => r.id == 'overpass-r12345');
      expect(first.title, 'Senda del Genaro');
      expect(first.distanceKm, 12.5);
      expect(first.difficulty, 'media');
      expect(first.startPoint, 'Cercedilla');
      expect(first.endPoint, 'Navacerrada');
      expect(first.centerLat, 40.74);
      expect(first.source, 'overpass');
      expect(first.sourceUrl, contains('12345'));

      final second = routes.firstWhere((r) => r.id == 'overpass-r67890');
      expect(second.distanceKm, 0); // sin dato: no se inventa
      expect(second.durationMinutes, 90);
    });

    test('error de red devuelve lista vacía', () async {
      final client = MockClient((_) => throw Exception('sin red'));
      final src = OverpassRouteSource(lat: 40.4, lng: -3.7, client: client);
      expect(await src.fetchAll(), isEmpty);
    });

    test('JSON inválido devuelve lista vacía', () async {
      final client =
          MockClient((_) async => http.Response('no-json{{{', 200));
      final src = OverpassRouteSource(lat: 40.4, lng: -3.7, client: client);
      expect(await src.fetchAll(), isEmpty);
    });

    test('status distinto de 200 devuelve lista vacía', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final src = OverpassRouteSource(lat: 40.4, lng: -3.7, client: client);
      expect(await src.fetchAll(), isEmpty);
    });
  });
}
