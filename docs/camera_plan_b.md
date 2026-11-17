# Plan B — Cámara 108MP real (Xiaomi 108MP + iOS) — Investigación

> Fecha: 2026-09-10 · Proyecto `party` · `camera: ^0.10.6` (lock actual, upgradable a `0.12.1`) · Sin cambios en `pubspec.yaml` ni código, solo informe.

## 1. Resumen ejecutivo

**Ningún plugin Flutter de pub.dev expone hoy foto nativa 108MP 9000×12000 / 12032×9024 sin código nativo custom.** Tanto `camera` (0.10.6/0.12.1) como `camerawesome: ^2.5.0` usan **CameraX (Android) / AVFoundation (iOS)** y resuelven `ResolutionPreset.max/ultraHigh` a la **resolución binned por defecto** (típicamente 4000×3000 ≈12MP u 3840×2160), no al stream `MAXIMUM_RESOLUTION` 108MP. El modo 108MP de Xiaomi requiere `CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION` + `CaptureRequest.SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION` (API 31+) o `cameraId` físico propietario — **no expuesto por ningún wrapper**.

**Recomendación: quedarse en `camera` con upscale actual (2× limitado a 4000px, quality 92, single-encode) para la release actual.** Migrar a `camerawesome` **no desbloquea 108MP** y rompe web. Reservar Plan B real para un plugin nativo propio (MethodChannel Camera2 directo) solo si se justifica coste/OOM.

---

## 2. Contexto actual (`party`)

- `lib/screens/retro_camera_screen.dart:14-24` ya documenta la limitación: `max` → preview 1280×720 y JPEG 1080×1920 (~1 MB) en Xiaomi, no 9000×12000 (~20 MB). Ordena `_cameras` priorizando `name=="0"` y prueba cascada `veryHigh → ultraHigh → max → high → medium` con `imageFormatGroup: jpeg`, `FocusMode.auto`, flash auto. Loguea `previewSize` vs JPEG decodificado.
- Post-proceso `_processImageIsolate` hace upscale máx 4000px (`copyResize` cúbico), `adjustColor` + grano por bloques 4×4, sin HSL, encode único `quality: 92` (nota dice 95, código usa 92). Guardado en `DCIM/PARTY` con `MediaScanner` en Android.
- `pubspec.yaml:43` fija `camera: ^0.10.5+9`, lock `0.10.6`. `flutter pub outdated` indica resolvable `0.12.1`, `camera_android_camerax 0.7.4+7`, `camera_avfoundation 0.10.3`. No usa `camera_android` (Camera2 legacy) sino el endorsed `camera_android_camerax`.
- Comportamiento observado coincide con issues `#78247` y `#93914`: `max` no garantiza sensor nativo, Stream/ImageCapture elige tamaño binned.

## 3. Qué es "108MP real" en Android (Xiaomi)

- Sensor Samsung ISOCELL Bright HMX 108MP (ej. Mi Note 10: 12032×9024). Por defecto el HAL expone **modo binned 12MP (4000×3000)** vía `SCALER_STREAM_CONFIGURATION_MAP`.
- El modo **108MP nativo** vive en **`SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION`** y requiere en cada `CaptureRequest` poner `SENSOR_PIXEL_MODE = SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION` (Android 13 / API 31+). Sin ese flag, aunque elijas `Size` 12032×9024, la sesión falla o cae a binned.
- `SCALER_AVAILABLE_STREAM_CONFIGURATIONS` (viejo) está deprecado; el mapa actual es `StreamConfigurationMap`. Dump típico Xiaomi vía `adb shell dumpsys media.camera` muestra ambos mapas: `DEFAULT` con 4000×3000 max y `MAXIMUM_RESOLUTION` con 12032×9024.
- Algunos OEM (Xiaomi/MIUI) además exponen el 108MP como **cámara física dentro de la cámara lógica** (multi-camera). `CameraManager.getCameraIdList()` lista `0,1,2,3` y `getPhysicalCameraIds()` revela el sensor HM2. Acceder requiere abrir el `physicalId` o usar `OutputConfiguration` multi-resolución — tampoco expuesto por plugins.
- **Coste**: RAW 108MP ≈ 120–150 MB en memoria, JPEG ~18–25 MB, captura lenta (1–2s), alto stall duration, riesgo OOM si haces `img.decodeImage` + `copyResize` en Dart. Requiere flujo nativo sin decode completo.

