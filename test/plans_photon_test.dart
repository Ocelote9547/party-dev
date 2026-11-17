import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:party/plans/sources/photon_source.dart';

Map<String, dynamic> _canned() {
  return {
    'features': [
      {
        'geometry': {
          'coordinates': [-4.6736, 37.308],
          'type': 'Point',
        },
        'properties': {
          'osm_id': 111,
          'osm_type': 'N',
          'osm_key': 'amenity',
          'osm_value': 'bar',
          'name': 'Bar los leones',
          'city': 'Badolatosa',
        },
      },
      {
        // Sin nombre: se ignora.
        'geometry': {
          'coordinates': [-4.67, 37.30],
          'type': 'Point',
        },
        'properties': {
          'osm_id': 222,
          'osm_type': 'N',
          'osm_key': 'amenity',
          'osm_value': 'bar',
        },
      },
      {
        // Calle con "bar" en el nombre pero otro osm_key: se filtra por tag.
        'geometry': {
          'coordinates': [-4.67, 37.30],
          'type': 'Point',
        },
        'properties': {
          'osm_id': 333,
          'osm_type': 'W',
          'osm_key': 'highway',
          'osm_value': 'residential',
          'name': 'Calle Barlovento',
        },
      },
    ],
  };
}

void main() {
  group('PhotonPlaceSource', () {
    test('parsea bares reales con pueblo y coords', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode(_canned()),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final src = PhotonPlaceSource(
        lat: 37.41,
        lng: -4.66,
        queries: const [('bar', 'amenity:bar')],
        radiusKm: 35,
        client: client,
      );
      final places = await src.fetchAll();
      expect(places.length, 1);
      final bar = places.first;
      expect(bar.title, 'Bar los leones');
      expect(bar.address, contains('Badolatosa'));
      expect(bar.source, 'photon');
      expect(bar.location!.lat, closeTo(37.308, 0.001));
      expect(bar.tags, contains('gastronomia'));
    });

    test('filtra por radio real (Photon solo sesga)', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode(_canned()),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final src = PhotonPlaceSource(
        lat: 40.41,
        lng: -3.70, // Madrid: lejos de Badolatosa
        queries: const [('bar', 'amenity:bar')],
        radiusKm: 5,
        client: client,
      );
      expect(await src.fetchAll(), isEmpty);
    });

    test('sin consultas devuelve vacío', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final src = PhotonPlaceSource(
        lat: 37.41,
        lng: -4.66,
        queries: const [],
        client: client,
      );
      expect(await src.fetchAll(), isEmpty);
    });

    test('error de red devuelve lista vacía', () async {
      final client = MockClient((_) => throw Exception('sin red'));
      final src = PhotonPlaceSource(
        lat: 37.41,
        lng: -4.66,
        queries: const [('bar', 'amenity:bar')],
        client: client,
      );
      expect(await src.fetchAll(), isEmpty);
    });
  });
}
