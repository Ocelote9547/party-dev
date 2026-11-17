import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Singleton SoundService — sonido y vibración funcionales sin assets silenciosos.
///
/// Persiste [soundEnabled] / [vibrationEnabled] en SharedPreferences con
/// claves `sound_enabled` y `vibration_enabled` (compat: también lee/escribe
/// `settings_sound` / `settings_vibration` de [FeedbackService]).
/// Todos los métodos son fire-and-forget y nunca lanzan excepciones
/// (try/catch + web fallback). Usa fallback audible real: SystemSound +
/// HapticFeedback + Vibration + tono generado en memoria vía BytesSource.
///
/// Mejora: pitido agradable con dos tonos (880+1320 acorde), envelope ADSR
/// (attack 5ms, decay 40ms, sustain 0.7, release 40ms) + reverb corta
/// y vibrato opcional. Timbres: tick brillante, countdown grave, success
/// acorde mayor, fail descendente y drone ambiente en loop.
class SoundService {
  static final SoundService instance = SoundService._internal();
  factory SoundService() => instance;
  SoundService._internal();

  static SoundService get I => instance;

  static const String kSoundKey = 'sound_enabled';
  static const String kVibrationKey = 'vibration_enabled';
  static const String kMusicKey = 'music_enabled';
  static const String kLegacySoundKey = 'settings_sound';
  static const String kLegacyVibrationKey = 'settings_vibration';

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool musicEnabled = true;
  bool _initialized = false;
  bool _globalRouteAdded = false;

