import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:party/theme/party_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'engines/discovery_engine.dart';
import 'engines/plan_generator.dart';
import 'geocoding_service.dart';
import 'intent.dart';
import 'location_service.dart';
import 'models/models.dart';
import 'plan_mock.dart';
import 'services/saved_plans_service.dart';
import 'services/weather_service.dart';
import 'sources/curated_routes.dart';
import 'sources/komoot_source.dart';
import 'sources/news_events_source.dart';
import 'sources/overpass_place_source.dart';
import 'sources/overpass_source.dart';
import 'sources/photon_source.dart';
import 'sources/wikipedia_source.dart';

/// Creador de planes completo: preguntas fullscreen, intención detectada,
/// generación con motores y deck tinder con persistencia de likes/dislikes.
class PlanCreatorV2Screen extends StatefulWidget {
  const PlanCreatorV2Screen({super.key, this.initialAnswers});

  /// Respuestas precargadas (útiles para tests).
  /// Claves admitidas: withWhom, planType, appetites, transport, timeLabel,
  /// budgetValue (num), place (String).
  final Map<String, dynamic>? initialAnswers;

  @override
  State<PlanCreatorV2Screen> createState() => _PlanCreatorV2ScreenState();
}

class _PlanCreatorV2ScreenState extends State<PlanCreatorV2Screen> {
  // Opciones como tarjetas (valor + emoji + icono). Los valores extra se
  // mapean a los `Appetite` / `MoveMode` EXISTENTES (sin tocar los enums).
  static const _withWhomOpts = [
    _Opt('solo', '🧍', Icons.person_rounded),
    _Opt('familia', '👨‍👩‍👧‍👦', Icons.family_restroom_rounded),
    _Opt('amigos', '🎉', Icons.celebration_rounded),
    _Opt('pareja', '💑', Icons.favorite_rounded),
  ];
  static const _appetiteOpts = [
    _Opt('aventura', '🧗', Icons.terrain_rounded),
    _Opt('cultura', '🏛️', Icons.museum_rounded),
    _Opt('relax', '🧘', Icons.spa_rounded),
    _Opt('fiesta', '🎉', Icons.celebration_rounded),
    _Opt('gastronomía', '🍽️', Icons.restaurant_rounded),
    _Opt('naturaleza', '🌿', Icons.park_rounded),
    _Opt('tapeo', '🍢', Icons.restaurant_menu_rounded),
    _Opt('copas', '🍸', Icons.local_bar_rounded),
    _Opt('brunch', '🥐', Icons.coffee_rounded),
    _Opt('festival', '🎪', Icons.festival_rounded),
    _Opt('cine', '🎬', Icons.movie_rounded),
    _Opt('teatro', '🎭', Icons.theaters_rounded),
    _Opt('running', '🏃', Icons.directions_run_rounded),
    _Opt('piscina', '🏊', Icons.pool_rounded),
    _Opt('picnic', '🧺', Icons.lunch_dining_rounded),
  ];
  static const _transportOpts = [
    _Opt('a pie', '🚶', Icons.directions_walk_rounded),
    _Opt('bici', '🚲', Icons.directions_bike_rounded),
    _Opt('patinete', '🛴', Icons.electric_scooter_rounded),
    _Opt('coche', '🚗', Icons.directions_car_rounded),
    _Opt('bus-metro', '🚌', Icons.directions_bus_rounded),
    _Opt('moto', '🏍️', Icons.two_wheeler_rounded),
    _Opt('taxi', '🚕', Icons.local_taxi_rounded),
    _Opt('tren', '🚆', Icons.train_rounded),
  ];
  static const _timeOpts = [
    _Opt('30min', '⚡', Icons.bolt_rounded),
    _Opt('1h', '🕐', Icons.schedule_rounded),
    _Opt('3h', '🕒', Icons.hourglass_full_rounded),
    _Opt('todo el día', '🌞', Icons.wb_sunny_rounded),
  ];
  static const _budgetOpts = [
    _BudgetOpt('Gratis', '🎁', Icons.card_giftcard_rounded, 0),
    _BudgetOpt('0–10 €', '🪙', Icons.savings_rounded, 5),
    _BudgetOpt('10–30 €', '💶', Icons.wallet_rounded, 20),
    _BudgetOpt('30–80 €', '💳', Icons.credit_card_rounded, 50),
    _BudgetOpt('80 € +', '💎', Icons.diamond_rounded, 120),
  ];
  static const _timeOfDayOpts = [
    _Opt('indiferente', '🕐', Icons.access_time_rounded),
    _Opt('manana', '🌅', Icons.wb_sunny_rounded),
    _Opt('tarde', '☀️', Icons.wb_sunny_rounded),
    _Opt('noche', '🌙', Icons.nights_stay_rounded),
  ];
  static Set<String> get _timeOfDayValues =>
      _timeOfDayOpts.map((o) => o.value).toSet();

  static Set<String> get _withWhomValues =>
      _withWhomOpts.map((o) => o.value).toSet();
  static Set<String> get _appetiteValues =>
      _appetiteOpts.map((o) => o.value).toSet();
  static Set<String> get _transportValues =>
      _transportOpts.map((o) => o.value).toSet();
  static Set<String> get _timeValues =>
      _timeOpts.map((o) => o.value).toSet();

  static _BudgetOpt _budgetPresetFor(double v) {
    if (v <= 0) return _budgetOpts[0];
    if (v <= 10) return _budgetOpts[1];
    if (v <= 30) return _budgetOpts[2];
    if (v <= 80) return _budgetOpts[3];
    return _budgetOpts[4];
  }

  // Semillas de cabecera por pregunta (picsum).
  static const _seeds = [
    'withwhom',
    'appetites',
    'timeslot',
    'budget',
    'place',
    'transport',
  ];

  static const _likedKey = 'liked_plans';
  static const _dislikedKey = 'disliked_plan_ids';
  static const _savedLatKey = 'plans_saved_lat';
  static const _savedLngKey = 'plans_saved_lng';
  static const _savedLabelKey = 'plans_saved_label';
  static const _maxKmKey = 'plans_max_km';

  /// Distancia máxima elegida (km). null = auto según transporte.
  double? _maxKm;

  String _withWhom = 'amigos';
  Set<String> _appetites = {'fiesta'};
  String _transport = 'a pie';
  String _timeLabel = '3h';
  String _timeOfDay = 'indiferente';
  DateTime? _planDate;
  double _budgetValue = 30;
  late final TextEditingController _placeController;
  late final PageController _pageController;

  int _step = 0;
  static const _totalSteps = 7;

  // Servicios.
  final WeatherService _weather = WeatherService();
  final SavedPlansService _savedPlans = SavedPlansService();
  WeatherHour? _weatherHour;
  bool _weatherLoading = false;

  // Ubicación exacta opcional.
  double? _lat;
  double? _lng;
  String? _geoLabel;
  bool _locatingExact = false;
  bool _locatingApprox = false;

  // Autocompletado real (Nominatim): pueblos, barrios, ciudades.
  final GeocodingService _geocoding = GeocodingService();
  List<PlaceSuggestion> _suggestions = [];
  bool _searchingPlaces = false;
  Timer? _debounce;

  // Estado visible (NO solo SnackBar invisible): banner en la UI.
  String? _statusInfo;
  bool _statusIsError = false;
  String _stage = '';

  bool _loading = false;
  bool _showResults = false;
  List<PlanMock> _results = [];
  String? _error;
  bool _generatedOnce = false;

  // Arrastre del deck.
  Offset _drag = Offset.zero;

  // Ids ya mostrados en esta sesión: "ver otros" los excluye para rotar.
  final Set<String> _sessionShown = {};

  final Set<String> _likedIds = {};
  final Set<String> _dislikedIds = {};

  @override
  void initState() {
    super.initState();
    _placeController = TextEditingController(text: 'Madrid Centro');
    _pageController = PageController();
    _applyInitialAnswers(widget.initialAnswers);
    unawaited(_loadFeedback());
    unawaited(_loadSavedPlace());
  }

