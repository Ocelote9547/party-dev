import 'candidate.dart';

/// Lugar visitable (restaurante, museo, mirador, etc.).
class Place extends Candidate {
  final bool needsBooking;
  /// Si el lugar es de interior (restaurante, museo, cine...).
  final bool indoor;
  /// Si es solo de exterior (mirador, laguna, parque...).
  final bool outdoorOnly;

  const Place({
    required super.id,
    super.type = CandidateType.place,
    required super.title,
    super.description = '',
    super.address = '',
    super.location,
    super.price = 0,
    super.pricePerPerson = true,
    super.openingHours,
    super.rating = 0,
    super.reviewCount = 0,
    super.durationMinutes = 60,
    super.difficulty = 'facil',
    super.tags = const [],
    super.source = 'mock',
    super.sourceUrl,
    super.verifiedAt,
    super.confidence = 0.5,
    super.photoUrl,
    super.placeName,
    this.needsBooking = false,
    this.indoor = false,
    this.outdoorOnly = false,
  });

  /// Si el lugar es de interior o exterior (para scoring con el tiempo).
  bool get isIndoor => indoor;
  bool get isOutdoorOnly => outdoorOnly;
}
