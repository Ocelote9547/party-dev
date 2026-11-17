# Fuentes reales de planes (FASE 12)

Cómo añadir un proveedor real sin llamadas de mentira.

## 1. Implementar `PlaceSource`

```dart
import 'package:party/plans/models/models.dart';
import 'package:party/plans/sources/data_source.dart';

class MiProveedorSource implements PlaceSource {
  @override
  Future<List<Place>> fetchAll() async {
    // 1. Llamar al endpoint real (http).
    // 2. Mapear cada item a Place (ver abajo).
    // 3. Devolver la lista.
    throw UnimplementedError();
  }
}
```

Ver esqueleto en `lib/plans/sources/real_source.dart` (`ApiPlaceSource`).

## 2. Mapear a `Place`

- `source`: `'api:<nombre>'` (ej. `'api:overpass'`). Nunca `'mock'`.
- `verifiedAt`: `DateTime.now()` al mapear (cuándo se verificó).
- `confidence`: `0..1` según cobertura (campos faltantes bajan el valor).
- Proveedores típicos: Overpass (OSM), Foursquare, ModelsLab.

## 3. Marcar estimaciones

- Si precio/horario/duración son aproximados, indicarlo en
  `description` con la palabra "Estimado".
- No inventar `rating`/`reviewCount`: usar `0` si el proveedor no los da.
