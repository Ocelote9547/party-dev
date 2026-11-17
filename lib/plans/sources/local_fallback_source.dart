import '../intent.dart';
import '../models/models.dart';
import 'data_source.dart';

/// Fallback histórico desactivado.
///
/// Esta fuente fabricaba establecimientos, rutas, precios y coordenadas a
/// partir del nombre de una localidad. Esos datos no se pueden verificar y
/// no deben convertirse en recomendaciones ni mezclarse con fuentes reales.
/// Se conserva la clase para mantener compatibilidad con llamadas antiguas.
class LocalFallbackSource implements PlaceSource {
  final double lat;
  final double lng;
  final String locationLabel;
  final Set<Appetite> appetites;
  final double radiusKm;

  LocalFallbackSource({
    required this.lat,
    required this.lng,
    required this.locationLabel,
    this.appetites = const <Appetite>{Appetite.fiesta},
    this.radiusKm = 50,
  });

  @override
  Future<List<Place>> fetchAll() async => const [];
}
