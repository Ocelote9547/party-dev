import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TiltService {
  static final TiltService instance = TiltService._();
  TiltService._();

  static const String kTiltEnabledKey = 'tilt_enabled';
  static const String kTiltSensitivityKey = 'tilt_sensitivity'; // 0 suave, 1 normal, 2 firme

  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> sensitivityNotifier = ValueNotifier<int>(1);

  bool get enabled => enabledNotifier.value;
  int get sensitivity => sensitivityNotifier.value;

  /// Indica si el sensor de inclinación está disponible en este dispositivo.
  /// Queda en false si `sensors_plus` falla o no hay giroscopio/acelerómetro.
  final ValueNotifier<bool> tiltAvailable = ValueNotifier<bool>(true);

  double get threshold {
    switch (sensitivity) {
      case 0: return 3.5; // suave
      case 2: return 5.0; // firme (subido de 4.5 para evitar falsos disparos)
      default: return 4.5; // normal
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabledNotifier.value = prefs.getBool(kTiltEnabledKey) ?? true;
    sensitivityNotifier.value = prefs.getInt(kTiltSensitivityKey) ?? 1;
  }

  Future<void> setEnabled(bool v) async {
    enabledNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kTiltEnabledKey, v);
  }

  Future<void> setSensitivity(int v) async {
    sensitivityNotifier.value = v.clamp(0, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kTiltSensitivityKey, sensitivityNotifier.value);
  }
}