  /// Carga la ubicación guardada (si la hay) + distancia máxima.
  Future<void> _loadSavedPlace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final lat = prefs.getDouble(_savedLatKey);
      final lng = prefs.getDouble(_savedLngKey);
      final label = prefs.getString(_savedLabelKey);
      final maxKm = prefs.getDouble(_maxKmKey);
      setState(() {
        if (lat != null && lng != null && (label ?? '').isNotEmpty) {
          _lat = lat;
          _lng = lng;
          _geoLabel = label;
          _placeController.text = label!;
          _statusInfo = 'Ubicación guardada: $label';
          _statusIsError = false;
        }
        _maxKm = (maxKm != null && maxKm > 0) ? maxKm : null;
      });
    } catch (_) {}
  }

  Future<void> _savePlace(double lat, double lng, String label) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_savedLatKey, lat);
      await prefs.setDouble(_savedLngKey, lng);
      await prefs.setString(_savedLabelKey, label);
    } catch (_) {}
  }

  Future<void> _forgetPlace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedLatKey);
      await prefs.remove(_savedLngKey);
      await prefs.remove(_savedLabelKey);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _lat = null;
      _lng = null;
      _geoLabel = null;
      _placeController.clear();
      _suggestions = [];
      _statusInfo = null;
      _statusIsError = false;
    });
    _showVisibleMessage('Ubicación olvidada. Escribe tu pueblo o usa el GPS.');
  }

  Future<void> _saveMaxKm(double? v) async {
    setState(() => _maxKm = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (v == null) {
        await prefs.remove(_maxKmKey);
      } else {
        await prefs.setDouble(_maxKmKey, v);
      }
    } catch (_) {}
  }

  /// Amplía el radio de búsqueda y vuelve a generar planes.
  /// Secuencia: auto → 50 km → 100 km → 200 km → se queda en 200 km.
  Future<void> _expandRadius() async {
    double? next;
    if (_maxKm == null) {
      next = 50.0;
    } else if (_maxKm! < 50.0) {
      next = 50.0;
    } else if (_maxKm! < 100.0) {
      next = 100.0;
    } else if (_maxKm! < 200.0) {
      next = 200.0;
    } else {
      next = 200.0; // ya en el máximo
    }
    if (next == _maxKm) {
      // Ya está en el máximo; notificar sutilmente.
      if (!mounted) return;
      _setStatus('Radio ya al máximo (200 km).');
      return;
    }
    await _saveMaxKm(next);
    if (!mounted) return;
    _setStatus('Radio ampliado a ${next.toInt()} km. Rebuscando…');
    await _generate();
  }

  void _applyInitialAnswers(Map<String, dynamic>? answers) {
    if (answers == null) return;
    final withWhom = answers['withWhom'];
    if (withWhom is String && _withWhomValues.contains(withWhom)) {
      _withWhom = withWhom;
    }
    final rawAppetites = answers['appetites'];
    if (rawAppetites is List && rawAppetites.isNotEmpty) {
      final parsed = rawAppetites
          .whereType<String>()
          .where(_appetiteValues.contains)
          .take(3)
          .toSet();
      if (parsed.isNotEmpty) _appetites = parsed;
    } else {
      final planType = answers['planType'];
      if (planType is String && _appetiteValues.contains(planType)) {
        _appetites = {planType};
      }
    }
    final transport = answers['transport'];
    if (transport is String) {
      if (_transportValues.contains(transport)) {
        _transport = transport;
      } else if (transport == 'bici/patinete') {
        _transport = 'bici';
      }
    }
    final timeLabel = answers['timeLabel'];
    if (timeLabel is String && _timeValues.contains(timeLabel)) {
      _timeLabel = timeLabel;
    }
    final budget = answers['budgetValue'];
    if (budget is num) {
      _budgetValue = budget.toDouble().clamp(0, 200);
    }
    final place = answers['place'];
    if (place != null) {
      _placeController.text = '$place';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _placeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setStatus(String? msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusInfo = msg;
      _statusIsError = isError;
    });
  }

  void _showVisibleMessage(String msg, {bool isError = false}) {
    _setStatus(msg, isError: isError);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : PartyColors.surface,
        duration: Duration(milliseconds: isError ? 3500 : 1800),
      ),
    );
  }

  Appetite _appetiteFor(String label) {
    switch (label) {
      case 'aventura':
        return Appetite.aventura;
      case 'cultura':
        return Appetite.cultura;
      case 'relax':
        return Appetite.relax;
      case 'fiesta':
        return Appetite.fiesta;
      case 'gastronomía':
      case 'tapeo':
      case 'brunch':
        return Appetite.gastronomia;
      case 'naturaleza':
      case 'picnic':
        return Appetite.naturaleza;
      case 'cine':
      case 'teatro':
        return Appetite.cultura;
      case 'copas':
      case 'festival':
        return Appetite.fiesta;
      case 'running':
      case 'piscina':
        return Appetite.deporte;
      default:
        return Appetite.fiesta;
    }
  }

  UserIntent _buildIntent() {
    final WithWhom withWhom;
    switch (_withWhom) {
      case 'solo':
        withWhom = WithWhom.solo;
        break;
      case 'familia':
        withWhom = WithWhom.familia;
        break;
      case 'pareja':
        withWhom = WithWhom.pareja;
        break;
      case 'amigos':
      default:
        withWhom = WithWhom.amigos;
        break;
    }

    final appetites =
        _appetites.map(_appetiteFor).toSet().ifEmpty({Appetite.fiesta});

    final TimeSlot timeSlot;
    switch (_timeLabel) {
      case '30min':
        timeSlot = TimeSlot.h30_60;
        break;
      case '1h':
        timeSlot = TimeSlot.h1_2;
        break;
      case '3h':
        timeSlot = TimeSlot.h2_4;
        break;
      case 'todo el día':
        timeSlot = TimeSlot.todoDia;
        break;
      default:
        timeSlot = TimeSlot.h2_4;
        break;
    }

    final BudgetRange budgetRange;
    if (_budgetValue <= 0) {
      budgetRange = BudgetRange.gratis;
    } else if (_budgetValue <= 15) {
      budgetRange = BudgetRange.hasta15;
    } else if (_budgetValue <= 40) {
      budgetRange = BudgetRange.r15_40;
    } else if (_budgetValue <= 80) {
      budgetRange = BudgetRange.r40_80;
    } else {
      budgetRange = BudgetRange.mas80;
    }

    final MoveMode moveMode;
    switch (_transport) {
      case 'a pie':
        moveMode = MoveMode.pie;
        break;
      case 'bici':
        moveMode = MoveMode.bici;
        break;
      case 'patinete':
        moveMode = MoveMode.patinete;
        break;
      case 'coche':
      case 'moto':
      case 'taxi':
        moveMode = MoveMode.coche;
        break;
      case 'bus-metro':
      case 'tren':
        moveMode = MoveMode.transporte;
        break;
      default:
        moveMode = MoveMode.indiferente;
        break;
    }

    final timeOfDay = switch (_timeOfDay) {
      'manana' => TimeOfDayPreference.manana,
      'tarde' => TimeOfDayPreference.tarde,
      'noche' => TimeOfDayPreference.noche,
      _ => TimeOfDayPreference.indiferente,
    };

    return UserIntent(
      withWhom: withWhom,
      appetites: appetites,
      timeSlot: timeSlot,
      budgetMinPerPerson: budgetRange.minPerPerson,
      budgetMaxPerPerson: budgetRange.maxPerPerson,
      locationLabel: _placeController.text.trim(),
      lat: _hasUsableCoordinates(_lat, _lng) ? _lat : null,
      lng: _hasUsableCoordinates(_lat, _lng) ? _lng : null,
      moveMode: moveMode,
      timeOfDay: timeOfDay,
      planDate: _planDate,
    );
  }

  /// Foto real del plan si el modelo la trae (`Plan.imageUrl`); si no,
  /// el `imageUrl` de `PlanMock` (picsum). Defensivo: `Plan` aún no declara
  /// `imageUrl`, así que hoy siempre se usa el fallback sin romper.
  String? _planPhoto(Plan plan) {
    try {
      final v = (plan as dynamic).imageUrl as String?;
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // Sin `imageUrl` en `Plan`: fallback a `PlanMock`.
    }
    return null;
  }

  int _groupSizeFor(WithWhom withWhom) {
    switch (withWhom) {
      case WithWhom.solo:
        return 1;
      case WithWhom.pareja:
        return 2;
      case WithWhom.familia:
      case WithWhom.amigos:
        return 4;
    }
  }

  Future<void> _loadFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final likedRaw = prefs.getStringList(_likedKey);
    final disliked = prefs.getStringList(_dislikedKey) ?? <String>[];
    final likedIds = <String>{};
    if (likedRaw != null) {
      for (final entry in likedRaw) {
        try {
          final decoded = jsonDecode(entry) as Map<String, dynamic>;
          final id = decoded['id'] as String?;
          if (id != null) likedIds.add(id);
        } catch (_) {
          likedIds.add(entry);
        }
      }
    }
    setState(() {
      _likedIds
        ..clear()
        ..addAll(likedIds);
      _dislikedIds
        ..clear()
        ..addAll(disliked);
    });
  }

  Future<Set<String>> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final likedRaw = prefs.getStringList(_likedKey) ?? <String>[];
    final disliked = prefs.getStringList(_dislikedKey) ?? <String>[];
    final seen = <String>{...disliked};
    for (final entry in likedRaw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        final id = decoded['id'] as String?;
        if (id != null) seen.add(id);
      } catch (_) {
        seen.add(entry);
      }
    }
    return seen;
  }

  bool _pickerCancelled = false;
  String? _lastSearchLabel;

  static bool _hasUsableCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
      return false;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    // 0,0 es el valor histórico usado cuando no había GPS; nunca se trata
    // como una ubicación del usuario.
    return lat != 0 || lng != 0;
  }

  /// Resuelve coordenadas reales: GPS o sugerencia elegida si la hay; si no,
  /// geocodifica el texto. Si el texto es ambiguo (varios pueblos distintos),
  /// pregunta cuál (antes cogía el 1º por importancia y te mandaba a Córdoba).
  Future<({double lat, double lng, String label})?> _resolveCoords(
      String placeText) async {
    if (_hasUsableCoordinates(_lat, _lng)) {
      return (
        lat: _lat!,
        lng: _lng!,
        label: _geoLabel ?? placeText,
      );
    }
    final q = placeText.trim();
    if (q.isEmpty) return null;
    if (q.length < 3) {
      _showVisibleMessage(
        'Escribe al menos 3 letras de tu pueblo.',
        isError: true,
      );
      return null;
    }
    try {
      final options = await _geocoding.autocomplete(q, limit: 5)
          .timeout(const Duration(seconds: 6));
      if (options.isEmpty) {
        _showVisibleMessage(
          'No encuentro "$q": prueba con "pueblo, provincia".',
          isError: true,
        );
        return null;
      }
      if (options.length == 1) return _useSuggestion(options.first);
      final towns = options.map((o) => o.shortLabel.toLowerCase()).toSet();
      if (towns.length == 1) return _useSuggestion(options.first);
      if (!mounted) return null;
      final picked = await _pickTownSheet(q, options);
      if (picked == null) {
        _pickerCancelled = true;
        return null;
      }
      return _useSuggestion(picked);
    } catch (_) {
      return null;
    }
  }

  /// Aplica la sugerencia elegida (actualiza cuadro + coords + la guarda).
  ({double lat, double lng, String label})? _useSuggestion(
      PlaceSuggestion s) {
    if (!mounted) return null;
    setState(() {
      _placeController.text = s.shortLabel;
      _lat = s.lat;
      _lng = s.lng;
      _geoLabel = s.shortLabel;
      _suggestions = [];
    });
    unawaited(_savePlace(s.lat, s.lng, s.shortLabel));
    return (lat: s.lat, lng: s.lng, label: s.shortLabel);
  }

  /// Hoja para elegir pueblo cuando el texto coincide con varios sitios.
  Future<PlaceSuggestion?> _pickTownSheet(
    String query,
    List<PlaceSuggestion> options,
  ) {
    return showModalBottomSheet<PlaceSuggestion>(
      context: context,
      backgroundColor: PartyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Text(
                '¿Cuál es tu pueblo?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.text,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                '"$query" coincide con varios sitios: elige para buscar cerca de ti.',
                style: TextStyle(
                  fontSize: 12,
                  color: PartyColors.textSecondary,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final o = options[i];
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: PartyColors.border),
                    ),
                    leading: const Icon(Icons.place_rounded, size: 20),
                    title: Text(
                      o.shortLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.text,
                      ),
                    ),
                    subtitle: Text(
                      o.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: PartyColors.textMuted,
                      ),
                    ),
                    onTap: () => Navigator.pop(sheetContext, o),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _statusInfo = null;
      _statusIsError = false;
      _stage = 'Leyendo tus respuestas…';
    });
    _pickerCancelled = false;
    try {
      final placeText = _placeController.text.trim();
      // Fase 1: ubicar de verdad (geocodifica tu pueblo si no hay GPS).
      if (mounted) setState(() => _stage = 'Localizando “$placeText”…');
      final resolved = await _resolveCoords(placeText);
      if (!mounted) return;
      if (resolved == null && _pickerCancelled) {
        // Canceló el selector de pueblo: aborta sin generar nada.
        _pickerCancelled = false;
        setState(() => _loading = false);
        return;
      }
      final hasGeo = resolved != null &&
          _hasUsableCoordinates(resolved.lat, resolved.lng);
      _lastSearchLabel = hasGeo ? resolved.label : placeText;
      double? maxDistance;

      // ---- Tiempo previsto y pronóstico ----
      DateTime plannedStart = DateTime.now();
      if (_planDate != null) {
        final h = _planDate!.hour;
        final m = _planDate!.minute;
        plannedStart = DateTime(
          _planDate!.year,
          _planDate!.month,
          _planDate!.day,
          h,
          m,
        );
      }
      if (mounted) {
        setState(() => _stage = 'Consultando el tiempo…');
        _weatherLoading = true;
      }
      WeatherHour? weather;
      if (hasGeo) {
        try {
          weather = await _weather.at(resolved.lat, resolved.lng, plannedStart)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          weather = null;
        }
      }
      if (mounted) {
        setState(() {
          _weatherHour = weather;
          _weatherLoading = false;
        });
      }
      if (weather != null && mounted) {
        _setStatus(
          'Tiempo en ${_geoLabel ?? placeText}: ${weather.emoji} ${weather.description}, ${weather.temperatureC.toStringAsFixed(0)}°C',
        );
      }

      var intent = _buildIntent();
      if (hasGeo) {
        intent = UserIntent(
          withWhom: intent.withWhom,
          appetites: intent.appetites,
          timeSlot: intent.timeSlot,
          budgetMinPerPerson: intent.budgetMinPerPerson,
          budgetMaxPerPerson: intent.budgetMaxPerPerson,
          locationLabel: resolved.label,
          lat: resolved.lat,
          lng: resolved.lng,
          moveMode: intent.moveMode,
          timeOfDay: intent.timeOfDay,
          planDate: intent.planDate,
        );
        if (mounted) {
          setState(() {
            _geoLabel = resolved.label;
            _stage = 'Buscando sitios reales cerca de ${resolved.label}…';
          });
        }
      } else {
        if (mounted) {
          setState(() => _stage = 'Sin ubicación exacta: usando ideas generales…');
        }
      }

      // Pequeña pausa para que el stage sea legible (el "IA pensando").
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      // Fase 2: descubrimiento coordinado por DiscoveryEngine.
      // Ninguna fuente sintética participa en una búsqueda geolocalizada.
      DiscoveryResult discovered;
      final searchRadius = _maxKm ?? _radiusFor(intent.moveMode);
      if (hasGeo) {
        final appetites =
            intent.appetites.isEmpty ? {Appetite.fiesta} : intent.appetites;
        final overpassRadius =
            searchRadius > 50 ? 50.0 : searchRadius;
        if (mounted) {
          setState(() => _stage = 'Consultando mapas y fuentes reales…');
        }

        final engine = DiscoveryEngine.fromSources(
          placeSources: [
            OverpassPlaceSource(
              lat: resolved.lat,
              lng: resolved.lng,
              appetites: appetites,
              radiusKm: overpassRadius,
            ),
            PhotonPlaceSource(
              lat: resolved.lat,
              lng: resolved.lng,
              queries: _photonQueriesFor(appetites),
              radiusKm: searchRadius > 200 ? 200.0 : searchRadius,
            ),
            WikipediaPlaceSource(
              lat: resolved.lat,
              lng: resolved.lng,
              radiusKm: searchRadius > 10 ? 10 : searchRadius,
            ),
            NewsEventsSource(
              lat: resolved.lat,
              lng: resolved.lng,
              radiusKm: searchRadius,
              locationLabel: resolved.label,
            ),
          ],
          routeSources: [
            OverpassRouteSource(
              lat: resolved.lat,
              lng: resolved.lng,
              radiusKm: overpassRadius + 15,
            ),
            KomootRouteSource(
              lat: resolved.lat,
              lng: resolved.lng,
              radiusKm: searchRadius > 50 ? 50.0 : searchRadius,
              sport: 'hike',
            ),
          ],
          perSourceTimeout: const Duration(seconds: 8),
          maxRetries: 1,
        );
        final sourceResult = await engine.discover();
        var realPlaces = _mergePlaces([sourceResult.places]);
        final allRoutes = _mergeRoutes([sourceResult.routes]);
        final sourcesResponded = [...sourceResult.sourcesResponded];
        final sourcesFailed = {...sourceResult.sourcesFailed};

        for (final entry in sourcesFailed.entries) {
          debugPrint('[PlanDiscovery] ${entry.key}: ${entry.value}');
        }

        // Overpass limita la consulta de lugares a 30 km. Solo se amplía
        // cuando la primera búsqueda usó un radio menor: evita repetir la
        // misma consulta cuando el radio efectivo ya era de 30 km o más.
        if (realPlaces.length < 5 && overpassRadius < 30) {
          if (mounted) {
            setState(() => _stage = 'Pocos sitios: ampliando la búsqueda local…');
          }
          try {
            final wide = await OverpassPlaceSource(
              lat: resolved.lat,
              lng: resolved.lng,
              appetites: appetites,
              radiusKm: 30,
            ).fetchAll().timeout(const Duration(seconds: 5));
            realPlaces = _mergePlaces([realPlaces, wide]);
            sourcesResponded.add('OverpassPlaceSource (radio ampliado)');
          } catch (error) {
            sourcesFailed['OverpassPlaceSource (radio ampliado)'] =
                error.toString();
            debugPrint('[PlanDiscovery] OverpassPlaceSource (radio ampliado): $error');
          }
        }

        maxDistance = searchRadius + 15;
        final curatedNear = CuratedRoutes.all.where((route) {
          if (route.centerLat == null || route.centerLng == null) return false;
          final distance = LocationService.distanceKm(
            resolved.lat,
            resolved.lng,
            route.centerLat!,
            route.centerLng!,
          );
          return distance != null && distance <= searchRadius + 40;
        }).take(3).toList();
        if (curatedNear.isNotEmpty) sourcesResponded.add('curated_routes');

        final routes = [...allRoutes, ...curatedNear];
        discovered = DiscoveryResult(
          places: realPlaces,
          routes: routes,
          activities: const [],
          sourcesResponded: sourcesResponded,
          sourcesFailed: sourcesFailed,
        );

        if (realPlaces.isEmpty && routes.isEmpty) {
          _setStatus(
            'No se encontraron lugares ni rutas verificables cerca de ${_geoLabel ?? placeText}. '
            'Comprueba la conexión o amplía el radio de búsqueda.',
            isError: true,
          );
        } else {
          if (mounted) {
            setState(() => _stage = 'Calculando costes, tiempos y distancias…');
          }
          if (realPlaces.isEmpty) {
            _setStatus('Hay pocas fichas de lugares en los mapas; se muestran rutas verificadas.');
          }
        }
      } else {
        // Sin coordenadas válidas no se hacen consultas geográficas ni se
        // convierten ideas inventadas en lugares cercanos.
        discovered = const DiscoveryResult();
        _setStatus(
          'No se pudo verificar tu ubicación. Selecciona tu localidad en las sugerencias o activa el GPS para buscar lugares reales.',
          isError: true,
        );
      }
      if (!mounted) return;
      final seenIds = await _loadSeenIds();
      if (!mounted) return;
      final plans = await PlanGenerator.generate(
        intent: intent,
        discovered: discovered,
        seenIds: seenIds,
        // Vistos + ya mostrados en esta sesión: rotan, no repiten.
        excludeIds: {...seenIds, ..._sessionShown},
        maxDistanceKm: maxDistance,
        groupSize: _groupSizeFor(intent.withWhom),
        weather: weather,
        plannedStart: plannedStart,
      );
      if (!mounted) return;
      final mapped = plans.map((p) {
        final m = PlanMock.fromPlan(p);
        final photo = _planPhoto(p);
        // Añade info del tiempo a la descripción si la hay.
        var desc = m.description;
        if (p.weatherSummary != null && p.weatherSummary!.isNotEmpty) {
          desc = '$desc\n${p.weatherSummary}';
        }
        if (photo == null) return m.copyWith(description: desc);
          return PlanMock(
            id: m.id,
            title: m.title,
            description: desc,
            duration: m.duration,
            costLabel: m.costLabel,
            costValue: m.costValue,
            address: m.address,
            schedule: m.schedule,
            mapsUrl: m.mapsUrl,
            emoji: m.emoji,
            imageUrl: photo,
            rating: m.rating,
            distanceKm: m.distanceKm,
          );
      }).toList();
      setState(() {
        _results = mapped;
        _generatedOnce = true;
        _loading = false;
        _drag = Offset.zero;
        _showResults = true;
        if (_results.isEmpty) {
          if (!hasGeo) {
            _error = 'No se puede buscar por cercanía sin una ubicación verificada. '
                'Selecciona tu localidad o activa el GPS y vuelve a intentarlo.';
          } else if (discovered.sourcesFailed.isNotEmpty) {
            final failed = discovered.sourcesFailed.keys.join(', ');
            _error = 'No se encontraron planes con los datos disponibles. '
                'Fuentes con error: $failed. '
                'Prueba a ampliar el radio o revisa tu conexión.';
          } else {
            _error = 'Las fuentes consultadas no devolvieron lugares ni rutas verificables. '
                'Prueba a ampliar el radio de búsqueda.';
          }
        }
      });
      // Acumula mostrados para que "ver otros" rote sin repetir.
      _sessionShown.addAll(mapped.map((m) => m.id));
      // Precarga las 3 primeras fotos para que el deck no parpadee al
      // arrastrar (cada drag hacía setState y re-resolvía Image.network).
      if (mapped.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          final ctx = context;
          for (final m in mapped.take(3)) {
            try {
              // ignore: use_build_context_synchronously
              await precacheImage(NetworkImage(m.imageUrl), ctx);
            } catch (_) {}
            if (!mounted) return;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generatedOnce = true;
        _showResults = true;
        _error = 'No se han podido generar planes. Inténtalo de nuevo. '
            '(Error: ${e.runtimeType})';
      });
    }
  }

  Future<void> _saveLikedPlan(PlanMock plan) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final existing = prefs.getStringList(_likedKey) ?? <String>[];
    final already = existing.any((entry) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        return decoded['id'] == plan.id;
      } catch (_) {
        return entry == plan.id;
      }
    });
    if (!already) {
      existing.add(jsonEncode(plan.toJson()));
      await prefs.setStringList(_likedKey, existing);
      if (!mounted) return;
    }
    setState(() {
      _likedIds.add(plan.id);
      _results.removeWhere((p) => p.id == plan.id);
      _drag = Offset.zero;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guardado en favoritos: ${plan.title}'),
        backgroundColor: PartyColors.surface,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _saveDislikedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final existing = prefs.getStringList(_dislikedKey) ?? <String>[];
    if (!existing.contains(id)) {
      existing.add(id);
      await prefs.setStringList(_dislikedKey, existing);
      if (!mounted) return;
    }
    setState(() {
      _dislikedIds.add(id);
      _results.removeWhere((p) => p.id == id);
      _drag = Offset.zero;
    });
  }

  Future<List<PlanMock>> _getLikedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_likedKey) ?? <String>[];
    final plans = <PlanMock>[];
    for (final entry in list) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        plans.add(PlanMock.fromJson(decoded));
      } catch (_) {
        continue;
      }
    }
    return plans;
  }

  Future<void> _showHistory() async {
    final plans = await _getLikedPlans();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PartyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        if (plans.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Todavía no tienes planes guardados. Dale a me gusta en un plan para verlo aquí.',
              style: TextStyle(color: PartyColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            itemCount: plans.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Planes guardados (${plans.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: PartyColors.text,
                    ),
                  ),
                );
              }
              final plan = plans[index - 1];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: PartyColors.border),
                ),
                leading: Text(
                  plan.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  plan.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: PartyColors.text,
                  ),
                ),
                subtitle: Text(
                  '${plan.duration} · ${plan.costLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    color: PartyColors.textMuted,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.map_rounded),
                  color: PartyColors.primary,
                  tooltip: 'Ver en Maps',
                  onPressed: () => _openMaps(plan),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Busca ferias, romerías y eventos actuales en el pueblo (Google).
  /// No inventamos eventos: te llevamos a la agenda real de tu zona.
  Future<void> _openEventsSearch() async {
    final label = (_lastSearchLabel ?? _placeController.text).trim();
    if (label.isEmpty) return;
    final year = DateTime.now().year;
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent('ferias romerías eventos $label $year')}',
    );
    final ok = await canLaunchUrl(uri);
    if (!mounted) return;
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede abrir la búsqueda de eventos en $label'),
          backgroundColor: PartyColors.surface,
        ),
      );
    }
  }

  /// Elige la fecha del plan para consultar el tiempo.
  Future<void> _pickPlanDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _planDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && mounted) {
      setState(() => _planDate = picked);
    }
  }

  /// Guarda un plan generado en "Mis Planes".
  Future<void> _savePlanToSaved(PlanMock pm) async {
    try {
      // Reconstruye un Plan simplificado desde PlanMock para guardar.
      final plan = Plan(
        id: pm.id,
        title: pm.title,
        summary: pm.description,
        score: pm.rating,
        totalDurationMinutes: _minutesFromDuration(pm.duration),
        totalCost: pm.costValue.toDouble(),
        costPerPerson: pm.costValue.toDouble(),
        difficulty: 'facil',
        transportSummary: pm.address.isNotEmpty ? pm.address : '',
        sources: [pm.imageUrl.isNotEmpty ? 'foto-real' : 'picsum'],
        distanceKm: pm.distanceKm,
        weatherSummary: _weatherHour != null
            ? '${_weatherHour!.emoji} ${_weatherHour!.description}, ${_weatherHour!.temperatureC.toStringAsFixed(0)}°C'
            : null,
        weatherCode: _weatherHour?.weatherCode,
        generatedAt: DateTime.now(),
        customName: pm.title,
      );
      await _savedPlans.savePlan(plan);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado en "Mis Planes": ${plan.title}'),
          backgroundColor: PartyColors.surface,
          duration: const Duration(milliseconds: 1400),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el plan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Convierte una etiqueta de duración ("2h - 3h") a minutos aproximados.
  int _minutesFromDuration(String d) {
    final lower = d.toLowerCase();
    if (lower.contains('30 min')) return 30;
    if (lower.contains('1h')) return 60;
    if (lower.contains('2h - 3h')) return 150;
    if (lower.contains('todo el día')) return 480;
    if (lower.contains('2h')) return 120;
    if (lower.contains('3h')) return 180;
    return 90;
  }

  Future<void> _openMaps(PlanMock plan) async {
    final uri = Uri.parse(plan.mapsUrl);
    final ok = await canLaunchUrl(uri);
    if (!mounted) return;
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede abrir Maps: ${plan.address}'),
          backgroundColor: PartyColors.surface,
        ),
      );
    }
  }

  // Valida la pregunta actual (no avanzar vacío).
  bool _stepValid(int step) {
    switch (step) {
      case 0:
        return _withWhomValues.contains(_withWhom);
      case 1:
        return _appetites.isNotEmpty &&
            _appetites.length <= 3 &&
            _appetites.every(_appetiteValues.contains);
      case 2:
        return _timeValues.contains(_timeLabel);
      case 3:
        return _timeOfDayValues.contains(_timeOfDay);
      case 4:
        return true; // presupuesto por tramos siempre válido
      case 5:
        return _placeController.text.trim().isNotEmpty;
      case 6:
        return _transportValues.contains(_transport);
      default:
        return false;
    }
  }

  void _goTo(int step) {
    final next = step.clamp(0, _totalSteps - 1);
    setState(() => _step = next);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (!_stepValid(_step)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_stepHint(_step)),
          backgroundColor: PartyColors.surface,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      return;
    }
    if (_step == _totalSteps - 1) {
      _generate();
      return;
    }
    _goTo(_step + 1);
  }

  String _stepHint(int step) {
    switch (step) {
      case 1:
        return 'Elige al menos 1 apetito (máx. 3).';
      case 3:
        return 'Elige una franja horaria.';
      case 5:
        return 'Escribe un lugar o usa tu ubicación.';
      default:
        return 'Elige una opción para continuar.';
    }
  }

  /// Consultas Photon (palabra, filtro osm_tag) según apetitos. Máx 9.
  /// En pueblos los sitios se llaman mesón, venta, taberna o pizzería:
  /// solo "bar/restaurante" dejaba fuera media carta.
  static List<(String, String)> _photonQueriesFor(Set<Appetite> appetites) {
    final out = <(String, String)>[];
    for (final a in appetites) {
      switch (a) {
        case Appetite.gastronomia:
          out.addAll([
            ('bar', 'amenity:bar'),
            ('restaurante', 'amenity:restaurant'),
            ('cafetería', 'amenity:cafe'),
            ('taberna', 'amenity:bar'),
            ('mesón', 'amenity:restaurant'),
            ('venta', 'amenity:restaurant'),
            ('pizzería', 'amenity:restaurant'),
            ('heladería', 'amenity:ice_cream'),
            ('bodega', 'craft:winery'),
          ]);
          break;
        case Appetite.fiesta:
        case Appetite.sorpresa:
          out.addAll([
            ('pub', 'amenity:pub'),
            ('discoteca', 'amenity:nightclub'),
            ('cine', 'amenity:cinema'),
          ]);
          break;
        case Appetite.cultura:
        case Appetite.aprender:
          out.addAll([
            ('museo', 'tourism:museum'),
            ('castillo', 'tourism:castle'),
            ('iglesia', 'amenity:place_of_worship'),
          ]);
          break;
        case Appetite.naturaleza:
        case Appetite.relax:
        case Appetite.bonito:
          out.addAll([
            ('parque', 'leisure:park'),
            ('mirador', 'tourism:viewpoint'),
            ('laguna', 'natural:water'),
          ]);
          break;
        case Appetite.aventura:
        case Appetite.deporte:
        case Appetite.descubrir:
          out.addAll([
            ('mirador', 'tourism:viewpoint'),
            ('polideportivo', 'leisure:sports_centre'),
            ('mercado', 'amenity:marketplace'),
          ]);
          break;
        case Appetite.socializar:
          out.addAll([
            ('bar', 'amenity:bar'),
            ('cafetería', 'amenity:cafe'),
            ('taberna', 'amenity:bar'),
            ('heladería', 'amenity:ice_cream'),
          ]);
          break;
        case Appetite.diferente:
          out.addAll([
            ('mercado', 'amenity:marketplace'),
            ('parque', 'leisure:park'),
            ('mirador', 'tourism:viewpoint'),
          ]);
          break;
      }
    }
    final seen = <String>{};
    return [
      for (final q in out)
        if (seen.add('${q.$1}|${q.$2}')) q,
    ].take(9).toList();
  }

  /// Une listas sin duplicados por nombre (prioridad: Overpass > Wikipedia
  /// > Photon, en el orden en que se pasan).
  static List<Place> _mergePlaces(List<List<Place>> lists) {
    final out = <Place>[];
    final seen = <String>{};
    for (final list in lists) {
      for (final p in list) {
        if (seen.add(_normName(p.title))) out.add(p);
      }
    }
    return out;
  }

  /// Une listas de rutas sin duplicados por nombre (prioridad: Overpass > Komoot).
  static List<PlanRoute> _mergeRoutes(List<List<PlanRoute>> lists) {
    final out = <PlanRoute>[];
    final seen = <String>{};
    for (final list in lists) {
      for (final r in list) {
        if (seen.add(r.title.toLowerCase().trim())) out.add(r);
      }
    }
    return out;
  }

  static String _normName(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  static MoveMode _moveModeFor(String label) {
    switch (label) {
      case 'a pie':
        return MoveMode.pie;
      case 'bici':
        return MoveMode.bici;
      case 'patinete':
        return MoveMode.patinete;
      case 'coche':
      case 'moto':
      case 'taxi':
        return MoveMode.coche;
      case 'bus-metro':
      case 'tren':
        return MoveMode.transporte;
      default:
        return MoveMode.indiferente;
    }
  }

  static double _radiusFor(MoveMode mode) {
    switch (mode) {
      case MoveMode.pie:
        return 10;
      case MoveMode.bici:
      case MoveMode.patinete:
        return 15;
      case MoveMode.transporte:
        return 25;
      case MoveMode.coche:
        return 40;
      case MoveMode.indiferente:
        return 20;
    }
  }

  /// Ubicación EXACTA (GPS alta precisión) con error VISIBLE en banner +
  /// SnackBar rojo. Al lograrse, actualiza el cuadro de texto.
  Future<void> _requestExact() async {
    if (_locatingExact) return;
    setState(() => _locatingExact = true);
    _setStatus(null);
    try {
      final res = await LocationService.requestExactDetailed();
      if (!mounted) return;
      if (!res.ok || res.location == null) {
        setState(() => _locatingExact = false);
        _showVisibleMessage(
          res.error ?? 'No se pudo obtener la ubicación exacta.',
          isError: true,
        );
        return;
      }
      final loc = res.location!;
      setState(() {
        _lat = loc.lat;
        _lng = loc.lng;
        _geoLabel = loc.label.isEmpty ? null : loc.label;
        if (loc.label.isNotEmpty && loc.label != 'Ubicación aproximada') {
          _placeController.text = loc.label;
        }
        _locatingExact = false;
      });
      if (loc.lat != null && loc.lng != null && loc.label.isNotEmpty) {
        unawaited(_savePlace(loc.lat!, loc.lng!, loc.label));
      }
      _showVisibleMessage('Ubicación exacta lista: ${loc.label}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _locatingExact = false);
      _showVisibleMessage('No se pudo obtener la ubicación exacta.', isError: true);
    }
  }

  /// Ubicación APROXIMADA (rápida, poco gasto batería) + actualiza el cuadro.
  Future<void> _requestApproximate() async {
    if (_locatingApprox) return;
    setState(() => _locatingApprox = true);
    _setStatus(null);
    try {
      final res = await LocationService.requestApproximateDetailed();
      if (!mounted) return;
      if (!res.ok || res.location == null) {
        setState(() => _locatingApprox = false);
        _showVisibleMessage(
          res.error ?? 'No se pudo obtener la ubicación aproximada.',
          isError: true,
        );
        return;
      }
      final loc = res.location!;
      setState(() {
        _lat = loc.lat;
        _lng = loc.lng;
        _geoLabel = loc.label.isEmpty ? null : loc.label;
        if (loc.label.isNotEmpty && loc.label != 'Ubicación aproximada') {
          _placeController.text = loc.label;
        }
        _locatingApprox = false;
      });
      if (loc.lat != null && loc.lng != null && loc.label.isNotEmpty) {
        unawaited(_savePlace(loc.lat!, loc.lng!, loc.label));
      }
      _showVisibleMessage('Ubicación aproximada: ${loc.label}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _locatingApprox = false);
      _showVisibleMessage('No se pudo obtener la ubicación.', isError: true);
    }
  }

  /// Autocompletado con debounce: a partir de 3 letras consulta Nominatim.
  void _onPlaceChanged(String value) {
    _debounce?.cancel();
    // Si edita a mano, las coords GPS dejan de valer.
    _lat = null;
    _lng = null;
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _searchingPlaces = false;
      });
      return;
    }
    setState(() => _searchingPlaces = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final list = await _geocoding.autocomplete(value.trim(), limit: 6);
        if (!mounted) return;
        setState(() {
          _suggestions = list;
          _searchingPlaces = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _searchingPlaces = false);
      }
    });
    setState(() {});
  }

  void _pickSuggestion(PlaceSuggestion s) {
    _debounce?.cancel();
    setState(() {
      _placeController.text = s.shortLabel;
      _lat = s.lat;
      _lng = s.lng;
      _geoLabel = s.shortLabel;
      _suggestions = [];
      _searchingPlaces = false;
      _statusInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: (_showResults)
            ? IconButton(
                icon: const Icon(Icons.edit_rounded),
                color: PartyColors.text,
                tooltip: 'Editar respuestas',
                onPressed: () {
                  // UNA sola fuente de verdad: `_step`. Reseteo del índice
                  // y salto a la página 0 en el MISMO setState para que
                  // dots y tarjeta siempre coincidan.
                  setState(() {
                    _showResults = false;
                    _drag = Offset.zero;
                    _step = 0;
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                    }
                  });
                  // El PageView se reconstruye al salir de resultados
                  // (sin clientes durante el setState): asegura la página 0.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients &&
                        (_pageController.page?.round() ?? 0) != 0) {
                      _pageController.jumpToPage(0);
                    }
                  });
                },
              )
            : null,
        title: Text(
          'CREADOR DE PLANES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            color: PartyColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            color: PartyColors.text,
            tooltip: 'Historial',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: PartyColors.scaffoldGradient.take(3).toList(),
          ),
        ),
        child: SafeArea(
          child: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _stage.isEmpty
                              ? 'Generando planes reales…'
                              : _stage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PartyColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Busco sitios de verdad cerca de ti y calculo costes. Tarda unos segundos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: PartyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _showResults
                  ? _ResultsDeck(
                      results: _results,
                      error: _error,
                      generatedOnce: _generatedOnce,
                      drag: _drag,
                      likedIds: _likedIds,
                      dislikedIds: _dislikedIds,
                      onDrag: (d) => setState(() => _drag = d),
                      onDragEnd: _onDeckDragEnd,
                      onLike: () {
                        if (_results.isNotEmpty) {
                          _saveLikedPlan(_results.first);
                        }
                      },
                      onDislike: () {
                        if (_results.isNotEmpty) {
                          _saveDislikedId(_results.first.id);
                        }
                      },
                      onMaps: (p) => _openMaps(p),
                      onRetry: _generate,
                      onMore: _generate,
                      onExpandRadius: _expandRadius,
                      locationLabel: _lastSearchLabel,
                      onEvents:
                          (_lastSearchLabel ?? '').trim().isNotEmpty
                              ? _openEventsSearch
                              : null,
                      onSave: (p) => _savePlanToSaved(p),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (i) =>
                                setState(() => _step = i),
                            children: [
                              _QuestionShell(
                                seed: _seeds[0],
                                title: '¿Con quién vas?',
                                subtitle: 'Elige una opción',
                                child: _OptionGrid(
                                  options: _withWhomOpts,
                                  selected: {_withWhom},
                                  multi: false,
                                  onTap: (o) =>
                                      setState(() => _withWhom = o),
                                ),
                              ),
                              _QuestionShell(
                                seed: _seeds[1],
                                title: '¿Qué te apetece?',
                                subtitle: 'Elige de 1 a 3',
                                child: _OptionGrid(
                                  options: _appetiteOpts,
                                  selected: _appetites,
                                  multi: true,
                                  onTap: (o) => setState(() {
                                    final next = Set<String>.of(_appetites);
                                    if (next.contains(o)) {
                                      next.remove(o);
                                    } else if (next.length < 3) {
                                      next.add(o);
                                    }
                                    _appetites = next;
                                  }),
                                ),
                              ),
                              _QuestionShell(
                                seed: _seeds[2],
                                title: '¿Cuánto tiempo tienes?',
                                subtitle: 'Elige una opción',
                                child: _OptionGrid(
                                  options: _timeOpts,
                                  selected: {_timeLabel},
                                  multi: false,
                                  onTap: (o) =>
                                      setState(() => _timeLabel = o),
                                ),
                              ),
                              _QuestionShell(
                                seed: 'timeofday',
                                title: '¿Qué franja horaria?',
                                subtitle: 'Afecta al tiempo y horarios',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _OptionGrid(
                                      options: _timeOfDayOpts,
                                      selected: {_timeOfDay},
                                      multi: false,
                                      onTap: (o) =>
                                          setState(() => _timeOfDay = o),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _pickPlanDate,
                                            icon: const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              _planDate == null
                                                  ? 'Elegir fecha del plan'
                                                  : 'Plan para ${_planDate!.day}/${_planDate!.month}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            ),
                                          ),
                                        if (_planDate != null)
                                          TextButton(
                                            onPressed: () =>
                                                setState(() => _planDate = null),
                                            child: const Text(
                                              'Quitar fecha',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (_weatherLoading)
                                      const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    else if (_weatherHour != null)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: PartyColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: PartyColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _weatherHour!.emoji,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tiempo previsto',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          PartyColors
                                                              .textMuted,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${_weatherHour!.description}, ${_weatherHour!.temperatureC.toStringAsFixed(0)}°C · ${_weatherHour!.precipitationProbability}% lluvia',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          PartyColors.text,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _QuestionShell(
                                seed: _seeds[3],
                                title: '¿Presupuesto por persona?',
                                subtitle:
                                    '${_budgetPresetFor(_budgetValue).label} por persona',
                                child: _OptionGrid(
                                  options: [
                                    for (final b in _budgetOpts)
                                      _Opt(b.label, b.emoji, b.icon),
                                  ],
                                  selected: {
                                    _budgetPresetFor(_budgetValue).label,
                                  },
                                  multi: false,
                                  onTap: (label) => setState(() {
                                    _budgetValue = _budgetOpts
                                        .firstWhere(
                                          (b) => b.label == label,
                                        )
                                        .value;
                                  }),
                                ),
                              ),
                              _QuestionShell(
                                seed: _seeds[4],
                                title: '¿Dónde estás?',
                                subtitle: _geoLabel == null
                                    ? 'Escribe tu pueblo o usa el GPS'
                                    : '📍 Cerca de $_geoLabel',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _placeController,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Ej. Villanueva del Pardillo, Malasaña…',
                                        border:
                                            const OutlineInputBorder(),
                                        isDense: true,
                                        suffixIcon:
                                            _searchingPlaces
                                                ? const Padding(
                                                  padding:
                                                      EdgeInsets.all(
                                                        10,
                                                      ),
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth:
                                                          2,
                                                    ),
                                                  ),
                                                )
                                                : (_placeController
                                                        .text
                                                        .trim()
                                                        .isNotEmpty
                                                    ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 18,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _placeController.clear();
                                                          _suggestions =
                                                              [];
                                                          _lat =
                                                              null;
                                                          _lng =
                                                              null;
                                                          _geoLabel =
                                                              null;
                                                        });
                                                      },
                                                    )
                                                    : null),
                                      ),
                                      onChanged: _onPlaceChanged,
                                    ),
                                    if (_suggestions.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PartyColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(
                                                12,
                                              ),
                                          border: Border.all(
                                            color: PartyColors.border,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            for (final s in _suggestions)
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _pickSuggestion(s),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.place_rounded,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                s.shortLabel,
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight.w800,
                                                                  color:
                                                                      PartyColors.text,
                                                                ),
                                                              ),
                                                              Text(
                                                                s.label,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color:
                                                                      PartyColors
                                                                          .textMuted,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed:
                                                _locatingExact
                                                    ? null
                                                    : _requestExact,
                                            icon:
                                                _locatingExact
                                                    ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth:
                                                            2,
                                                      ),
                                                    )
                                                    : const Icon(
                                                      Icons.my_location_rounded,
                                                      size: 16,
                                                    ),
                                            label: Text(
                                              _lat == null
                                                  ? 'GPS exacto'
                                                  : 'GPS listo ✓',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed:
                                                _locatingApprox
                                                    ? null
                                                    : _requestApproximate,
                                            icon:
                                                _locatingApprox
                                                    ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth:
                                                            2,
                                                      ),
                                                    )
                                                    : const Icon(
                                                      Icons.location_city_rounded,
                                                      size: 16,
                                                    ),
                                            label: const Text(
                                              'Aproximada',
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_statusInfo != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              _statusIsError
                                                  ? Colors.red.shade700
                                                  : PartyColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color:
                                                _statusIsError
                                                    ? Colors.red.shade200
                                                    : PartyColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          _statusInfo!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_lat != null &&
                                        _lng != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Coords: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)} · se guarda para la próxima',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      PartyColors.textMuted,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _forgetPlace,
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Olvidar',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _QuestionShell(
                                seed: _seeds[5],
                                title: '¿Cómo te mueves?',
                                subtitle: 'Elige una opción',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _OptionGrid(
                                      options: _transportOpts,
                                      selected: {_transport},
                                      multi: false,
                                      onTap: (o) =>
                                          setState(
                                            () => _transport = o,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '¿Hasta dónde? (en $_transport)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: PartyColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _DistanceChip(
                                          label: 'Auto',
                                          selected: _maxKm == null,
                                          onTap: () => _saveMaxKm(null),
                                        ),
                                        for (final km in [
                                          10.0,
                                          25.0,
                                          50.0,
                                          100.0,
                                          200.0,
                                        ])
                                          _DistanceChip(
                                            label:
                                                '${km.toStringAsFixed(0)} km',
                                            selected: _maxKm == km,
                                            onTap:
                                                () => _saveMaxKm(km),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _maxKm == null
                                          ? 'Auto: busco a ${_radiusFor(_moveModeFor(_transport)).toStringAsFixed(0)} km en $_transport.'
                                          : 'Buscaré planes hasta ${_maxKm!.toStringAsFixed(0)} km (te digo cómo ir y cuánto tardas).',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: PartyColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _DotsRow(step: _step, total: _totalSteps),
                        _NavRow(
                          step: _step,
                          total: _totalSteps,
                          isLast: _step == _totalSteps - 1,
                          onBack: _step == 0
                              ? null
                              : () => _goTo(_step - 1),
                          onNext: _next,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  void _onDeckDragEnd() {
    if (_results.isEmpty) {
      setState(() => _drag = Offset.zero);
      return;
    }
    if (_drag.dx > 110) {
      _saveLikedPlan(_results.first);
    } else if (_drag.dx < -110) {
      _saveDislikedId(_results.first.id);
    } else {
      setState(() => _drag = Offset.zero);
    }
  }
}

extension _NonEmptySet<T> on Set<T> {
  Set<T> ifEmpty(Set<T> fallback) => isEmpty ? fallback : this;
}

/// Cabecera con imagen picsum + título grande + control abajo.
class _QuestionShell extends StatelessWidget {
  final String seed;
  final String title;
  final String subtitle;
  final Widget child;

  const _QuestionShell({
    required this.seed,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://picsum.photos/seed/$seed/800/400',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 800,
                  filterQuality: FilterQuality.low,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            PartyColors.primary,
                            PartyColors.surface,
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          PartyColors.primary,
                          PartyColors.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Opción seleccionable (valor + emoji + icono) para el grid de tarjetas.
class _Opt {
  final String value;
  final String emoji;
  final IconData icon;

  const _Opt(this.value, this.emoji, this.icon);
}

/// Tramo de presupuesto por persona (etiqueta + valor representativo que
/// alimenta el `BudgetRange` del intent; `initialAnswers.budgetValue`
/// numérico sigue funcionando).
class _BudgetOpt {
  final String label;
  final String emoji;
  final IconData icon;
  final double value;

  const _BudgetOpt(this.label, this.emoji, this.icon, this.value);
}

/// Grid de tarjetas seleccionables (icono + emoji) en vez de chips planos.
class _OptionGrid extends StatelessWidget {
  final List<_Opt> options;
  final Set<String> selected;
  final bool multi;
  final ValueChanged<String> onTap;

  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.92,
          children: [
            for (final o in options)
              _OptionCard(
                opt: o,
                isSelected: selected.contains(o.value),
                onTap: () => onTap(o.value),
              ),
          ],
        ),
        if (multi)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${selected.length}/3 elegidos',
              style: TextStyle(
                fontSize: 12,
                color: PartyColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final _Opt opt;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.opt,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? PartyColors.primary
        : PartyColors.border;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? PartyColors.primary.withValues(alpha: 0.12)
              : PartyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  opt.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                if (isSelected)
                  const Positioned(
                    right: -14,
                    top: -8,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: PartyColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Icon(opt.icon, size: 16, color: PartyColors.primary),
            const SizedBox(height: 4),
            Text(
              opt.value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
                color: PartyColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de distancia máxima (Auto / 10 / 25 / 50 / 100 / 200 km).
class _DistanceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DistanceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? PartyColors.primary.withValues(alpha: 0.14)
              : PartyColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? PartyColors.primary : PartyColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? PartyColors.primary : PartyColors.text,
          ),
        ),
      ),
    );
  }
}

class _DotsRow extends StatelessWidget {
  final int step;
  final int total;

  const _DotsRow({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: i == step ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == step
                    ? PartyColors.primary
                    : PartyColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final int step;
  final int total;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _NavRow({
    required this.step,
    required this.total,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 12 + bottomPad),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Atrás'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: PartyColors.primary,
                foregroundColor: PartyColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(isLast ? 'GENERAR' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deck tinder fullscreen: 3 apiladas, arrastre real en la superior.
class _ResultsDeck extends StatelessWidget {
  final List<PlanMock> results;
  final String? error;
  final bool generatedOnce;
  final Offset drag;
  final Set<String> likedIds;
  final Set<String> dislikedIds;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final ValueChanged<PlanMock> onMaps;
  final VoidCallback onRetry;
  final VoidCallback onMore;
  final VoidCallback? onExpandRadius;
  final String? locationLabel;
  final VoidCallback? onEvents;
  final ValueChanged<PlanMock>? onSave;

  const _ResultsDeck({
    required this.results,
    required this.error,
    required this.generatedOnce,
    required this.drag,
    required this.likedIds,
    required this.dislikedIds,
    required this.onDrag,
    required this.onDragEnd,
    required this.onLike,
    required this.onDislike,
    required this.onMaps,
    required this.onRetry,
    required this.onMore,
    this.onExpandRadius,
    this.locationLabel,
    this.onEvents,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (!generatedOnce) {
      return const Center(child: Text('Genera planes para verlos aquí.'));
    }
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: PartyColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Reintentar búsqueda'),
              ),
              const SizedBox(height: 8),
              if (onExpandRadius != null)
                OutlinedButton(
                  onPressed: onExpandRadius,
                  child: const Text('Ampliar radio de búsqueda'),
                ),
            ],
          ),
        ),
      );
    }
    final visible = results.take(3).toList().reversed.toList();
    return Column(
      children: [
        if ((locationLabel ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: Text(
              '📍 Cerca de ${locationLabel!.trim()}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: PartyColors.text,
              ),
            ),
          ),
        if (onEvents != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            child: GestureDetector(
              onTap: onEvents,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PartyColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '🎪 Fiestas, ferias y eventos en ${locationLabel!.trim()}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.primary,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quedan ${results.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PartyColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PartyColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    '🔀 Ver otros',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: PartyColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      _stackedCard(
                        context,
                        plan: visible[i],
                        depth: visible.length - 1 - i,
                        isTop: i == visible.length - 1,
                        maxH: constraints.maxHeight,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundBtn(
                icon: Icons.close_rounded,
                bg: PartyColors.surface,
                fg: Colors.redAccent,
                onTap: onDislike,
              ),
              const SizedBox(width: 18),
              _RoundBtn(
                icon: Icons.map_rounded,
                bg: PartyColors.surface,
                fg: PartyColors.primary,
                small: true,
                onTap: () => onMaps(results.first),
              ),
              const SizedBox(width: 18),
              _RoundBtn(
                icon: Icons.favorite_rounded,
                bg: PartyColors.primary,
                fg: Colors.white,
                onTap: onLike,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _stackedCard(
    BuildContext context, {
    required PlanMock plan,
    required int depth,
    required bool isTop,
    required double maxH,
  }) {
    final scale = 1.0 - depth * 0.06;
    final dy = depth * 12.0;
    final rot = isTop ? (drag.dx / 900).clamp(-0.25, 0.25) : 0.0;
    Widget card = _TinderCard(
      plan: plan,
      dragDx: isTop ? drag.dx : 0,
      onMaps: () => onMaps(plan),
      onSave: onSave != null ? () => onSave!(plan) : null,
    );
    if (isTop) {
      card = GestureDetector(
        onPanUpdate: (d) => onDrag(drag + d.delta),
        onPanEnd: (_) => onDragEnd(),
        child: Transform.translate(
          offset: drag,
          child: Transform.rotate(angle: rot, child: card),
        ),
      );
    }
    return Positioned.fill(
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Transform.translate(offset: Offset(0, dy), child: card),
      ),
    );
  }
}

class _TinderCard extends StatelessWidget {
  final PlanMock plan;
  final double dragDx;
  final VoidCallback onMaps;
  final VoidCallback? onSave;

  const _TinderCard({
    required this.plan,
    required this.dragDx,
    required this.onMaps,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PartyColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 10),
            color: Color(0x33000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Imagen + emoji de fuente + chip fuente ----
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  plan.imageUrl,
                  key: ValueKey(plan.imageUrl),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 600,
                  filterQuality: FilterQuality.low,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            PartyColors.primary,
                            PartyColors.surface,
                          ],
                        ),
                      ),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    );
                  },
                  frameBuilder: (ctx, child, frame, sync) {
                    if (frame == null) return child;
                    return child;
                  },
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          PartyColors.primary,
                          PartyColors.surface,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      plan.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                // Like / Nope overlay durante arrastre
                if (dragDx.abs() > 20)
                  Align(
                    alignment: dragDx > 0
                        ? Alignment.topLeft
                        : Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dragDx > 0 ? Colors.green : Colors.red,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            dragDx > 0 ? Icons.favorite : Icons.close,
                            color: dragDx > 0 ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dragDx > 0 ? 'GUARDAR' : 'DESCARTAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: dragDx > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Badge de fuente de datos (arriba-izquierda)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: plan.sourceColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          plan.sourceIcon,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plan.sourceLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Título en la imagen
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (plan.sourceLabel.isNotEmpty)
                        Text(
                          'Datos: ${plan.sourceLabel}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ---- Detalles abajo ----
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips de info
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.wallet_rounded,
                        label: plan.costLabel,
                        color: PartyColors.primary,
                      ),
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: plan.duration,
                        color: PartyColors.primary,
                      ),
                      if (plan.distanceLabel != null)
                        _InfoChip(
                          icon: Icons.place_rounded,
                          label: plan.distanceLabel!,
                          color: PartyColors.primary,
                        ),
                      if (plan.weatherLabel != null)
                        _InfoChip(
                          icon: Icons.wb_sunny_rounded,
                          label: plan.weatherLabel!,
                          color: PartyColors.warning,
                        ),
                      _InfoChip(
                        icon: Icons.star_rounded,
                        label: plan.rating.toStringAsFixed(1),
                        color: PartyColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Avisos (tiempo adverso, reserva, etc.)
                  if (plan.warnings.isNotEmpty) ...[
                    for (final w in plan.warnings)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                w,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  if (plan.warnings.isNotEmpty)
                    const SizedBox(height: 8),
                  // Descripción
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: PartyColors.textSecondary,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plan.address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: PartyColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            plan.address,
                            style: TextStyle(
                              fontSize: 11,
                              color: PartyColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMaps,
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Ver en Maps'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSave,
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Guardar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool small;
  final VoidCallback onTap;

  const _RoundBtn({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: small ? 52 : 64,
        height: small ? 52 : 64,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: PartyColors.border),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 4),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Icon(icon, color: fg, size: small ? 22 : 30),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = PartyColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
