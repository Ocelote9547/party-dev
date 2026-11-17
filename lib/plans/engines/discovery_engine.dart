import '../models/models.dart';
import '../sources/data_source.dart';

// Motor de descubrimiento (Fase 4): agrega lo que devuelven las fuentes.
// Cada fuente se consulta de forma independiente; el fallo de una no invalida
// las demás. Se registra qué fuentes respondieron y cuáles fallaron para
// que la UI pueda mostrar un estado honesto al usuario.

/// Resultado de una única fuente.
class _SourceResult {
  final String sourceName;
  final List<dynamic> data;
  final bool success;
  final String? error;
  const _SourceResult({
    required this.sourceName,
    required this.data,
    required this.success,
    this.error,
  });
}

/// Ejecuta una fuente con reintentos limitados y espera progresiva.
/// Solo tiene sentido para fuentes de red; las fuentes locales se ejecutan
/// una sola vez.
Future<_SourceResult> _fetchWithRetry(
  String sourceName,
  Future<List<dynamic>> Function() fetch, {
  int maxRetries = 2,
  Duration initialDelay = const Duration(seconds: 2),
}) async {
  Exception? lastError;
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      final data = await fetch();
      return _SourceResult(
        sourceName: sourceName,
        data: data,
        success: true,
      );
    } catch (e) {
      lastError = e is Exception ? e : Exception(e.toString());
      if (attempt < maxRetries) {
        await Future.delayed(initialDelay * (attempt + 1));
      }
    }
  }
  return _SourceResult(
    sourceName: sourceName,
    data: <dynamic>[],
    success: false,
    error: lastError?.toString() ?? 'Error desconocido',
  );
}

/// Ejecuta una fuente sin reintentos (fuentes locales o no críticas).
Future<_SourceResult> _fetchOnce(
  String sourceName,
  Future<List<dynamic>> Function() fetch,
) async {
  try {
    final data = await fetch();
    return _SourceResult(
      sourceName: sourceName,
      data: data,
      success: true,
    );
  } catch (e) {
    return _SourceResult(
      sourceName: sourceName,
      data: <dynamic>[],
      success: false,
      error: (e is Exception ? e : Exception(e.toString())).toString(),
    );
  }
}

/// Resultado agregado del descubrimiento.
class DiscoveryResult {
  final List<Place> places;
  final List<PlanRoute> routes;
  final List<PlanActivity> activities;
  /// Nombres de las fuentes que respondieron con éxito.
  final List<String> sourcesResponded;
  /// Nombres de las fuentes que fallaron, con motivo.
  final Map<String, String> sourcesFailed;

  const DiscoveryResult({
    this.places = const [],
    this.routes = const [],
    this.activities = const [],
    this.sourcesResponded = const [],
    this.sourcesFailed = const {},
  });

  /// Todos los candidatos (lugares + rutas + actividades como [Candidate]).
  List<Candidate> get allCandidates => [
        ...places,
        ...routes.map(
          (r) {
            final verified = r.source == 'overpass' || r.source == 'curated';
            return Candidate(
              id: r.id,
              type: CandidateType.route,
              title: r.title,
              description: r.description,
              address: r.startPoint.isNotEmpty
                  ? '${r.startPoint} → ${r.endPoint}'
                  : '',
              location: (r.centerLat != null && r.centerLng != null)
                  ? GeoPoint(r.centerLat!, r.centerLng!)
                  : null,
              durationMinutes: r.durationMinutes,
              difficulty: r.difficulty,
              rating: verified ? 4.3 : 3.5,
              reviewCount: verified ? 8 : 2,
              tags: const ['ruta', 'senderismo', 'naturaleza', 'aventura'],
              source: r.source,
              sourceUrl: r.sourceUrl,
              verifiedAt: r.verifiedAt,
              confidence: verified ? 0.85 : 0.5,
            );
          },
        ),
        ...activities.map(
          (a) => Candidate(
            id: a.id,
            type: CandidateType.activity,
            title: a.title,
            description: a.description,
            address: a.address,
            location: a.location,
            price: a.price,
            pricePerPerson: a.pricePerPerson,
            durationMinutes: a.durationMinutes,
            source: a.source,
            sourceUrl: a.sourceUrl,
            placeName: a.placeName,
          ),
        ),
      ];
}

/// Motor de descubrimiento (Fase 4): agrega lo que devuelven las fuentes.
class DiscoveryEngine {
  final PlaceSource places;
  final RouteSource? routes;
  final ActivitySource? activities;

  DiscoveryEngine({required this.places, this.routes, this.activities});

  Future<DiscoveryResult> discover() async {
    // Ejecutar cada fuente de forma independiente; el fallo de una no
    // invalida las demás.
    final placesResult = await _fetchOnce(
      'places:${places.runtimeType}',
      places.fetchAll,
    );

    _SourceResult routesResult;
    if (routes != null) {
      routesResult = await _fetchWithRetry(
        'routes:${routes!.runtimeType}',
        routes!.fetchAll,
        maxRetries: 2,
        initialDelay: const Duration(seconds: 2),
      );
    } else {
      routesResult = const _SourceResult(
        sourceName: 'routes:none',
        data: [],
        success: true,
      );
    }

    _SourceResult activitiesResult;
    if (activities != null) {
      activitiesResult = await _fetchOnce(
        'activities:${activities!.runtimeType}',
        activities!.fetchAll,
      );
    } else {
      activitiesResult = const _SourceResult(
        sourceName: 'activities:none',
        data: [],
        success: true,
      );
    }

    final sourcesResponded = <String>[];
    final sourcesFailed = <String, String>{};

    if (placesResult.success) {
      sourcesResponded.add(placesResult.sourceName);
    } else {
      sourcesFailed[placesResult.sourceName] =
          placesResult.error ?? 'error';
    }

    if (routesResult.success) {
      sourcesResponded.add(routesResult.sourceName);
    } else {
      sourcesFailed[routesResult.sourceName] =
          routesResult.error ?? 'error';
    }

    if (activitiesResult.success) {
      sourcesResponded.add(activitiesResult.sourceName);
    } else {
      sourcesFailed[activitiesResult.sourceName] =
          activitiesResult.error ?? 'error';
    }

    return DiscoveryResult(
      places: placesResult.success
          ? (placesResult.data as List<Place>)
          : <Place>[],
      routes: routesResult.success
          ? (routesResult.data as List<PlanRoute>)
          : <PlanRoute>[],
      activities: activitiesResult.success
          ? (activitiesResult.data as List<PlanActivity>)
          : <PlanActivity>[],
      sourcesResponded: sourcesResponded,
      sourcesFailed: sourcesFailed,
    );
  }
}