## 4. Tabla comparativa

| Criterio | `camera: ^0.10.6` (actual) / `^0.12.1` | `camerawesome: ^2.5.0` (solicitado `^2.0`) | `flutter_camera` / wrappers (`native_camera_view`, `fl_camera`, `manual_camera_view`) | Nativo custom (Camera2 directo, Plan B real) |
|---|---|---|---|---|
| **Backend Android** | `camera_android_camerax` (CameraX 1.4.x) desde 0.11; opcional `camera_android` (Camera2). `pub.dev:camera` `0.12.1` usa endorsed camerax. | CameraX 1.4.2 (changelog 2.5.0), kotlin 1.7.10, minSdk 21. | Varía: `fl_camera` CameraX, `native_camera_view` CameraX, `manual_camera_view` Camera2/AVFoundation directo, pero solo `low/medium/high/max`. | Camera2 API directo, sin CameraX. Control total. |
| **Backend iOS** | `camera_avfoundation 0.9.23+2` (resolvable 0.10.3). Captura high quality desde 0.2.2, `highResolutionPhotoEnabled`. | AVFoundation (mismo), UI builtin + filtros live. | AVFoundation similar. | AVFoundation `AVCapturePhotoSettings.isHighResolutionPhotoEnabled` + `maxPhotoDimensions`. |
| **Expone `ultraHigh` real 2160p?** | Sí (`ultraHigh` ≈ 3840×2160) pero trata preset como *target*; si no disponible hace fallback automático. En Xiaomi `ultraHigh`/`max` colapsan a binned 4000×3000 o 1920×1080 según OEM. No garantiza 2160p. | No expone `ResolutionPreset`; elige `targetAspectRatio` / `width` para análisis (ej. `AndroidAnalysisOptions.nv21 width:250`), captura usa mejor resolución CameraX disponible (también binned, no 108MP). | `flutter_camera: ^1.0` depende de `camera` (mismo presets); `native_camera_view` expone `CameraResolutionPreset {low,medium,high,max}` ≈ equivalente. Ninguno 108MP. | Sí, si implementas `SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION` y eliges `Size` de `MAXIMUM_RESOLUTION` map. |
| **Foto nativa 9000×12000 (~108MP) sin upscale** | **No.** `SCALER_STREAM_CONFIGURATION_MAP` usado; `MAXIMUM_RESOLUTION` ignorado. | **No.** Mismo CameraX, no toca `MAXIMUM_RESOLUTION`. | **No.** | **Sí** (única vía). En Xiaomi físico: 12032×9024 ≈108MP; otros 108MP: 9000×12000 (≈108MP 3:4). |
| **Acceso `SCALER_AVAILABLE_STREAM_CONFIGURATIONS` / `cameraId` 108MP** | No expone mapa ni `physicalCameraId`; solo `CameraDescription.name` (ej. "0"). No API para listar `StreamConfigurationMap`. | No expone mapa; `SensorConfig.multiple()` permite multi-cámara beta pero no lista tamaños. | No. | Sí, vía `CameraManager.getCameraCharacteristics(cameraId).get(SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION)` y `getPhysicalCameraIds()`. |
| **Peso APK (estimado delta)** | Base: ~+1.2 MB nativo + transitive (`camera_android_camerax`, `camera_avfoundation`). `pub outdated` sin bloat Dart. | **+3–6 MB**: + `carousel_slider`, `colorfilter_generator`, `rxdart`, `image`, assets. Nativo similar pero UI más pesada. Issue reportado tamaño +~4 MB vs `camera`. | Ligero a medio: `fl_camera` (+ `fl_channel`), `native_camera_view` similar a `camera`; `manual_camera_view` muy ligero (solo `plugin_platform_interface`). | Mínimo Dart, + código Kotlin/Swift propio (~100–200 KB). |
| **Permisos Android** | `CAMERA`; `WRITE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE` auto-mergedeado ≤Android 10 (ya en plugin, removible con `tools:node="remove"`); `RECORD_AUDIO` solo si video con audio; `FOREGROUND_SERVICE_CAMERA` si streaming background en Android 14+. Mismo en `retro_camera_screen.dart:230-538` pide `Permission.camera`, `storage`, `photos`, `manageExternalStorage`. | `CAMERA` + mismos opcionales (`RECORD_AUDIO`, `ACCESS_FINE/COARSE_LOCATION` para EXIF). minSdk 21. `WRITE_EXTERNAL_STORAGE` ya no incluido desde 1.4.0. | `CAMERA` solo (cada plugin declara). | Solo `CAMERA` + lo que declares. |
| **Permisos iOS** | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` en `Info.plist`. | Igual + `NSLocationWhenInUseUsageDescription` si guardas GPS EXIF. | Igual. | Igual. |
| **Compatibilidad Web** | **Sí** (`camera_web 0.3.5+5`): preview vía `getUserMedia`, captura por `<canvas>.drawImage` / `MediaRecorder`. Limitaciones: sin `Exposure/Focus`, sin `ImageFormatGroup`, sin streaming frames, resolución map a `Size` fijo, requiere HTTPS. | **No** (Android+iOS only). `pub.dev/camerawesome` no lista `web`. Migrar rompe `flutter build web`. | `flutter_camera: ^1.0` lista web (porque envuelve `camera`), resto no. | No (solo Android). |
| **Fallback web si migra** | N/A | Requiere `conditional import` / `kIsWeb` o flavor: `camera` para web + `camerawesome` para mobile. Añade complejidad y dos UIs. | Sí si el wrapper lo soporta, si no igual que camerawesome. | Necesita fallback web a `camera` o `camera_web`. |
| **Madurez / soporte** | Verificado `flutter.dev`, 2.5k likes, 560k descargas, null-safety, WASM (`package:web`). Activo, última 2026-07-13. | Verificado `apparence.io`, 1.1k likes, 25k descargas, última 2025-06-13 (15 meses sin release, CameraX 1.4.2). Más filtros/UI pero menos activo. | Diverso, poca tracción (`flutter_camera` 25 likes, archivado 2023; `native_camera_view` beta; `manual_camera_view` 21 descargas). Riesgo mantenimiento. | Tú mantienes; depende de ti. |
| **Esfuerzo integración** | Nulo (actual). Upgrade a `0.12.1` trivial. | Medio-alto: reescribir `retro_camera_screen.dart` a `CameraAwesomeBuilder.awesome/custom`, nuevo flujo `SaveConfig`, `onMediaCaptureEvent`, permisos distintos, break web. | Medio (cambio API). | Alto: Kotlin + Swift, manejo lifecycle, orientación, stall, OOM, permisos, MediaStore. |

## 5. Análisis por opción

### 5.1 `camera: ^0.10.6` (actual) y `^0.12.1`

- **Pros:** Soporta **Android+iOS+Web** (único de la lista). API estable, endorsed, `flutter analyze` limpio actual. Upscale controlado a 4000px evita OOM; `veryHigh/ultraHigh/max` cascade ya maximiza lo que el HAL binned permite. `camera_android_camerax` limita a casos concurrentes CameraX pero para foto única es suficiente. Upgrade a `0.12.1` trae fix de dispose al cambiar `CameraDescription` (tu `_switchLens` lo hace manual).
- **Contras:** No hay 108MP nativo. `max` no es "máxima del sensor" sino "máxima del mapa DEFAULT". Sin `SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION` no hay 12032×9024. iOS sí da alta calidad pero en iPhone 48MP (no 108MP) también binned a 12/24MP salvo que pidas `maxPhotoDimensions`.
- **Verificación:** `resolution_preset.dart:7-27` docs: *"A preset is treated as a target resolution, and exact values are not guaranteed. Platform implementations may fall back"*. `camera_web` `mapResolutionPresetToSize` solo mapea a `Size` fijo (ej. `max` → 1920×1080 en web). No hay lista de `SCALER_STREAM_CONFIGURATION_MAP`.

### 5.2 `camerawesome: ^2.0` → `2.5.0`

- **Pros:** UI built-in muy completa (filtros live, `AnalysisConfig`, `SensorConfig.multiple`, zoom, flash, `SaveConfig.photoAndVideo`). Si quisieras filtros Kodak en preview (hoy tu `_KodakOverlay` es solo viñeteado + sello), camerawesome trae `AwesomeFilter.*`. Gestión permisos integrada.
- **Contras:** **No desbloquea 108MP** (misma CameraX). Peor para tu caso: **sin soporte web** → rompe `party` web. Añade dependencias pesadas (`carousel_slider ^5.0`, `rxdart`, `colorfilter_generator`) → +APK, más conflictos de versiones (ej. `playServicesLocationVersion`). Última pub 2025-06-13, 15 meses sin update vs `camera` 6 días. Reescribir ~1100 líneas de `retro_camera_screen.dart` + perder control fino de `DCIM/PARTY` + `MediaScanner` (camerawesome guarda en cache y tú gestionas `pathBuilder`).
- **108MP:** Revisado `pub.dev/camerawesome` + GitHub `Apparence-io/CamerAwesome` — no menciona `SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION`, ni `SENSOR_PIXEL_MODE`, ni selección de `Size` custom para captura. `selectDefaultSize` solo en v0.3.3 antigua; en v2 se delega a CameraX.

### 5.3 `flutter_camera` / `native` / otros wrappers

- `flutter_camera: ^1.0` — wrapper fino sobre `camera`, sin ventaja (25 likes, 2023-08-14, licencia unknown, ya desactualizado).
- `native_camera_view` — propone `previewPreset` / `capturePreset` + `captureMode: maximizeQuality` (HDR), WYSIWYG crop, pero presets siguen siendo `max` binned. Código cerrado reciente, 91 descargas, sin mapa 108MP.
- `fl_camera` (CameraX) / `manual_camera_view` (bytes JPEG) — útil si quieres bytes en memoria, pero tampoco expone 108MP.
- Conclusión: **ninguno resuelve el requisito sin fork nativo**.

### 5.4 Nativo custom (único Plan B real 108MP)

- **Cómo sería:** `MethodChannel('com.n3mesis.party/camera108')` que en Android: `CameraManager -> characteristics.get(SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION) -> getOutputSizes(ImageFormat.JPEG)` lista 12032×9024; crea `ImageReader` a ese tamaño; `CaptureRequest.Builder` con `SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION`; captura; guarda en `MediaStore` (Android 10+) o `DCIM/PARTY`. En iOS: `AVCaptureDevice.maxPhotoDimensions` + `isHighResolutionPhotoEnabled`.
- **Riesgos:** Captura 108MP bloquea preview (stall >1s), memoria ≈120 MB → OOM en isolates Dart si decodificas con `package:image`. Debes evitar `img.decodeImage` para 108MP; guarda directo y solo decodifica thumbnail. Requiere `minSdk` 21 pero `MAXIMUM_RESOLUTION` solo API 31+ (fallback binned en <31). Xiaomi MIUI a veces limita 108MP a app stock; test `adb` en dispositivo real imprescindible.
- **Cuándo hacerlo:** Solo si métrica de negocio exige foto imprimible 9000×12000 y aceptas coste: +~2 semanas dev, +tests en Xiaomi real, +manejo OOM, +permiso `MANAGE_EXTERNAL_STORAGE` ya pedido.

## 6. Peso APK, permisos y web — síntesis

- **Peso:** `camera` < `camerawesome`. Medido indirecto: `camerawesome` arrastra `carousel_slider`, `rxdart`, `collection`, `colorfilter_generator`, `image` en Dart + mismo CameraX nativo + UI overlay → delta estimado **+3–6 MB** APK release (más si habilitas `AnalysisConfig` con MLKit). Para `party` (ya usa `image: ^4.9.2`) el delta neto es menor (~+2–3 MB) pero sigue.
- **Permisos:** Equivalentes. Tu código ya pide `camera`, `storage`, `photos`, `manageExternalStorage` — con `camera` o `camerawesome` igual. `camerawesome` doc pide además `RECORD_AUDIO` y `ACCESS_FINE_LOCATION` opcionales; no añade `MANAGE_EXTERNAL_STORAGE`.
- **Web:** `camera` **sí** (web), `camerawesome` **no**. Si migras, propone fallback:
  ```dart
  // conditional import
  import 'camera_mobile.dart' if (dart.library.html) 'camera_web_fallback.dart';
  // o runtime
  if (kIsWeb) return CameraPreview(controller); // camera
  else return CameraAwesomeBuilder.awesome(...);
  ```
  Duplica UI/QA. Recomendado: mantener `camera` único si web es target (tu `pubspec.yaml` incluye `web/`).

## 7. Recomendación

**Quedarse en `camera` con upscale (opción A).** Justificación:

1. **0% ganancia 108MP migrando** a `camerawesome`/`flutter_camera`; mismo techo binned.
2. **Mantiene web** sin bifurcar código.
3. **Upscale actual (4000px, cúbico, quality 92) es el compromiso correcto**: simula "108MP" perceptivo sin OOM ni stall; tu límite `width<2500 && width!=2160` evita 4320 y `desired.clamp(4000)` evita 9000 que crashea.
4. **Menor riesgo**: `camera 0.12.1` está a 1 salto (`flutter pub upgrade --major-versions`); `camerawesome` exige rewrite y sube deuda.
5. **Plan B real solo si lo pide producto**: implementar plugin nativo Camera2 `MAXIMUM_RESOLUTION` detrás de feature flag, con `kIsWeb` fallback a `camera` y con test en Xiaomi 108MP físico (Redmi Note 11 Pro, Mi Note 10, etc.) validando `12032×9024` real.

**Si pese a esto se quiere explorar `camerawesome`:**

- Crear branch `experiment/camerawesome`, `flutter pub add camerawesome: ^2.5.0`, reescribir `retro_camera_screen.dart` a `CameraAwesomeBuilder.custom`, medir APK (`flutter build apk --analyze-size`) y comparar foto `Exif` vs `camera` en mismo dispositivo. Mantener `camera` para web vía `conditional import`.

## 8. Próximos pasos (sin tocar código aún)

- [ ] Validar en Xiaomi real el mapa: `adb shell dumpsys media.camera | grep -A 20 STREAM_CONFIGURATION_MAP` + app debug que loguee `characteristics.get(SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION)` vía channel temporal.
- [ ] Medir `flutter build apk --analyze-size` actual vs con `camerawesome` en branch desechable.
- [ ] Si se aprueba Plan B nativo: diseñar `MethodChannel` + `ImageReader` 108MP + `SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION`, con fallback a binned y sin `img.decode` en Dart para 108MP.

## 9. Referencias verificadas

- `pub.dev/packages/camera` 0.12.1 (flutter.dev, 6 días, SDK Flutter, Android/iOS/web, `camera_android_camerax ^0.7.4`, `camera_avfoundation ^0.10.2`, `camera_web ^0.3.3`) — webfetch 2026-09-10.
- `camera_platform_interface/lib/src/types/resolution_preset.dart` — enum `low,medium,high,veryHigh (~1080p),ultraHigh (~2160p),max` como *target*, fallback.
- `pub.dev/packages/camerawesome` 2.5.0 (apparence.io, 2025-06-13, Android/iOS only, CameraX 1.4.2, minSdk 21, deps `carousel_slider`, `rxdart`, `image`) — webfetch.
- `pub.dev/packages/camera_android_camerax` 0.7.4+7 — limitaciones CameraX, permisos, `WRITE_EXTERNAL_STORAGE`.
- `SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION` + `SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION` (API 31) — `CameraCharacteristics` docs + AOSP `OutputConfiguration`, `CameraConstrainedHighSpeedCaptureSessionImpl`.
- `pub.dev/packages/camera_web` 0.3.5+5 — web vía `getUserMedia`, sin `Exposure/Focus`, `mapResolutionPresetToSize`.
- Xiaomi Mi Note 10 108MP 12032×9024 (xiaomi.com), Redmi Note 11 Pro 108MP specs — confirm sensor 108MP binned.
- Issues `flutter/flutter#78247`, `#93914` — `max` no da resolución nativa, image stream limitado a 720p.
- Código local `retro_camera_screen.dart`, `pubspec.yaml`, `flutter pub outdated`, `flutter analyze` (No issues found).

> **Nota:** No se modificó `pubspec.yaml` ni código. Solo se creó `docs/camera_plan_b.md`. `flutter analyze` sigue limpio (verificado 2026-09-10).
