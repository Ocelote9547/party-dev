// Ubicación aproximada del usuario (barrio/ciudad o texto manual).
class UserLocation {
  final String label; // ej. "Malasaña, Madrid" o texto manual
  final double? lat;
  final double? lng; // null = solo texto manual
  final bool approximate; // true = barrio/ciudad, no GPS exacto
  const UserLocation(
      {required this.label, this.lat, this.lng, this.approximate = true});
}
