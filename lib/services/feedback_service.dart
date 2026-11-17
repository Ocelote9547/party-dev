import 'sound_service.dart';

/// Central utility for sound & vibration feedback.
///
/// Unificado con [SoundService]: persiste en `sound_enabled` / `vibration_enabled`
/// (compat `settings_sound` / `settings_vibration`) y delega a SystemSound +
/// HapticFeedback como fallback principal. Todos los métodos son fire-and-forget.
/// Sin logs ruidosos — solo delegación a SoundService.
class FeedbackService {
  static const String kSoundKey = 'settings_sound';
  static const String kVibrationKey = 'settings_vibration';

  // ---------------------------------------------------------------------------
  // Low-level preference helpers (leen ambas claves) — delegan a SoundService
  // ---------------------------------------------------------------------------

  static Future<bool> isSoundEnabled() async {
    try {
      await SoundService.instance.init();
      return SoundService.instance.soundEnabled;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> isVibrationEnabled() async {
    try {
      await SoundService.instance.init();
      return SoundService.instance.vibrationEnabled;
    } catch (_) {
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // General feedback — delega a SoundService para unificar (sin duplicar)
  // ---------------------------------------------------------------------------

  static Future<void> playClick() async {
    await selectionClick();
  }

  static Future<void> selectionClick() async {
    try {
      await SoundService.I.playTick();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Countdown beeps
  // ---------------------------------------------------------------------------

  /// Returns true when a beep should be emitted for [secondsLeft].
  /// Beeps at 60, 30, 15, 10 and then every second 10..0 inclusive.
  static bool shouldBeep(int secondsLeft) {
    if (secondsLeft == 60 || secondsLeft == 30 || secondsLeft == 15) return true;
    if (secondsLeft <= 10 && secondsLeft >= 0) return true;
    return false;
  }

  static Future<void> playBeep() async {
    try {
      await SoundService.I.playTick();
    } catch (_) {}
  }

  static Future<void> playCountdownBeep({required int secondsLeft}) async {
    if (!shouldBeep(secondsLeft)) return;
    await playBeep();
  }

  static Future<void> countdownTick(int secondsLeft) async {
    if (!shouldBeep(secondsLeft)) return;
    await playBeep();
  }

  static Future<void> countdownTickWithTotal(int secondsLeft, int totalSeconds) async {
    await countdownTick(secondsLeft);
  }
}
