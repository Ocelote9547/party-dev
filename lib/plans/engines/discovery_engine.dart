import '../models/models.dart';
import '../sources/data_source.dart';

class _SourceResult {
  final String sourceName;
  final List<dynamic> data;
  final bool success;
  final String? error;
  const _SourceResult({required this.sourceName, required this.data, required this.success, this.error});
}

Future<_SourceResult> _fetchWithRetry(
  String sourceName,
  Future<List<dynamic>> Function() fetch, {
  required Duration timeout,
  required int maxRetries,
  Duration initialDelay = const Duration(milliseconds: 300),
}) async {
  final clock = Stopwatch()..start();
  Object? lastError;
  for (var attempt = 0; attempt <= maxRetries; attempt++) {
    final remaining = timeout - clock.elapsed;
    if (remaining.inMicroseconds <= 0) break;
    try {
      final data = await fetch().timeout(remaining);
      return _SourceResult(sourceName: sourceName, data: data, success: true);
    } catch (error) {
      lastError = error;
      if (attempt >= maxRetries) break;
      final delay = initialDelay * (attempt + 1);
      final timeLeft = timeout - clock.elapsed;
      if (timeLeft.compareTo(delay) <= 0) break;
      await Future<void>.delayed(delay);
    }
  }
  return _SourceResult(
    sourceName: sourceName,
    data: const <dynamic>[],
    success: false,
    error: lastError?.toString() ?? 'Tiempo límite agotado (${timeout.inSeconds}s)',
  );
}

class DiscoveryResult {
  final List<Place> places;
  final List<PlanRoute> routes;
  final List<PlanActivity> activities;
  final List<String> sourcesResponded;
  final Map<String, String> sourcesFailed;

  const DiscoveryResult({
    this.places = const [],
    this.routes = const [],
    this.activities = const [],
    this.sourcesResponded = const [],
    this.sourcesFailed = const {},
  });

  List<Candidate> get allCandidates => [
        ...places,
        ...routes.map((r) {
          final verified = r.source == 'overpass' || r.source == 'curated';
          return Candidate(
            id: r.id,
            type: CandidateType.route,
            title: r.title,
            description: r.description,
            address: r.startPoint.isNotEmpty ? '${r.startPoint} → ${r.endPoint}' : '',
            location: r.centerLat != null && r.centerLng != null
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
        }),
        ...activities.map((a) => Candidate(
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
            )),
      ];
}

/// Agrega fuentes independientes en paralelo. El constructor original se
/// conserva; fromSources permite que la pantalla V2 use todas sus fuentes.
class DiscoveryEngine {
  final PlaceSource places;
  final RouteSource? routes;
  final ActivitySource? activities;
  final List<PlaceSource> _placeSources;
  final List<RouteSource> _routeSources;
  final List<ActivitySource> _activitySources;
  final Duration perSourceTimeout;
  final int maxRetries;

  DiscoveryEngine({
    required this.places,
    RouteSource? routes,
    ActivitySource? activities,
    this.perSourceTimeout = const Duration(seconds: 8),
    this.maxRetries = 1,
  })  : routes = routes,
        activities = activities,
        _placeSources = [places],
        _routeSources = [if (routes != null) routes],
        _activitySources = [if (activities != null) activities];

  factory DiscoveryEngine.fromSources({
    required List<PlaceSource> placeSources,
    List<RouteSource> routeSources = const [],
    List<ActivitySource> activitySources = const [],
    Duration perSourceTimeout = const Duration(seconds: 8),
    int maxRetries = 1,
  }) {
    if (placeSources.isEmpty) {
      throw ArgumentError.value(placeSources, 'placeSources', 'Debe indicarse al menos una fuente de lugares.');
    }
    return DiscoveryEngine._(
      places: placeSources.first,
      routes: routeSources.isEmpty ? null : routeSources.first,
      activities: activitySources.isEmpty ? null : activitySources.first,
      placeSources: List.unmodifiable(placeSources),
      routeSources: List.unmodifiable(routeSources),
      activitySources: List.unmodifiable(activitySources),
      perSourceTimeout: perSourceTimeout,
      maxRetries: maxRetries,
    );
  }

  DiscoveryEngine._({
    required this.places,
    required this.routes,
    required this.activities,
    required List<PlaceSource> placeSources,
    required List<RouteSource> routeSources,
    required List<ActivitySource> activitySources,
    required this.perSourceTimeout,
    required this.maxRetries,
  })  : _placeSources = placeSources,
        _routeSources = routeSources,
        _activitySources = activitySources;

  Future<DiscoveryResult> discover() async {
    final placeTasks = [
      for (final source in _placeSources)
        _fetchWithRetry('places:${source.runtimeType}', source.fetchAll,
            timeout: perSourceTimeout, maxRetries: maxRetries),
    ];
    final routeTasks = [
      for (final source in _routeSources)
        _fetchWithRetry('routes:${source.runtimeType}', source.fetchAll,
            timeout: perSourceTimeout, maxRetries: maxRetries),
    ];
    final activityTasks = [
      for (final source in _activitySources)
        _fetchWithRetry('activities:${source.runtimeType}', source.fetchAll,
            timeout: perSourceTimeout, maxRetries: maxRetries),
    ];

    // Cada tarea está acotada individualmente; no existe un timeout global
    // que pueda descartar resultados correctos de otras fuentes.
    final results = await Future.wait([...placeTasks, ...routeTasks, ...activityTasks]);
    final placeResults = results.take(placeTasks.length);
    final routeResults = results.skip(placeTasks.length).take(routeTasks.length);
    final activityResults = results.skip(placeTasks.length + routeTasks.length);

    final foundPlaces = <Place>[];
    final foundRoutes = <PlanRoute>[];
    final foundActivities = <PlanActivity>[];
    final sourcesResponded = <String>[];
    final sourcesFailed = <String, String>{};

    void record(_SourceResult result) {
      if (result.success) {
        sourcesResponded.add(result.sourceName);
      } else {
        sourcesFailed[result.sourceName] = result.error ?? 'Error desconocido';
      }
    }

    for (final result in placeResults) {
      record(result);
      if (result.success) foundPlaces.addAll(result.data.cast<Place>());
    }
    for (final result in routeResults) {
      record(result);
      if (result.success) foundRoutes.addAll(result.data.cast<PlanRoute>());
    }
    for (final result in activityResults) {
      record(result);
      if (result.success) foundActivities.addAll(result.data.cast<PlanActivity>());
    }

    return DiscoveryResult(
      places: foundPlaces,
      routes: foundRoutes,
      activities: foundActivities,
      sourcesResponded: sourcesResponded,
      sourcesFailed: sourcesFailed,
    );
  }
}
