import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/engines/discovery_engine.dart';
import 'package:party/plans/intent.dart';
import 'package:party/plans/models/models.dart';
import 'package:party/plans/sources/data_source.dart';
import 'package:party/plans/sources/local_fallback_source.dart';

Place _place(String id) => Place(
      id: id,
      title: 'Lugar $id',
      source: 'overpass',
      location: const GeoPoint(37.0, -4.0),
    );

class _FailingPlaceSource implements PlaceSource {
  @override
  Future<List<Place>> fetchAll() async {
    throw StateError('fallo de red simulado');
  }
}

class _WorkingPlaceSource implements PlaceSource {
  @override
  Future<List<Place>> fetchAll() async => [_place('correcto')];
}

class _RetryingPlaceSource implements PlaceSource {
  int attempts = 0;

  @override
  Future<List<Place>> fetchAll() async {
    attempts++;
    if (attempts == 1) throw StateError('fallo transitorio');
    return [_place('reintento-correcto')];
  }
}

class _HangingPlaceSource implements PlaceSource {
  @override
  Future<List<Place>> fetchAll() => Completer<List<Place>>().future;
}

void main() {
  group('DiscoveryEngine: aislamiento de fuentes', () {
    test('una fuente fallida no descarta los resultados de otra', () async {
      final result = await DiscoveryEngine.fromSources(
        placeSources: [
          _FailingPlaceSource(),
          _WorkingPlaceSource(),
        ],
        perSourceTimeout: const Duration(seconds: 1),
        maxRetries: 0,
      ).discover();

      expect(result.places.map((place) => place.id), contains('correcto'));
      expect(result.sourcesResponded, contains('places:_WorkingPlaceSource'));
      expect(result.sourcesFailed.keys, contains('places:_FailingPlaceSource'));
      expect(
        result.sourcesFailed['places:_FailingPlaceSource'],
        contains('fallo de red simulado'),
      );
    });

    test('reintenta una vez y conserva la respuesta posterior', () async {
      final source = _RetryingPlaceSource();
      final result = await DiscoveryEngine.fromSources(
        placeSources: [source],
        perSourceTimeout: const Duration(seconds: 2),
        maxRetries: 1,
      ).discover();

      expect(source.attempts, 2);
      expect(result.places.map((place) => place.id),
          contains('reintento-correcto'));
      expect(result.sourcesResponded, contains('places:_RetryingPlaceSource'));
      expect(result.sourcesFailed, isEmpty);
    });

    test('una fuente que no responde queda acotada por su timeout', () async {
      final result = await DiscoveryEngine.fromSources(
        placeSources: [
          _HangingPlaceSource(),
          _WorkingPlaceSource(),
        ],
        perSourceTimeout: const Duration(milliseconds: 40),
        maxRetries: 0,
      ).discover();

      expect(result.places.map((place) => place.id), contains('correcto'));
      expect(result.sourcesFailed.keys, contains('places:_HangingPlaceSource'));
      expect(
        result.sourcesFailed['places:_HangingPlaceSource'],
        contains('TimeoutException'),
      );
    });
  });

  test('LocalFallbackSource no fabrica lugares ni coordenadas', () async {
    final fallback = LocalFallbackSource(
      lat: 0,
      lng: 0,
      locationLabel: 'Localidad de prueba',
      appetites: const {Appetite.naturaleza},
    );

    expect(await fallback.fetchAll(), isEmpty);
  });
}
