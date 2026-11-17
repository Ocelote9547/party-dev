# 🎉 PARTY — Juegos y Planes para Grupos

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/version-1.8.3+19-orange)](https://github.com/n3mesis/party)
[![License](https://img.shields.io/badge/license-Private-red)](https://github.com/n3mesis/party)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web-green)](https://github.com/n3mesis/party)

> La app móvil para grupos que convierte cualquier reunión en una fiesta inolvidable. Juegos, planes reales, cámara retro, economía de avatares y un creador de planes inteligente — todo en español, offline y sin anuncios.

---

## 📱 Características

### 🎮 Juegos para grupos (14+ juegos)

| Juego | Descripción |
|---|---|
| **Tabú** | Describe sin decir las palabras prohibidas, con tilt, cronómetro y puntuación |
| **¿Quién soy?** | Pon el móvil en la frente y adivina el personaje |
| **Adivina** | Categorías masivas con 16×100 palabras |
| **Impostor** | Descubre quién no conoce la palabra secreta |
| **Bomba** | Desactiva la bomba antes de que explote |
| **Dibuja y adivina** | Canvas optimizado con galería de dibujos PNG |
| **Verdad o reto** | 190+ cartas + 80 picantes |
| **Debate** | 102 temas + picantes + profundas |
| **Dos palabras** | Encuentra la conexión entre dos palabras |
| **Es un 10** | Carta de póker con frases de ejemplo |
| **Mímica** | Palabras ocultas solo para el actor |
| **Pueblo duerme** | Lobos, vidente, cupido, ladrón (6 roles con 2-3 lobos) |
| **Ensalada** | 80 platos para adivinar |
| **Yo nunca / Yo tengo un amigo / Yo nunca equipos** | Clásicos de fiesta |
| **Apt coreano** | Retos con ritmo |
| **Ángeles y demonios** | Sistema persistente con servicio dedicado |

**Controles inteligentes:** tilt con calibración, EMA, histéresis y sensibilidad (Suave/Normal/Firme). Fallback con deslizar, botones y flechas ↑↓ W/S. Orientación automática y restauración al salir.

### 📸 Cámara Retro KODAK
- Filtro Kodak Lightroom + HDR + grano real en isolate
- Upscale IA ×2/×3 con toggle
- Sello de fecha quemado
- Lente principal forzada, preview 9:16/4:3 vertical
- Guardado en DCIM/PARTY con MediaScanner

### 🗺️ Creador de Planes Inteligente (V2)
- **Preguntas fullscreen** con selector visual
- **Ubicación real**: GPS exacto o aproximado, o escribe tu pueblo
- **Autocompletado real** de pueblos y ciudades (Nominatim/OpenStreetMap)
- **6 fuentes de datos en paralelo**: OpenStreetMap, Photon (Komoot), Wikipedia, noticias web, rutas Komoot, planes locales
- **Rutas reales de Komoot**: senderismo, BTT, ciclismo con distancia, duración y desnivel
- **Costes honestos**: actividad + transporte (por distancia y medio) + comida (por duración)
- **Tiempo meteorológico** integrado (Open-Meteo)
- **Horario de apertura**: filtra sitios cerrados en la hora prevista
- **Deck Tinder**: arrastra, guarda, descarta — sin repetir planes

### 💰 Economía, Avatares y Tienda
- **13 juegos desbloqueados** gratis + 5 premium
- **Monedas**: 100 iniciales, +10 por partida completada
- **Tienda**: cosméticos masivos + avatar dorado (150 monedas)
- **Avatares**: 12 vectoriales + 14 slots custom (2 dorados exclusivos)
- **Códigos creador** (12 caracteres) con bóveda maestro

### 🔊 Sonido y Vibración
- Tonos reales en memoria (tick 1200Hz, success acorde, fail descendente)
- Ambiente por categoría con fades y volumen 8-15%
- Autoplay web con resume en primer tap
- Pausa en background

### 🎨 Tema Volcán B
- PartyColors dinámicos desde themeNotifier
- Material 3 con google_fonts
- AnimatedPartyBackground con wipe B/N→color solo en juego

---

## 🛠️ Stack técnico

| Tecnología | Uso |
|---|---|
| **Flutter 3.13+** / **Dart 3.13+** | Framework principal |
| **sensors_plus** ^7.1.0 | Tilt con calibración |
| **camera** ^0.10.5+9 | Cámara retro KODAK |
| **geolocator** ^12.0.0 | GPS exacto/aproximado |
| **geocoding** ^5.0.0 | Autocompletado de pueblos |
| **http** ^1.6.0 | APIs (Overpass, Photon, Wikipedia, Komoot, Open-Meteo, DuckDuckGo) |
| **audioplayers** ^6.1.0 | Música ambiente y efectos |
| **vibration** ^3.2.1 | Feedback háptico |
| **permission_handler** ^11.3.1 | Permisos CAMERA/storage/ubicación |
| **path_provider** ^2.1.5 | Directorios de almacenamiento |
| **image** ^4.9.2 | Procesamiento de imágenes en isolate |
| **google_fonts** ^8.2.1 | Tipografía |
| **shared_preferences** ^2.5.5 | Persistencia local |
| **swipable_stack** ^2.0.0 | Deck de planes |

---

## 📂 Estructura del proyecto

```
lib/
├── data/              # game_data.dart, game_config.dart, event_cards.dart
├── games/             # 14+ juegos (adivina, tabu, quien_soy, etc.)
├── models/            # avatar.dart
├── plans/             # Creador de planes V2
│   ├── engines/       # discovery, validation, scoring, plan_generator, intent
│   ├── models/        # place, plan, candidate, cost, activity, plan_route
│   ├── services/      # weather_service, saved_plans_service
│   ├── sources/       # overpass, photon, wikipedia, komoot, news_events, local_fallback, mock, curated
│   ├── validators/    # time, budget, transport, availability
│   ├── intent.dart    # UserIntent, enums, extensiones
│   ├── geocoding_service.dart
│   ├── location_service.dart
│   └── plan_creator_v2_screen.dart
├── screens/           # main_shell, home, games, players, extras, settings, etc.
├── services/          # sound, economy, avatar, feedback, tilt, streak, chaos, angeles
├── theme/             # party_theme, theme_notifier
├── widgets/           # bottom_navigation, game_instructions, animated_party_background, etc.
└── main.dart
```

---

## 🚀 Cómo ejecutar

```bash
# Clonar el repositorio
git clone https://github.com/n3mesis/party.git
cd party

# Instalar dependencias
flutter pub get

# Ejecutar en debug
flutter run

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release

# Compilar web
flutter build web
```

---

## 🧪 Tests

```bash
# Todos los tests
flutter test

# Tests específicos
flutter test test/plans_generator_test.dart
flutter test test/plans_photon_test.dart
flutter test test/plans_wikipedia_test.dart
flutter test test/widget_test.dart
flutter test test/repro_errors_test.dart
```

**99+ tests verdes** cubriendo: generación de planes, scoring, validación, ubicación, Overpass, Photon, Wikipedia, fotos, personalización, y smoke tests de todos los juegos.

---

## 📋 Ficha técnica

| Campo | Valor |
|---|---|
| **Nombre** | PARTY |
| **Package** | com.n3mesis.party |
| **Versión** | 1.8.3+19 |
| **Plataformas** | Android, iOS, Web |
| **SDK** | Flutter 3.13+ / Dart 3.13+ |
| **compileSdk** | 36 |
| **targetSdk** | 36 |
| **minSdk** | flutter.minSdkVersion |
| **Análisis** | `flutter analyze`: No issues found |
| **Tests** | 99+ verdes |

---

## 🔗 APIs y servicios externos (todos gratuitos, sin clave API)

| Servicio | Uso |
|---|---|
| **OpenStreetMap / Overpass** | Lugares, rutas, eventos |
| **Photon (Komoot)** | Bares, restaurantes, POIs rápidos |
| **Wikipedia** | Castillos, lagunas, monumentos |
| **Komoot Tours API** | Rutas reales de senderismo/BTT |
| **Open-Meteo** | Pronóstico del tiempo |
| **Nominatim** | Geocodificación y autocompletado |
| **DuckDuckGo HTML** | Búsqueda de eventos locales |

---

## 📄 Licencia

Proyecto privado. No publicado en pub.dev.

---

## 👨‍💻 Desarrollado con

- **Flutter** + **Dart**
- **Material 3** con tema Volcán B
- **Sin anuncios** · **Sin suscripciones** · **Sin tracking**
- **Datos locales** (SharedPreferences + path_provider)

> *"La app móvil para grupos que convierte cualquier reunión en una fiesta inolvidable."* 🎉

---

**Autor:** n3mesis  
**Repositorio:** https://github.com/n3mesis/party