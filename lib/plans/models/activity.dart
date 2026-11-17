import 'candidate.dart';

/// Actividad realizable (deporte, taller, clase, evento...).
enum ActivityKind {
  sport,
  workshop,
  culture,
  food,
  nature,
  social,
  other,
}

class PlanActivity {
  final String id;
  final String title;
  final String description;
  final ActivityKind kind;
  final int durationMinutes;
  final double price;
  final bool pricePerPerson;
  final String? schedule; // ej. "Sáb 18:00"
  final bool bookingRequired;
  final String source; // 'mock' o 'api:nombre'
  final String? sourceUrl;
  final String address; // sede fija: calle/plaza + ciudad (sin números inventados)
  final GeoPoint? location; // coords aproximadas de la sede
  final String? placeName; // nombre fijo del establecimiento

  const PlanActivity({
    required this.id,
    required this.title,
    this.description = '',
    this.kind = ActivityKind.other,
    this.durationMinutes = 60,
    this.price = 0,
    this.pricePerPerson = true,
    this.schedule,
    this.bookingRequired = false,
    this.source = 'mock',
    this.sourceUrl,
    this.address = '',
    this.location,
    this.placeName,
  });
}
