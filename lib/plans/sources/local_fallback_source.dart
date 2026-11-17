import '../intent.dart';
import '../models/models.dart';
import 'data_source.dart';

/// Genera ideas generales basadas en el nombre de tu localidad.
///
/// Cuando no hay datos reales de OpenStreetMap, Photon, Wikipedia ni
/// Komoot, este generador crea sugerencias genéricas (no lugares
/// verificados) para que la pantalla no quede vacía. Nunca lanza: siempre
/// devuelve al menos una idea.
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
  Future<List<Place>> fetchAll() async {
    // Extraer el nombre del pueblo/ciudad de la etiqueta.
    final town = _townFromLabel(locationLabel);

    final places = <Place>[];

    // 1. Plan gastronómico: bares/restaurantes del pueblo (siempre hay).
    if (appetites.contains(Appetite.gastronomia) ||
        appetites.contains(Appetite.socializar) ||
        appetites.contains(Appetite.fiesta)) {
      places.add(Place(
        id: 'local-bar-$town',
        title: 'Tapeo y cañas en $town',
        description:
            'Recorre los bares y tabernas de $town. Pregunta por las especialidades de la casa y el vino de la zona.',
        address: '$town, centro',
        location: GeoPoint(lat, lng),
        placeName: 'Bares de $town',
        price: 12,
        durationMinutes: 90,
        rating: 4.0,
        reviewCount: 5,
        tags: ['gastronomia', 'social', 'bar', 'local'],
        source: 'local_fallback_idea',
        sourceUrl: 'https://www.google.com/maps/search/?api=1&query=$town+bares',
        verifiedAt: DateTime.now(),
        confidence: 0.6,
        indoor: false,
      ));
    }

    // 2. Plan naturaleza: parques, plazas, rutas de senderismo locales.
    if (appetites.contains(Appetite.naturaleza) ||
        appetites.contains(Appetite.relax) ||
        appetites.contains(Appetite.aventura) ||
        appetites.contains(Appetite.deporte)) {
      places.add(Place(
        id: 'local-naturaleza-$town',
        title: 'Ruta de senderismo por los alrededores de $town',
        description:
            'Camina por los caminos y senderos de los alrededores de $town. Lleva calzado cómodo y agua. Ideal para desconectar.',
        address: 'Caminos rurales de $town',
        location: GeoPoint(lat, lng),
        placeName: 'Senderos de $town',
        price: 0,
        durationMinutes: 120,
        rating: 4.2,
        reviewCount: 8,
        tags: ['naturaleza', 'senderismo', 'aire-libre', 'relaj'],
        source: 'local_fallback_idea',
        sourceUrl:
            'https://www.google.com/maps/search/?api=1&query=$town+senderismo',
        verifiedAt: DateTime.now(),
        confidence: 0.6,
        indoor: false,
        outdoorOnly: true,
      ));
    }

    // 3. Plan cultura: iglesias, ermitas, plazas principales.
    if (appetites.contains(Appetite.cultura) ||
        appetites.contains(Appetite.aprender)) {
      places.add(Place(
        id: 'local-cultura-$town',
        title: 'Visita cultural: plaza y monumentos de $town',
        description:
            'Pasea por la plaza principal de $town, visita la iglesia o ermita local y descubre la historia del pueblo.',
        address: 'Centro histórico, $town',
        location: GeoPoint(lat, lng),
        placeName: 'Centro de $town',
        price: 0,
        durationMinutes: 60,
        rating: 3.8,
        reviewCount: 3,
        tags: ['cultura', 'monumento', 'historia', 'local'],
        source: 'local_fallback_idea',
        sourceUrl:
            'https://www.google.com/maps/search/?api=1&query=$town+monumentos',
        verifiedAt: DateTime.now(),
        confidence: 0.6,
        indoor: false,
      ));
    }

    // 4. Plan eventos: ferias, romerías, mercados locales.
    if (appetites.contains(Appetite.fiesta) ||
        appetites.contains(Appetite.sorpresa) ||
        appetites.contains(Appetite.diferente)) {
      places.add(Place(
        id: 'local-eventos-$town',
        title: 'Ferias y romerías de $town',
        description:
            'Infórmate en el ayuntamiento o bares del pueblo sobre ferias, romerías y verbenas próximas. Pregunta por el calendario festivo.',
        address: 'Ayuntamiento de $town',
        location: GeoPoint(lat, lng),
        placeName: 'Eventos de $town',
        price: 0,
        durationMinutes: 180,
        rating: 3.9,
        reviewCount: 4,
        tags: ['eventos', 'fiesta', 'social', 'local'],
        source: 'local_fallback_idea',
        sourceUrl:
            'https://www.google.com/search?q=ferias+romerías+$town',
        verifiedAt: DateTime.now(),
        confidence: 0.5,
        indoor: false,
      ));
    }

    // 5. Plan relajación: terrazas, merenderos, áreas de picnic.
    if (appetites.contains(Appetite.relax) ||
        appetites.contains(Appetite.bonito)) {
      places.add(Place(
        id: 'local-relax-$town',
        title: 'Merendero y terraza cerca de $town',
        description:
            'Busca un merendero o área de recreo en los alrededores de $town para comer al aire libre y relajarte.',
        address: 'Alrededores de $town',
        location: GeoPoint(lat, lng),
        placeName: 'Merendero de $town',
        price: 8,
        durationMinutes: 90,
        rating: 4.0,
        reviewCount: 6,
        tags: ['relax', 'parque', 'picnic', 'local'],
        source: 'local_fallback_idea',
        sourceUrl:
            'https://www.google.com/maps/search/?api=1&query=$town+merendero',
        verifiedAt: DateTime.now(),
        confidence: 0.6,
        indoor: false,
      ));
    }

    // Si no coincidió ningún apetito, dar al menos un plan general.
    if (places.isEmpty) {
      places.add(Place(
        id: 'local-general-$town',
        title: 'Descubrir $town',
        description:
            'Pasea por $town, descubre sus rincones y pregunta a los lugareños por los mejores sitios para comer y visitar.',
        address: town,
        location: GeoPoint(lat, lng),
        placeName: town,
        price: 0,
        durationMinutes: 90,
        rating: 3.5,
        reviewCount: 2,
        tags: ['local', 'descubrir'],
        source: 'local_fallback_idea',
        sourceUrl:
            'https://www.google.com/maps/search/?api=1&query=$town',
        verifiedAt: DateTime.now(),
        confidence: 0.5,
      ));
    }

    return places;
  }

  String _townFromLabel(String label) {
    // Tomar la primera palabra o la parte antes de la coma.
    final parts = label.split(RegExp(r'[,]'));
    final first = parts.first.trim();
    if (first.isEmpty) return 'tu pueblo';
    final words = first.split(RegExp(r'\s+'));
    // Si es muy largo, tomar las primeras 2-3 palabras.
    if (words.length > 3) return words.take(3).join(' ');
    return first;
  }
}
