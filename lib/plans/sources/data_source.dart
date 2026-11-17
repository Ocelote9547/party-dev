import '../models/models.dart';

// Contratos de fuentes de datos (Fase 4).
// Toda fuente real o mock debe implementar estas interfaces.

/// Fuente de lugares visitables.
abstract class PlaceSource {
  Future<List<Place>> fetchAll();
}

/// Fuente de rutas.
abstract class RouteSource {
  Future<List<PlanRoute>> fetchAll();
}

/// Fuente de actividades.
abstract class ActivitySource {
  Future<List<PlanActivity>> fetchAll();
}
