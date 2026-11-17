import 'package:flutter/material.dart';

import 'models/plan.dart';
import '../theme/party_theme.dart';

/// Modelo de presentación para planes (UI + persistencia de historial).
/// Compartido por el creador clásico y el creador V2 para que el
/// historial (`liked_plans`) sea compatible entre ambos.
class PlanMock {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String costLabel;
  final int costValue;
  final String address;
  final String schedule;
  final String mapsUrl;
  final String emoji;
  final String imageUrl;
  final double rating;
  final double? distanceKm; // haversine usuario→lugar, null = sin dato
  final String? weatherSummary; // resumen del tiempo previsto
  final String? source; // 'overpass', 'wikipedia', 'news_events', 'local_fallback', 'mock'
  final List<String> warnings; // avisos (tiempo adverso, reserva, etc.)

  const PlanMock({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.costLabel,
    required this.costValue,
    required this.address,
    required this.schedule,
    required this.mapsUrl,
    required this.emoji,
    required this.imageUrl,
    required this.rating,
    this.distanceKm,
    this.weatherSummary,
    this.source,
    this.warnings = const [],
  });

  PlanMock copyWith({String? description}) => PlanMock(
        id: id,
        title: title,
        description: description ?? this.description,
        duration: duration,
        costLabel: costLabel,
        costValue: costValue,
        address: address,
        schedule: schedule,
        mapsUrl: mapsUrl,
        emoji: emoji,
        imageUrl: imageUrl,
        rating: rating,
        distanceKm: distanceKm,
        weatherSummary: weatherSummary,
        source: source,
        warnings: warnings,
      );
  factory PlanMock.fromPlan(Plan plan) {
    final address = plan.steps
        .map((s) => s.location.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final resolvedAddress = address.isEmpty ? '' : address;
    String schedule = '';
    if (plan.startTime != null && plan.endTime != null) {
      String fmt(DateTime d) =>
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      schedule = '${fmt(plan.startTime!)}-${fmt(plan.endTime!)}';
    }
    final cost = plan.costPerPerson;
    // Etiqueta afinada a 0.5 € (2.5 € no se redondea a 3 €) + detalle real
    // de transporte si el generador lo trae en transportSummary.
    String costLabel;
    if (cost <= 0) {
      costLabel = 'Gratis';
    } else if (cost % 1 == 0) {
      costLabel = '${cost.toStringAsFixed(0)} € aprox.';
    } else {
      costLabel = '${cost.toStringAsFixed(1)} € aprox.';
    }
    var description = plan.summary;
    if (plan.transportSummary.isNotEmpty) {
      description = description.isEmpty
          ? plan.transportSummary
          : '$description\n${plan.transportSummary}';
    }
    final m = plan.totalDurationMinutes;
    final String duration;
    if (m <= 35) {
      duration = '30 min';
    } else if (m <= 75) {
      duration = '1h';
    } else if (m <= 150) {
      duration = '2h - 3h';
    } else if (m >= 420) {
      duration = 'todo el día';
    } else if (m < 60) {
      duration = '$m min';
    } else {
      duration = '${(m / 60).toStringAsFixed(1).replaceAll('.0', '')}h';
    }
    final slug = plan.id
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final seed = slug.isEmpty ? 'lugar' : slug;
    final customPhoto =
        (plan.imageUrl != null && plan.imageUrl!.isNotEmpty) ? plan.imageUrl! : null;
    return PlanMock(
      id: plan.id,
      title: plan.title,
      description: description,
      duration: duration,
      costLabel: costLabel,
      costValue: cost.round(),
      distanceKm: plan.distanceKm,
      weatherSummary: plan.weatherSummary,
      source: plan.sources.isNotEmpty ? plan.sources.first : null,
      warnings: plan.warnings,
      address: resolvedAddress,
      schedule: schedule,
      mapsUrl: resolvedAddress == ''
          ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(plan.title)}'
          : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(resolvedAddress)}',
      emoji: '📍',
      imageUrl: customPhoto ?? 'https://picsum.photos/seed/$seed/400/250',
      rating: 4.5,
    );
  }
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'duration': duration, 'costLabel': costLabel, 'costValue': costValue, 'address': address, 'schedule': schedule, 'mapsUrl': mapsUrl, 'emoji': emoji, 'imageUrl': imageUrl, 'rating': rating, 'distanceKm': distanceKm, 'weatherSummary': weatherSummary, 'source': source, 'warnings': warnings};
  factory PlanMock.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Plan';
    String imageUrl = json['imageUrl'] as String? ?? '';
    if (imageUrl.isEmpty) {
      final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
      final seed = slug.isEmpty ? 'lugar' : slug;
      imageUrl = 'https://picsum.photos/seed/$seed/400/250';
    }
    return PlanMock(id: json['id'] as String, title: title, description: json['description'] as String, duration: json['duration'] as String, costLabel: json['costLabel'] as String, costValue: json['costValue'] as int? ?? 0, address: json['address'] as String, schedule: json['schedule'] as String? ?? '10:00-22:00', mapsUrl: json['mapsUrl'] as String, emoji: json['emoji'] as String? ?? '📍', imageUrl: imageUrl, rating: (json['rating'] as num?)?.toDouble() ?? 4.5, distanceKm: (json['distanceKm'] as num?)?.toDouble(), weatherSummary: json['weatherSummary'] as String?, source: json['source'] as String?, warnings: (json['warnings'] as List?)?.whereType<String>().toList() ?? const []);
  }

  /// Etiqueta corta del tiempo para mostrar en chip.
  String? get weatherLabel {
    final ws = weatherSummary;
    if (ws == null || ws.isEmpty) return null;
    // Extrae solo el emoji + descripción (antes de la coma de temperatura).
    final parts = ws.split(',');
    if (parts.isNotEmpty) return parts.first.trim();
    return null;
  }

  /// "a 3,2 km" o null si no hay dato. Coma decimal española.
  String? get distanceLabel {
    final d = distanceKm;
    if (d == null || !d.isFinite || d < 0) return null;
    if (d < 1) return 'a ${(d * 1000).round()} m';
    return 'a ${d.toStringAsFixed(d < 10 ? 1 : 0).replaceAll('.', ',')} km';
  }

  /// Icono de la fuente de datos.
  IconData get sourceIcon {
    switch (source) {
      case 'overpass':
        return Icons.map_rounded;
      case 'wikipedia':
        return Icons.book_rounded;
      case 'news_events':
        return Icons.newspaper_rounded;
      case 'local_fallback':
      case 'local_fallback_idea':
        return Icons.location_on_rounded;
      case 'mock':
        return Icons.lightbulb_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  /// Color de la fuente de datos.
  Color get sourceColor {
    switch (source) {
      case 'overpass':
        return PartyColors.primary;
      case 'wikipedia':
        return PartyColors.purple;
      case 'news_events':
        return PartyColors.warning;
      case 'local_fallback':
      case 'local_fallback_idea':
        return PartyColors.primaryDark;
      case 'mock':
        return PartyColors.textMuted;
      default:
        return PartyColors.textMuted;
    }
  }

  /// Etiqueta legible de la fuente.
  String get sourceLabel {
    switch (source) {
      case 'overpass':
        return 'OpenStreetMap';
      case 'wikipedia':
        return 'Wikipedia';
      case 'news_events':
        return 'Noticias web';
      case 'local_fallback':
      case 'local_fallback_idea':
        return 'Idea general';
      case 'mock':
        return 'Idea general';
      default:
        return 'Desconocida';
    }
  }
}
