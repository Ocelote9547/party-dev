import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sensors_plus/sensors_plus.dart';

import '../services/feedback_service.dart';
import '../services/tilt_service.dart';
import '../theme/party_theme.dart';

/// Notificador global de disponibilidad del sensor de inclinación.
/// Permite a cualquier juego mostrar fallback "usa deslizar".
/// Alias directo al notifier de [TiltService] para cumplir el requisito
/// `ValueNotifier<bool> tiltAvailable` importable desde game_utils.
ValueNotifier<bool> get tiltAvailable => TiltService.instance.tiltAvailable;

/// Sets the preferred screen orientation for a single game screen.
///
/// Call in the game's [State.initState] and remember to call
/// [restoreOrientation] in `dispose`.
void setGameOrientation(List<DeviceOrientation> orientations) {
  SystemChrome.setPreferredOrientations(orientations);
}

/// Restores the app to portrait (menu vertical).
void restoreOrientation() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

/// Banner reutilizable cuando la inclinación no está disponible.
class TiltUnavailableBanner extends StatelessWidget {
  const TiltUnavailableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TiltService.instance.tiltAvailable,
      builder: (context, available, _) {
        if (available) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: PartyColors.warning.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PartyColors.warning.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              const Icon(Icons.screen_rotation_rounded, size: 18, color: PartyColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Inclinación no disponible en este dispositivo — usa deslizar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.text,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wraps content that reacts to a tilt of the phone (accelerometer).
///
/// The phone is placed on the forehead / face down and the player (or group)
/// tilts the device. A sharp tilt on the screen's vertical axis triggers
/// [onTiltForward] (pass) or [onTiltBackward] (accept). Thresholds are
/// configurable to work across devices.
class TiltZone extends StatefulWidget {
  final Widget child;
  final void Function()? onTiltForward;
  final void Function()? onTiltBackward;

  /// Screen axis mapped to up/down. In portrait the natural axis is Y and in
  /// landscape it is X. Defaults to Y (portrait).
  final Axis axis;

  /// Whether tilt detection is enabled. When false, the stream is cancelled.
  final bool enabled;

  /// Acceleration spike threshold (m/s²). The change from baseline must
  /// exceed this value to trigger a tilt event.
  final double spikeThreshold;

  /// Duration after a tilt event during which further events are ignored.
  final Duration lockDuration;

  const TiltZone({
    super.key,
    required this.child,
    this.onTiltForward,
    this.onTiltBackward,
    this.axis = Axis.vertical,
    this.enabled = true,
    this.spikeThreshold = 4.5,
    this.lockDuration = const Duration(milliseconds: 900),
  });

  @override
  State<TiltZone> createState() => _TiltZoneState();
}

class _TiltZoneState extends State<TiltZone> {
  StreamSubscription<AccelerometerEvent>? _sub;
  final _lockUntil = <_TiltDirection, DateTime>{};

  // EMA baseline for acceleration
  double _baselineX = 0.0;
  double _baselineY = 0.0;
  double _baselineZ = 0.0;
  bool _initialized = false;
  int _calibrationCount = 0;
  static const _calibrationWindow = 30;
  static const _emaAlpha = 0.08;

  // Require 3 consecutive readings in same direction to fire (histeresis)
  int _consecutiveForward = 0;
  int _consecutiveBackward = 0;
  DateTime? _lastConsecutiveTime;
  bool _needsNeutral = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(TiltZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startListening();
      } else {
        _sub?.cancel();
        _sub = null;
      }
    }
  }

  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    // Marca sensor no disponible sin crashear; el juego sigue con deslizar/botones.
    _sub?.cancel();
    _sub = null;
    if (kDebugMode) {
      debugPrint('[TiltZone] accelerometer stream error: $error');
    }
    // No tocar tiltAvailable si el usuario lo tiene deshabilitado manualmente,
    // pero sí marcar no disponible para mostrar banner fallback.
    TiltService.instance.tiltAvailable.value = false;
  }

