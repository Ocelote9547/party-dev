/// Entidad base del motor de planes: todo lo descubrible es un [Candidate].
/// Los datos reales deben venir de fuentes verificables (ver DataSource
/// en fases posteriores); los mocks actuales son solo datos de prueba.
enum CandidateType {
  place,
  route,
  activity,
  event,
  experience,
  restaurant,
  sport,
  viewpoint,
  natureSpot,
  workshop,
  cultural,
}

/// Punto geográfico simple, sin depender de google_maps.
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

class Candidate {
  final String id;
  final CandidateType type;
  final String title;
  final String description;
  final String address;
  final GeoPoint? location;
  final double price; // 0 = gratis
  final bool pricePerPerson;
  final String? openingHours; // ej. "10:00-22:00"
  final double rating; // 0..5
  final int reviewCount;
  final int durationMinutes;
  final String difficulty; // 'facil' | 'media' | 'alta'
  final List<String> tags;
  final String source; // 'mock' o 'api:nombre'
  final String? sourceUrl;
  final DateTime? verifiedAt;
  final double confidence; // 0..1
  final String? photoUrl; // foto real del sitio, null = sin foto
  final String? placeName; // nombre fijo del establecimiento/ruta

  const Candidate({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    this.address = '',
    this.location,
    this.price = 0,
    this.pricePerPerson = true,
    this.openingHours,
    this.rating = 0,
    this.reviewCount = 0,
    this.durationMinutes = 60,
    this.difficulty = 'facil',
    this.tags = const [],
    this.source = 'mock',
    this.sourceUrl,
    this.verifiedAt,
    this.confidence = 0.5,
    this.photoUrl,
    this.placeName,
  });
}
