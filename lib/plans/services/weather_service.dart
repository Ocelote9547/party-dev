import 'dart:convert';

import 'package:http/http.dart' as http;

/// Servicio del tiempo gratuito y sin clave API (Open-Meteo).
///
/// Devuelve el pronóstico por horas para unas coordenadas, para poder
/// penalizar actividades de exterior si hay lluvia prevista y sugerir
/// alternativas de interior. Nunca lanza: falla en silencio.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Pronóstico por horas para [lat]/[lng] desde ahora hasta [hours] horas.
  /// Devuelve null si falla la red o el servicio.
  Future<WeatherForecast?> forecast(
    double lat,
    double lng, {
    int hours = 48,
  }) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lng',
        'hourly': 'temperature_2m,precipitation_probability,weathercode',
        'timezone': 'Europe/Madrid',
        'forecast_hours': '$hours',
      });
      final res = await _client.get(uri, headers: const {
        'User-Agent': 'PARTY-App/1.8.3 (com.n3mesis.party)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final hourly = decoded['hourly'];
      if (hourly is! Map) return null;
      final times = hourly['time'];
      final temps = hourly['temperature_2m'];
      final probs = hourly['precipitation_probability'];
      final codes = hourly['weathercode'];
      if (times is! List || temps is! List || probs is! List || codes is! List) {
        return null;
      }
      final entries = <WeatherHour>[];
      for (var i = 0; i < times.length && i < hours; i++) {
        final t = '${times[i]}';
        final temp = (temps[i] as num?)?.toDouble() ?? 0;
        final prob = (probs[i] as num?)?.toInt() ?? 0;
        final code = (codes[i] as num?)?.toInt() ?? 0;
        final dt = DateTime.tryParse(t);
        if (dt == null) continue;
        entries.add(WeatherHour(
          time: dt,
          temperatureC: temp,
          precipitationProbability: prob.clamp(0, 100),
          weatherCode: code,
        ));
      }
      return WeatherForecast(lat: lat, lng: lng, hours: entries);
    } catch (_) {
      return null;
    }
  }

  /// Pronóstico para un instante concreto (la hora más cercana).
  /// Devuelve null si no hay datos.
  Future<WeatherHour?> at(double lat, double lng, DateTime when) async {
    final fc = await forecast(lat, lng, hours: 48);
    if (fc == null || fc.hours.isEmpty) return null;
    // Busca la hora más cercana a [when].
    WeatherHour? best;
    int? bestDiff;
    for (final h in fc.hours) {
      final diff = h.time.difference(when).abs().inMinutes;
      if (bestDiff == null || diff < bestDiff) {
        bestDiff = diff;
        best = h;
      }
    }
    return best;
  }

  /// ¿Llueve (o nieva/tormenta) en las próximas [horas] horas?
  Future<bool> willRain(double lat, double lng, {int hours = 6}) async {
    final fc = await forecast(lat, lng, hours: hours);
    if (fc == null) return false;
    return fc.hours.any((h) => isBadWeather(h.weatherCode));
  }

  /// Código de tiempo adverso para exteriores (lluvia, nieve, tormenta).
  static bool isBadWeather(int code) {
    // 51-67: llovizna/lluvia/lluvia congelada
    // 80-82: chubascos
    // 95-99: tormenta
    // 71-77: nieve
    if (code >= 51 && code <= 67) return true;
    if (code >= 80 && code <= 82) return true;
    if (code >= 95 && code <= 99) return true;
    if (code >= 71 && code <= 77) return true;
    return false;
  }

  /// ¿Es buen momento para actividades de exterior?
  static bool isOutdoorFriendly(WeatherHour h) {
    final bad = isBadWeather(h.weatherCode);
    if (bad) return false;
    // Muy frío (< 5°C) o muy calor (> 35°C) también desaconseja exterior.
    if (h.temperatureC < 5 || h.temperatureC > 35) return false;
    // Alta probabilidad de precipitación aunque el código no sea "lluvia".
    if (h.precipitationProbability >= 60) return false;
    return true;
  }
}

/// Una hora del pronóstico.
class WeatherHour {
  final DateTime time;
  final double temperatureC;
  final int precipitationProbability; // 0..100
  final int weatherCode; // WMO code

  const WeatherHour({
    required this.time,
    required this.temperatureC,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  /// Descripción legible del tiempo.
  String get description {
    final c = weatherCode;
    if (c == 0) return 'Despejado';
    if (c == 1) return 'Mayormente despejado';
    if (c == 2) return 'Parcialmente nublado';
    if (c == 3) return 'Nublado';
    if (c >= 45 && c <= 48) return 'Niebla';
    if (c >= 51 && c <= 57) return 'Llovizna';
    if (c >= 61 && c <= 67) return 'Lluvia';
    if (c >= 80 && c <= 82) return 'Chubascos';
    if (c >= 95 && c <= 99) return 'Tormenta';
    if (c >= 71 && c <= 77) return 'Nieve';
    return 'Desconocido';
  }

  /// Icono resumido.
  String get emoji {
    final c = weatherCode;
    if (c == 0) return '☀️';
    if (c == 1) return '🌤️';
    if (c == 2) return '⛅';
    if (c == 3) return '☁️';
    if (c >= 45 && c <= 48) return '🌫️';
    if (c >= 51 && c <= 67) return '🌧️';
    if (c >= 80 && c <= 82) return '🌦️';
    if (c >= 95 && c <= 99) return '⛈️';
    if (c >= 71 && c <= 77) return '❄️';
    return '🌡️';
  }
}

/// Pronóstico completo.
class WeatherForecast {
  final double lat;
  final double lng;
  final List<WeatherHour> hours;

  const WeatherForecast({
    required this.lat,
    required this.lng,
    required this.hours,
  });

  /// Primera hora con buen tiempo para exterior (o null).
  WeatherHour? get nextOutdoorFriendly {
    try {
      return hours.firstWhere((h) => WeatherService.isOutdoorFriendly(h));
    } catch (_) {
      return null;
    }
  }
}
