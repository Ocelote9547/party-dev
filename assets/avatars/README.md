# Mis fotos IA — specs para `assets/avatars/`

Caras base por imagen para el editor de avatares (`AvatarData.assetPath`).

## Formato esperado
- **Tipo:** PNG con canal alfa (fondo transparente).
- **Tamaño:** cuadrado **512x512 px** (mínimo 256, máximo 1024; se muestra con `ClipOval` + `BoxFit.cover`).
- **Encuadre:** vista frontal, cara centrada, margen ~10% alrededor.
- **Fondo:** transparente (sin fondo blanco/negro; el círculo degradado lo pone la app).
- **Peso:** < 300 KB por imagen si es posible (usa compresión PNG).

## Nombres
- Slots del catálogo: `custom_01.png`, `custom_02.png`, ... `custom_12.png`.
- Slots dorados premium (Pack Dorado, se compran aparte): `custom_13.png`
  (Héroe Dorado) y `custom_14.png` (Leyenda Dorada). Estilo dorado/metalizado.
- También vale cualquier otro `*.png|*.jpg` en esta carpeta: la sección
  "Mis fotos IA" del editor lista todo lo que encuentre vía `AssetManifest`.
- Nombres en minúsculas, sin espacios ni tildes.

## Cómo añadirlas
1. Copia tus PNG generados con IA a `assets/avatars/`.
2. Ejecuta `flutter pub get` (la carpeta ya está declarada en `pubspec.yaml`).
3. Abre el editor de avatar → sección "Mis fotos IA" → elige tu foto.
4. Si la carpeta está vacía verás: "Añade tus PNG a assets/avatars/".

## Fallback
Si un slot `custom_XX` no tiene archivo, la app usa el vectorial actual
automáticamente (nunca crashea: `Image.asset` con `errorBuilder` → vectorial).
