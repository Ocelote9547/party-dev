import '../models/models.dart';
import 'data_source.dart';

// Esqueleto de fuente real de lugares (FASE 12).
// Solo interfaz: NO hace llamadas HTTP reales.
class ApiPlaceSource implements PlaceSource {
  // Base del API (ej. https://overpass-api.de/api/interpreter).
  final String baseUrl;

  // Clave del proveedor si lo exige (Foursquare, ModelsLab, etc.).
  final String? apiKey;

  const ApiPlaceSource({required this.baseUrl, this.apiKey});

  @override
  Future<List<Place>> fetchAll() {
    // TODO: pegar al endpoint real según proveedor:
    // - Overpass (OSM): POST $baseUrl con query Overpass QL
    //   (node["tourism"](bbox);out;) y mapear tags name/amenity.
    // - Foursquare: GET $baseUrl/places/search con header
    //   Authorization: $apiKey; mapear name, location, categories.
    // - ModelsLab u otro: GET/POST según su doc con ?key=$apiKey.
    // Mapear cada item a Place con `source` = 'api:<nombre>',
    // `verifiedAt` = DateTime.now() y `confidence` 0..1 según
    // cobertura del proveedor. Marcar estimaciones como "Estimado".
    throw UnimplementedError(
      'ApiPlaceSource.fetchAll sin implementar: conectar baseUrl a '
      'Overpass/Foursquare/ModelsLab y mapear a Place.',
    );
  }
}
