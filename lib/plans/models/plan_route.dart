/// Ruta real de naturaleza/ciudad. No inventar rutas de campo:
/// toda ruta recomendada debe existir con inicio, fin, km y desnivel.
class PlanRoute {
  final String id;
  final String title;
  final String description;
  final String startPoint;
  final String endPoint;
  final double distanceKm;
  final int durationMinutes;
  final int elevationGain; // metros
  final String difficulty; // 'facil' | 'media' | 'alta'
  final String surfaceType; // 'sendero' | 'asfalto' | 'carril bici' ...
  final bool circular;
  final bool returnToStart;
  final String accessInfo;
  final double? centerLat;
  final double? centerLng;
  final String source; // 'mock' o 'api:nombre'
  final String? sourceUrl;
  final DateTime? verifiedAt;

  const PlanRoute({
    required this.id,
    required this.title,
    this.description = '',
    this.startPoint = '',
    this.endPoint = '',
    this.distanceKm = 0,
    this.durationMinutes = 60,
    this.elevationGain = 0,
    this.difficulty = 'facil',
    this.surfaceType = 'sendero',
    this.circular = false,
    this.returnToStart = false,
    this.accessInfo = '',
    this.centerLat,
    this.centerLng,
    this.source = 'mock',
    this.sourceUrl,
    this.verifiedAt,
  });
}