  AudioPlayer? _player;
  AudioPlayer? _ambientPlayer;

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(0.7);
    return _player!;
  }

  AudioPlayer get _ambientAudioPlayer {
    _ambientPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    return _ambientPlayer!;
  }

  /// Pista deseada para reanudar tras interacción (autoplay web).
  /// Se guarda como closure para reintentar con los mismos parámetros.
  Future<void> Function()? _resumeAttempt;

  /// Se registra una vez: al primer tap en cualquier parte (los navegadores
  /// bloquean el audio hasta que el usuario interactúa), reintenta la
  /// pista deseada si no suena nada.
  void _onGlobalPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    handleUserInteraction();
  }

  Future<void> handleUserInteraction() async {
    final attempt = _resumeAttempt;
    if (attempt == null) return;
    if (!soundEnabled || !musicEnabled) return;
    // Si ya suena algo confirmado, no reiniciar.
    if (currentTrack != null) return;
    try {
      await attempt();
    } catch (_) {}
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
      _globalRouteAdded = true;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(kSoundKey)) {
        soundEnabled = prefs.getBool(kSoundKey) ?? true;
      } else if (prefs.containsKey(kLegacySoundKey)) {
        soundEnabled = prefs.getBool(kLegacySoundKey) ?? true;
      }
      if (prefs.containsKey(kVibrationKey)) {
        vibrationEnabled = prefs.getBool(kVibrationKey) ?? true;
      } else if (prefs.containsKey(kLegacyVibrationKey)) {
        vibrationEnabled = prefs.getBool(kLegacyVibrationKey) ?? true;
      }
      // Música ambiente: por defecto activada.
      musicEnabled = prefs.getBool(kMusicKey) ?? true;
      if (kDebugMode) {
        debugPrint('[SoundService] init sound=$soundEnabled vibration=$vibrationEnabled music=$musicEnabled');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SoundService] init error $e');
    }
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  Future<void> toggleSound(bool value) async {
    soundEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kSoundKey, value);
      await prefs.setBool(kLegacySoundKey, value);
    } catch (_) {}
    if (value) {
      await playTick();
      await vibrateShort();
    } else {
      await stopAmbient();
    }
  }

  Future<void> toggleVibration(bool value) async {
    vibrationEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kVibrationKey, value);
      await prefs.setBool(kLegacyVibrationKey, value);
    } catch (_) {}
    if (value) {
      await vibrateShort();
    }
  }

  /// Activa/desactiva solo la música ambiente (persistido en `music_enabled`).
  Future<void> toggleMusic(bool value) async {
    musicEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kMusicKey, value);
    } catch (_) {}
    if (!value) {
      await stopAmbient();
    } else {
      // Se reactiva desde ajustes (menú): reanuda la pista del menú.
      await playMenuLoop();
    }
  }

  // ---------------------------------------------------------------------------
  // Generación de WAV en memoria (tono real sin assets)
  // Envelope ADSR + reverb corta + vibrato + dos senos
  // ---------------------------------------------------------------------------

  Uint8List _generateToneWav({
    required double freq,
    double? freq2,
    double? freq3,
    required int durationMs,
    int sampleRate = 44100,
    double volume = 0.6,
    bool vibrato = false,
    bool descending = false,
    double descendingEndFreq = 120,
  }) {
    final numSamples = (sampleRate * durationMs ~/ 1000);
    final dataBytes = numSamples * 2; // 16-bit mono
    final totalBytes = 44 + dataBytes;
    final buffer = Uint8List(totalBytes);
    final bd = ByteData.view(buffer.buffer);

    // RIFF header
    buffer[0] = 0x52; // R
    buffer[1] = 0x49; // I
    buffer[2] = 0x46; // F
    buffer[3] = 0x46; // F
    bd.setUint32(4, 36 + dataBytes, Endian.little);
    buffer[8] = 0x57; // W
    buffer[9] = 0x41; // A
    buffer[10] = 0x56; // V
    buffer[11] = 0x45; // E
    // fmt chunk
    buffer[12] = 0x66; // f
    buffer[13] = 0x6D; // m
    buffer[14] = 0x74; // t
    buffer[15] = 0x20; // ' '
    bd.setUint32(16, 16, Endian.little); // PCM fmt size
    bd.setUint16(20, 1, Endian.little); // PCM
    bd.setUint16(22, 1, Endian.little); // mono
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bd.setUint16(32, 2, Endian.little); // block align
    bd.setUint16(34, 16, Endian.little); // bits per sample
    // data chunk
    buffer[36] = 0x64; // d
    buffer[37] = 0x61; // a
    buffer[38] = 0x74; // t
    buffer[39] = 0x61; // a
    bd.setUint32(40, dataBytes, Endian.little);

    // ADSR params
    const attackMs = 5;
    const decayMs = 35;
    const releaseMs = 60;
    const sustainLevel = 0.70;
    final attackSamples = sampleRate * attackMs ~/ 1000;
    final decaySamples = sampleRate * decayMs ~/ 1000;
    final releaseSamples = sampleRate * releaseMs ~/ 1000;

    // Reverb corta: delay 28ms, mezcla 0.18 con decaimiento
    final delaySamples = sampleRate * 28 ~/ 1000;
    const reverbMix = 0.16;
    final floatSamples = List<double>.filled(numSamples, 0.0);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Frecuencia efectiva (vibrato o descending)
      double f = freq;
      if (descending) {
        final progress = i / numSamples;
        f = freq + (descendingEndFreq - freq) * progress;
      } else if (vibrato) {
        const vibRate = 6.5; // Hz
        const vibDepth = 12.0; // Hz
        f = freq + math.sin(2 * math.pi * vibRate * t) * vibDepth;
      }

      // Dos/tres senos sumados para acorde más agradable
      double sample = math.sin(2 * math.pi * f * t);
      if (freq2 != null) {
        // segundo tono más suave (-3dB)
        sample += 0.65 * math.sin(2 * math.pi * freq2 * t + 0.3);
        if (freq3 != null) {
          sample += 0.5 * math.sin(2 * math.pi * freq3 * t + 0.6);
          sample /= 2.15;
        } else {
          sample /= 1.65;
        }
      } else if (vibrato) {
        // leve segundo armónico para brillo
        sample = 0.75 * sample + 0.25 * math.sin(2 * math.pi * f * 2 * t);
      }

      // Envelope ADSR
      double env;
      if (i < attackSamples) {
        env = i / attackSamples;
      } else if (i < attackSamples + decaySamples) {
        final p = (i - attackSamples) / decaySamples;
        env = 1.0 - (1.0 - sustainLevel) * p;
      } else if (i >= numSamples - releaseSamples) {
        env = sustainLevel * (numSamples - i) / releaseSamples;
      } else {
        env = sustainLevel;
      }
      // Curva suave attack (ease)
      if (i < attackSamples) env = math.pow(env, 0.7).toDouble();

      floatSamples[i] = sample * volume * env;
    }

    // Reverb corta: añadir eco simple con decaimiento
    for (int i = delaySamples; i < numSamples; i++) {
      floatSamples[i] += floatSamples[i - delaySamples] * reverbMix * 0.9;
    }

    // Normalizar si reverb excede 1.0 y escribir PCM
    double maxAbs = 0;
    for (final v in floatSamples) {
      final a = v.abs();
      if (a > maxAbs) maxAbs = a;
    }
    final norm = maxAbs > 1.0 ? 1.0 / maxAbs : 1.0;

    for (int i = 0; i < numSamples; i++) {
      var s = floatSamples[i] * norm;
      // soft clipping
      s = s.clamp(-1.0, 1.0);
      final pcm = (s * 32767).toInt();
      bd.setInt16(44 + i * 2, pcm, Endian.little);
    }
    return buffer;
  }

  Uint8List _generateChordWav({
    required List<double> freqs,
    required int durationMs,
    double volume = 0.5,
    int sampleRate = 44100,
  }) {
    return _generateToneWav(
      freq: freqs[0],
      freq2: freqs.length > 1 ? freqs[1] : null,
      freq3: freqs.length > 2 ? freqs[2] : null,
      durationMs: durationMs,
      sampleRate: sampleRate,
      volume: volume,
    );
  }

  Future<void> _playTone({
    required double freq,
    double? freq2,
    double? freq3,
    required int durationMs,
    double volume = 0.5,
    bool vibrato = false,
  }) async {
    try {
      final wav = _generateToneWav(
        freq: freq,
        freq2: freq2,
        freq3: freq3,
        durationMs: durationMs,
        volume: volume,
        vibrato: vibrato,
      );
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(wav));
    } catch (_) {}
  }

  Future<void> _playChord({
    required List<double> freqs,
    required int durationMs,
    double volume = 0.5,
  }) async {
    try {
      final wav = _generateChordWav(freqs: freqs, durationMs: durationMs, volume: volume);
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(wav));
    } catch (_) {}
  }

  Future<void> _playDescending({
    required double startFreq,
    required double endFreq,
    required int durationMs,
    double volume = 0.55,
  }) async {
    try {
      final wav = _generateToneWav(
        freq: startFreq,
        durationMs: durationMs,
        volume: volume,
        descending: true,
        descendingEndFreq: endFreq,
      );
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(wav));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Pad ambiente cálido en loop (acorde mayor La mayor: A3+C#4+E4, senos
  // a volumen muy bajo con fade in/out para que no se note el corte).
  // ---------------------------------------------------------------------------

  /// Genera un buffer WAV estéreo-mono cálido para loop sin clics:
  /// senos puros + envolvente de fade in/out (raised-cosine) + leve LFO.
  Uint8List _generateAmbientPadWav({
    int durationMs = 8000,
    int fadeMs = 3000,
    int sampleRate = 44100,
    double volume = 0.04,
  }) {
    final numSamples = sampleRate * durationMs ~/ 1000;
    final fadeSamples = (sampleRate * fadeMs ~/ 1000).clamp(1, numSamples ~/ 2);
    final dataBytes = numSamples * 2; // 16-bit mono
    final totalBytes = 44 + dataBytes;
    final buffer = Uint8List(totalBytes);
    final bd = ByteData.view(buffer.buffer);

    // RIFF header
    buffer[0] = 0x52; // R
    buffer[1] = 0x49; // I
    buffer[2] = 0x46; // F
    buffer[3] = 0x46; // F
    bd.setUint32(4, 36 + dataBytes, Endian.little);
    buffer[8] = 0x57; // W
    buffer[9] = 0x41; // A
    buffer[10] = 0x56; // V
    buffer[11] = 0x45; // E
    buffer[12] = 0x66; // f
    buffer[13] = 0x6D; // m
    buffer[14] = 0x74; // t
    buffer[15] = 0x20; // ' '
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    buffer[36] = 0x64; // d
    buffer[37] = 0x61; // a
    buffer[38] = 0x74; // t
    buffer[39] = 0x61; // a
    bd.setUint32(40, dataBytes, Endian.little);

    // Acorde mayor cálido: A3 (220) + C#4 (277.18) + E4 (329.63).
    const f1 = 220.0;
    const f2 = 277.18;
    const f3 = 329.63;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Senos puros con amplitudes equilibradas; leve respiración (LFO 0.1Hz).
      final lfo = 0.85 + 0.15 * math.sin(2 * math.pi * 0.1 * t);
      double sample = (math.sin(2 * math.pi * f1 * t) * 0.4 +
              math.sin(2 * math.pi * f2 * t) * 0.33 +
              math.sin(2 * math.pi * f3 * t) * 0.27) *
          lfo;
      // Envolvente raised-cosine: fade in al inicio y fade out al final
      // para que el punto de loop (ReleaseMode.loop) no tenga clic.
      double env = 1.0;
      if (i < fadeSamples) {
        env = 0.5 - 0.5 * math.cos(math.pi * i / fadeSamples);
      } else if (i >= numSamples - fadeSamples) {
        final j = numSamples - 1 - i;
        env = 0.5 - 0.5 * math.cos(math.pi * j / fadeSamples);
      }
      final s = (sample * volume * env).clamp(-1.0, 1.0);
      bd.setInt16(44 + i * 2, (s * 32767).toInt(), Endian.little);
    }
    return buffer;
  }

  Future<void> playAmbient() async => playAmbientLoop();

  /// Pista actual sonando: 'menu', 'game' o null.
  String? currentTrack;

  int _fadeVersion = 0;
  double _lastAmbientVolume = 0.0;

  /// Rampa de volumen con easing suave. Un fade nuevo cancela el anterior.
  /// Devuelve false si el fade abortó por error (para no dejar estado stale).
  Future<bool> _rampAmbientVolume(double target, {int durationMs = 700}) async {
    final version = ++_fadeVersion;
    const stepMs = 50;
    final steps = (durationMs ~/ stepMs).clamp(1, 40);
    final start = _lastAmbientVolume;
    for (var i = 1; i <= steps; i++) {
      if (version != _fadeVersion) return true; // Superseded: otro fade manda.
      final t = i / steps;
      final eased = t * t * (3 - 2 * t); // smoothstep
      final v = (start + (target - start) * eased).clamp(0.0, 1.0);
      _lastAmbientVolume = v;
      try {
        await _ambientAudioPlayer.setVolume(v);
      } catch (_) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: stepMs));
    }
    return true;
  }

  /// Reproduce una pista musical en loop con un solo AudioPlayer.
  /// Intenta primero `assets/sounds/<asset>` (mp3/wav del usuario) y si no
  /// existe usa el pad generado como fallback. Consume pocos recursos.
  Future<void> _playMusicTrack({
    required String asset,
    required String track,
    required Uint8List Function() fallbackWav,
    double volume = 0.3,
  }) async {
    _resumeAttempt = () => _playMusicTrack(
          asset: asset,
          track: track,
          fallbackWav: fallbackWav,
          volume: volume,
        );
    try {
      await _ensureInit();
      if (!soundEnabled || !musicEnabled) {
        currentTrack = null;
        return;
      }
      _fadeVersion++; // Cancela cualquier fade anterior.
      try {
        await _ambientAudioPlayer.stop();
      } catch (_) {}
      try {
        await _ambientAudioPlayer.setReleaseMode(ReleaseMode.loop);
      } catch (_) {}
      // Arranca en silencio y sube con fade para evitar cortes.
      _lastAmbientVolume = 0.0;
      try {
        await _ambientAudioPlayer.setVolume(0.0);
      } catch (_) {}
      // Estado honesto: null hasta confirmar que suena.
      currentTrack = null;
      var played = false;
      try {
        await _ambientAudioPlayer.play(AssetSource(asset));
        played = true;
      } catch (_) {
        try {
          // Sin mp3/wav del usuario: pad generado como fallback.
          await _ambientAudioPlayer.play(BytesSource(fallbackWav()));
          played = true;
        } catch (_) {}
      }
      if (!played) {
        _scheduleMusicRetry(() => _playMusicTrack(
              asset: asset,
              track: track,
              fallbackWav: fallbackWav,
              volume: volume,
            ));
        return;
      }
      currentTrack = track;
      _musicRetryCount = 0;
      final rampOk = await _rampAmbientVolume(volume, durationMs: 800);
      if (!rampOk) {
        // El fade abortó: no dejar estado stale con volumen 0.
        currentTrack = null;
        _scheduleMusicRetry(() => _playMusicTrack(
              asset: asset,
              track: track,
              fallbackWav: fallbackWav,
              volume: volume,
            ));
      }
    } catch (_) {
      currentTrack = null;
      // Un solo reintento por si el reproductor no estaba listo.
      _scheduleMusicRetry(() => _playMusicTrack(
            asset: asset,
            track: track,
            fallbackWav: fallbackWav,
            volume: volume,
          ));
    }
  }

  /// Música del menú (chill). Usa `assets/sounds/menu.mp3` si existe.
  Future<void> playMenuLoop() {
    if (currentTrack == 'menu') return Future.value();
    return _playMusicTrack(
      asset: 'sounds/menu.mp3',
      track: 'menu',
      fallbackWav: () => _generateAmbientPadWav(
        durationMs: 8000,
        fadeMs: 3000,
        volume: 0.04,
      ),
      volume: 0.08,
    );
  }

  bool _retryScheduled = false;
  int _musicRetryCount = 0;
  static const int _maxMusicRetries = 2;

  /// Reintenta la pista si falló al arrancar (p.ej. si el reproductor
  /// aún no estaba listo en initState). Máximo 2 reintentos y solo si
  /// sigue sin sonar nada.
  void _scheduleMusicRetry(Future<void> Function() attempt) {
    if (_retryScheduled || _musicRetryCount >= _maxMusicRetries) return;
    _retryScheduled = true;
    _musicRetryCount++;
    Future.delayed(const Duration(milliseconds: 1500), () async {
      _retryScheduled = false;
      if (currentTrack == null && soundEnabled && musicEnabled) {
        await attempt();
      }
    });
  }

  /// Normaliza una categoría de juego a slug de archivo
  /// (MENTIRA->mentira, OPINIÓN->opinion, MISTERIO->misterio...).
  static String musicSlugForCategory(String? category) {
    var s = (category ?? '').toLowerCase().trim();
    const map = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return s;
  }

  /// Música de los juegos según su conjunto (categoría).
  /// Usa `assets/sounds/musica_<slug>.mp3` si existe (p.ej.
  /// `musica_mentira.mp3`, `musica_misterio.mp3` para Pueblo Duerme),
  /// si no `assets/sounds/game.mp3`, si no el pad generado.
  /// Si la pista ya suena no la reinicia (evita cortes raros).
  Future<void> playAmbientLoop({String? category}) {
    final slug = musicSlugForCategory(category);
    final trackId = slug.isEmpty ? 'game' : 'game_$slug';
    if (currentTrack == trackId) return Future.value();
    return _playCategoryTrack(slug: slug, track: trackId);
  }

  Future<void> _playCategoryTrack({
    required String slug,
    required String track,
  }) {
    // Se intenta en orden y la primera que exista suena.
    return _playMusicTrackList(
      track: track,
      volume: 0.08,
      candidates: slug.isEmpty
          ? ['sounds/game.mp3']
          : ['sounds/musica_$slug.mp3', 'sounds/game.mp3'],
    );
  }

  /// Reproduce la primera pista existente de [candidates] en loop.
  /// Si ninguna existe, usa el pad generado como fallback.
  Future<void> _playMusicTrackList({
    required String track,
    required double volume,
    required List<String> candidates,
  }) async {
    _resumeAttempt = () => _playMusicTrackList(
          track: track,
          volume: volume,
          candidates: candidates,
        );
    try {
      await _ensureInit();
      if (!soundEnabled || !musicEnabled) {
        currentTrack = null;
        return;
      }
      _fadeVersion++; // Cancela cualquier fade anterior.
      try {
        await _ambientAudioPlayer.stop();
      } catch (_) {}
      try {
        await _ambientAudioPlayer.setReleaseMode(ReleaseMode.loop);
      } catch (_) {}
      // Arranca en silencio y sube con fade para evitar cortes.
      _lastAmbientVolume = 0.0;
      try {
        await _ambientAudioPlayer.setVolume(0.0);
      } catch (_) {}
      // Estado honesto: null hasta confirmar que suena.
      currentTrack = null;
      var played = false;
      for (final asset in candidates) {
        try {
          await _ambientAudioPlayer.play(AssetSource(asset));
          played = true;
          break;
        } catch (_) {}
      }
      if (!played) {
        try {
          // Sin mp3/wav del usuario: pad generado como fallback.
          await _ambientAudioPlayer.play(BytesSource(_generateAmbientPadWav(
            durationMs: 8000,
            fadeMs: 3000,
            volume: 0.04,
          )));
          played = true;
        } catch (_) {}
      }
      if (!played) {
        _scheduleMusicRetry(() => _playMusicTrackList(
              track: track,
              volume: volume,
              candidates: candidates,
            ));
        return;
      }
      currentTrack = track;
      _musicRetryCount = 0;
      final rampOk = await _rampAmbientVolume(volume, durationMs: 800);
      if (!rampOk) {
        // El fade abortó: no dejar estado stale con volumen 0.
        currentTrack = null;
        _scheduleMusicRetry(() => _playMusicTrackList(
              track: track,
              volume: volume,
              candidates: candidates,
            ));
      }
    } catch (_) {
      currentTrack = null;
      // Un solo reintento por si el reproductor no estaba listo.
      _scheduleMusicRetry(() => _playMusicTrackList(
            track: track,
            volume: volume,
            candidates: candidates,
          ));
    }
  }

  /// Parada inmediata sin fade (al salir la app a segundo plano).
  Future<void> stopAmbientNow() async {
    currentTrack = null;
    _fadeVersion++;
    _lastAmbientVolume = 0.0;
    try {
      await _ambientAudioPlayer.stop();
    } catch (_) {}
  }

  /// Llamar al pasar la app a segundo plano: silencia de inmediato pero
  /// recuerda la pista para reanudarla al volver.
  Future<void> onAppPaused() async {
    final resume = _resumeAttempt;
    await stopAmbientNow();
    if (resume != null) _resumeAttempt = resume;
  }

  /// Llamar al volver la app a primer plano: reanuda lo que sonaba.
  Future<void> onAppResumed() async {
    if (!soundEnabled || !musicEnabled) return;
    if (currentTrack != null) return;
    final resume = _resumeAttempt;
    if (resume == null) return;
    _resumeAttempt = null;
    try {
      await resume();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    currentTrack = null;
    _resumeAttempt = null;
    // Fade out antes de parar para que no corte en seco.
    // Si otro fade/track tomó el control mientras tanto, NO parar
    // (si no mataríamos la pista nueva que acaba de arrancar).
    final myVersion = _fadeVersion + 1;
    try {
      await _rampAmbientVolume(0.0, durationMs: 500);
    } catch (_) {}
    if (myVersion != _fadeVersion) return;
    try {
      await _ambientAudioPlayer.stop();
    } catch (_) {}
    _lastAmbientVolume = 0.0;
  }

  // ---------------------------------------------------------------------------
  // Public sound API — siempre usa fallback audible real (SystemSound + Haptic + tono BytesSource)
  // ---------------------------------------------------------------------------

  Future<void> playTick() async {
    await _ensureInit();
    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      // Tick corto 100ms 1200Hz brillante con envolvente rápida + segundo armónico
      try {
        await _playTone(freq: 1200, freq2: 2400, durationMs: 100, volume: 0.42);
      } catch (_) {}
    }
    if (vibrationEnabled && !kIsWeb) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 30);
        }
      } catch (_) {
        try {
          await HapticFeedback.lightImpact();
        } catch (_) {}
      }
    }
  }

  Future<void> playSuccess() async {
    await _ensureInit();
    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        try {
          await SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
      // Acorde mayor agradable 523+659Hz (C5+E5) con 784Hz (G5) opcional, 280ms
      try {
        await _playChord(freqs: [523.25, 659.25, 783.99], durationMs: 280, volume: 0.48);
      } catch (_) {}
    }
    if (vibrationEnabled && !kIsWeb) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(pattern: [0, 60, 40, 60]);
        }
      } catch (_) {}
    }
  }

  Future<void> playFail() async {
    await _ensureInit();
    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      // 220Hz descendente hasta 140Hz, 380ms grave
      try {
        await _playDescending(startFreq: 220, endFreq: 130, durationMs: 380, volume: 0.52);
      } catch (_) {}
    }
    if (vibrationEnabled && !kIsWeb) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 80);
        }
      } catch (_) {}
    }
  }

  Future<void> playCountdown() async {
    await _ensureInit();
    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        try {
          await SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
      // 600Hz grave, 140ms con leve vibrato para no ser soso
      try {
        await _playTone(freq: 600, durationMs: 140, volume: 0.5, vibrato: true);
      } catch (_) {}
    }
    if (vibrationEnabled && !kIsWeb) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 40);
        }
      } catch (_) {}
    }
  }

  Future<void> playGameOver() async {
    await _ensureInit();
    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      try {
        // Acorde descendente suave para fin de partida
        await _playDescending(startFreq: 400, endFreq: 220, durationMs: 520, volume: 0.5);
      } catch (_) {}
    }
    if (vibrationEnabled && !kIsWeb) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(pattern: [0, 100, 50, 100]);
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Vibration helpers (compat)
  // ---------------------------------------------------------------------------

  Future<void> vibrateShort() async {
    await _ensureInit();
    if (!vibrationEnabled) return;
    if (kIsWeb) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 50);
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  Future<void> vibrateSuccess() async {
    await _ensureInit();
    if (!vibrationEnabled) return;
    if (kIsWeb) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 60, 40, 60]);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  void dispose() {
    if (_globalRouteAdded) {
      try {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
      } catch (_) {}
      _globalRouteAdded = false;
    }
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
    try {
      _ambientPlayer?.stop();
    } catch (_) {}
    try {
      _ambientPlayer?.dispose();
    } catch (_) {}
    _ambientPlayer = null;
  }
}