  void _startListening() {
    _sub?.cancel();
    _sub = null;
    if (!widget.enabled) return;
    if (!TiltService.instance.enabled) return;
    try {
      final stream = accelerometerEventStream();
      _sub = stream.listen(
        _onEvent,
        onError: (Object e, StackTrace st) => _handleStreamError(e, st),
        cancelOnError: false,
      );
      // Si el stream se crea correctamente, asumimos disponible hasta error.
      // No pisamos a true si ya estaba en false por error previo permanente.
      // Pero si antes falló y ahora reintentamos, probamos a poner true.
      // Dejamos true por defecto; solo onError lo pone a false.
    } catch (e, st) {
      _handleStreamError(e, st);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _fire(_TiltDirection dir, void Function()? cb) {
    final now = DateTime.now();
    final lockedUntil = _lockUntil[dir];
    if (lockedUntil != null && now.isBefore(lockedUntil)) return;
    _lockUntil[dir] = now.add(widget.lockDuration);
    cb?.call();
    // General tilt feedback (guarded by prefs inside service).
    // Fire-and-forget: do not await.
    FeedbackService.selectionClick();
  }

  void _onEvent(AccelerometerEvent e) {
    if (!mounted) return;
    if (!TiltService.instance.enabled) return;

    // Update baseline with EMA
    if (!_initialized) {
      _baselineX = e.x;
      _baselineY = e.y;
      _baselineZ = e.z;
      _calibrationCount++;
      if (_calibrationCount >= _calibrationWindow) {
        _initialized = true;
      }
      return; // Don't fire during calibration
    }

    // Slow baseline adaptation
    _baselineX = _baselineX * (1 - _emaAlpha) + e.x * _emaAlpha;
    _baselineY = _baselineY * (1 - _emaAlpha) + e.y * _emaAlpha;
    _baselineZ = _baselineZ * (1 - _emaAlpha) + e.z * _emaAlpha;

    // Horizontal (forehead, landscapeLeft) -> gravity on X, tilt forward/back
    // rotates around Y, giving a clear X delta. Vertical uses Y.
    double delta;
    if (widget.axis == Axis.horizontal) {
      delta = e.x - _baselineX;
    } else {
      delta = e.y - _baselineY;
    }

    // Magnitude check: tilt keeps ~9.8, shake/translation spikes magnitude
    final magnitude = (e.x * e.x + e.y * e.y + e.z * e.z);
    // 9.8^2 ≈ 96, allow 55..165 (7.4..12.8) to reject strong shakes
    if (magnitude < 55 || magnitude > 165) {
      // Reset consecutive on strong shake to avoid false trigger after
      _consecutiveForward = 0;
      _consecutiveBackward = 0;
      return;
    }

    double effectiveThreshold = TiltService.instance.threshold;
    // Si acabamos de disparar, esperamos volver a zona neutra antes de permitir otro.
    // Histéresis: para resetear necesita volver a < umbral*0.25 (antes 0.35).
    if (_needsNeutral) {
      if (delta.abs() < effectiveThreshold * 0.25) {
        _needsNeutral = false;
        _consecutiveForward = 0;
        _consecutiveBackward = 0;
      } else {
        return; // aún no volvió al centro, ignora
      }
    }

    // Reset consecutive if too much time passed (gesture must be quick)
    final now = DateTime.now();
    if (_lastConsecutiveTime != null &&
        now.difference(_lastConsecutiveTime!).inMilliseconds > 400) {
      _consecutiveForward = 0;
      _consecutiveBackward = 0;
    }
    _lastConsecutiveTime = now;

    // Require sustained direction: 3 consecutive readings above 70% threshold
    final absDelta = delta.abs();
    if (absDelta > effectiveThreshold * 0.7) {
      if (delta > 0) {
        _consecutiveForward++;
        _consecutiveBackward = 0;
      } else {
        _consecutiveBackward++;
        _consecutiveForward = 0;
      }
    } else {
      _consecutiveForward = 0;
      _consecutiveBackward = 0;
    }

    // Need full threshold + 3 consecutive to actually fire
    if (absDelta > effectiveThreshold) {
      if (widget.axis == Axis.horizontal) {
        // ── MAPEO TILT HORIZONTAL INVERTIDO ──────────────────
        // Horizontal = juego en la frente (landscapeLeft). Gravedad en X.
        // delta X > 0 → inclinación hacia atrás (barbilla arriba) → ACIERTO → onTiltBackward
        // delta X < 0 → inclinación hacia adelante (frente abajo) → PASAR/FALLO → onTiltForward
        // En vertical no se invierte: delta Y >0 → forward, <0 → backward.
        // ─────────────────────────────────────────────────────
        if (delta > 0 && _consecutiveBackward == 0 && _consecutiveForward >= 3) {
          _consecutiveForward = 0;
          _consecutiveBackward = 0;
          _needsNeutral = true;
          _fire(_TiltDirection.backward, widget.onTiltBackward);
        } else if (delta < 0 && _consecutiveForward == 0 && _consecutiveBackward >= 3) {
          _consecutiveForward = 0;
          _consecutiveBackward = 0;
          _needsNeutral = true;
          _fire(_TiltDirection.forward, widget.onTiltForward);
        }
      } else {
        if (delta > 0 && _consecutiveBackward == 0 && _consecutiveForward >= 3) {
          _consecutiveForward = 0;
          _consecutiveBackward = 0;
          _needsNeutral = true;
          _fire(_TiltDirection.forward, widget.onTiltForward);
        } else if (delta < 0 && _consecutiveForward == 0 && _consecutiveBackward >= 3) {
          _consecutiveForward = 0;
          _consecutiveBackward = 0;
          _needsNeutral = true;
          _fire(_TiltDirection.backward, widget.onTiltBackward);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiltEnabled = TiltService.instance.enabledNotifier.value;
    if (!widget.enabled || !tiltEnabled) return widget.child;
    return ValueListenableBuilder<bool>(
      valueListenable: TiltService.instance.enabledNotifier,
      builder: (context, tiltOn, _) {
        if (!widget.enabled || !tiltOn) return widget.child;
        return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _fire(_TiltDirection.backward, widget.onTiltBackward);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _fire(_TiltDirection.forward, widget.onTiltForward);
          return KeyEventResult.handled;
        }
        // also support W/S for web
        if (event.logicalKey == LogicalKeyboardKey.keyW) {
          _fire(_TiltDirection.backward, widget.onTiltBackward);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyS) {
          _fire(_TiltDirection.forward, widget.onTiltForward);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
      },
    );
  }
}

/// Saves game scores to SharedPreferences (accumulates with existing scores).
/// Call this when a game ends to persist the ranking.
Future<void> saveGameScores(Map<String, int> gameScores) async {
  if (gameScores.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('player_scores');
    Map<String, int> all = <String, int>{};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        all = decoded.map((k, v) => MapEntry(k, v is int ? v : (v is num ? v.toInt() : 0)));
      } catch (_) {
        all = <String, int>{};
      }
    }
    for (final entry in gameScores.entries) {
      all[entry.key] = (all[entry.key] ?? 0) + entry.value;
    }
    await prefs.setString('player_scores', jsonEncode(all));
  } catch (_) {}
}

enum _TiltDirection { forward, backward }

/// Returns a random valid index for a list of [length], or 0 when empty.
/// Callers must still avoid using the index when the list is empty.
int safeRandomIndex(int length) => length <= 0 ? 0 : Random().nextInt(length);

/// Last-resort screen when a game is opened without players.
/// GamesScreen already blocks this (minPlayers), so this should never show.
class NeedPlayersScreen extends StatelessWidget {
  final int minPlayers;
  const NeedPlayersScreen({super.key, this.minPlayers = 3});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Se necesitan al menos $minPlayers jugadores',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PartyColors.primary,
                  foregroundColor: PartyColors.onPrimary,
                ),
                child: const Text('VOLVER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón atrás visible para pantallas de juego sin AppBar (adivina, tabú,
/// quién soy, es un 10, dibuja). Usa [Navigator.maybePop] para que se
/// muestre el diálogo de confirmación de salida del [PopScope] del juego,
/// igual que con la flecha del sistema.
class GameBackButton extends StatelessWidget {
  const GameBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PartyColors.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: PartyColors.border),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: PartyColors.text,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
