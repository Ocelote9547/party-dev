import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/economy_service.dart';
import '../services/feedback_service.dart';
import '../services/sound_service.dart';
import '../services/tilt_service.dart';
import '../theme/party_theme.dart';
import '../theme/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool musicEnabled = true;
  bool tiltEnabled = true;
  int tiltSensitivity = 1;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Lee claves correctas sound_enabled/vibration_enabled con fallback legacy
    await SoundService.instance.init();
    await TiltService.instance.init();
    if (!mounted) return;
    setState(() {
      if (prefs.containsKey(SoundService.kSoundKey)) {
        soundEnabled = prefs.getBool(SoundService.kSoundKey) ?? true;
      } else {
        soundEnabled = prefs.getBool(FeedbackService.kSoundKey) ?? true;
      }
      if (prefs.containsKey(SoundService.kVibrationKey)) {
        vibrationEnabled = prefs.getBool(SoundService.kVibrationKey) ?? true;
      } else {
        vibrationEnabled = prefs.getBool(FeedbackService.kVibrationKey) ?? true;
      }
      // Sincroniza con singleton en memoria
      soundEnabled = SoundService.instance.soundEnabled;
      vibrationEnabled = SoundService.instance.vibrationEnabled;
      musicEnabled = SoundService.instance.musicEnabled;
      tiltEnabled = TiltService.instance.enabled;
      tiltSensitivity = TiltService.instance.sensitivity;
    });
    if (kDebugMode) {
      debugPrint('[Settings] loadPrefs sound=$soundEnabled vib=$vibrationEnabled');
    }
  }

  Future<void> _setSound(bool value) async {
    if (kDebugMode) debugPrint('[Settings] _setSound $value');
    setState(() => soundEnabled = value);
    await SoundService.instance.toggleSound(value);
    if (kDebugMode) debugPrint('[Settings] _setSound done sound=${SoundService.instance.soundEnabled}');
  }

  Future<void> _setVibration(bool value) async {
    if (kDebugMode) debugPrint('[Settings] _setVibration $value');
    setState(() => vibrationEnabled = value);
    await SoundService.instance.toggleVibration(value);
    if (kDebugMode) debugPrint('[Settings] _setVibration done vib=${SoundService.instance.vibrationEnabled}');
  }

  Future<void> _setMusic(bool value) async {
    setState(() => musicEnabled = value);
    await SoundService.instance.toggleMusic(value);
  }

  Future<void> _setTiltEnabled(bool value) async {
    setState(() => tiltEnabled = value);
    await TiltService.instance.setEnabled(value);
  }

  Future<void> _setTiltSensitivity(int value) async {
    setState(() => tiltSensitivity = value);
    await TiltService.instance.setSensitivity(value);
  }

  static const Map<String, String> _creatorCodes = {
    'X7K9P2M4Q8W1': 'ALL',
    'G4M3S9X2P7LQ1': 'GAMES',
    'C0SM3T1K9Q3W': 'COSMETICS',
    'TH3M3V0LC4N1': 'THEME',
    'C01NS1000X7K': 'COINS',
    'G0LD3N4V4T4R': 'GOLDEN',
  };
  // Código maestro (solo para ti) que muestra la bóveda con todos los códigos.
  static const String _masterDevCode = 'N3MESISDEV12';

  Future<void> _showCreatorCodeDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        title: Row(children: [const Text('🎁', style: TextStyle(fontSize: 22)), const SizedBox(width: 8), Text('Código de creador', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800, fontSize: 16))]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Introduce un código de 12 caracteres', style: TextStyle(color: PartyColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 12,
            decoration: InputDecoration(
              hintText: 'XXXXXXXXXXXX',
              counterText: '',
              filled: true,
              fillColor: PartyColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: PartyColors.border)),
            ),
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700, color: PartyColors.text),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim().toUpperCase()),
            style: FilledButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    final code = result.trim().toUpperCase();
    // Bóveda de desarrollador: muestra todos los códigos
    if (code == _masterDevCode) {
      if (!mounted) return;
      await _showDevVault();
      return;
    }
    final type = _creatorCodes[code];
    if (type == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Código no válido'), backgroundColor: PartyColors.danger));
      return;
    }
    // Evitar canjear dos veces el mismo código
    final prefs = await SharedPreferences.getInstance();
    final redeemed = (prefs.getStringList('redeemed_codes') ?? []).toSet();
    if (redeemed.contains(code)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Código ya canjeado'), backgroundColor: PartyColors.surface));
      return;
    }
    redeemed.add(code);
    await prefs.setStringList('redeemed_codes', redeemed.toList());

    String msg = '¡Código canjeado!';
    if (type == 'ALL') {
      await EconomyService.instance.debugUnlockAll();
      msg = '¡Todo desbloqueado! +500 monedas 🪙';
    } else if (type == 'GAMES') {
      final all = EconomyService.allGameIds;
      await prefs.setString('unlocked_games', '["${all.join('","')}"]');
      // Usamos el método del servicio para no duplicar lógica de JSON
      for (final id in all) {
        await EconomyService.instance.unlockGame(id);
      }
      msg = '¡Todos los juegos desbloqueados! 🎮';
    } else if (type == 'COSMETICS') {
      for (final p in ['pack_hats', 'pack_glasses', 'pack_masks', 'pack_faces', 'pack_hats_premium', 'pack_colors', 'pack_extras']) {
        await EconomyService.instance.unlockPack(p);
      }
      msg = '¡Cosméticos desbloqueados! 🎨';
    } else if (type == 'THEME') {
      for (final p in ['pack_colors', 'pack_hats_premium']) {
        await EconomyService.instance.unlockPack(p);
      }
      final coins = await EconomyService.instance.getCoins();
      await prefs.setInt('coins', coins + 300);
      msg = '¡Tema especial desbloqueado! +300 monedas 🎨';
    } else if (type == 'COINS') {
      final coins = await EconomyService.instance.getCoins();
      await prefs.setInt('coins', coins + 1000);
      msg = '¡+1000 monedas! 🪙';
    } else if (type == 'GOLDEN') {
      await EconomyService.instance.unlockPack('pack_golden');
      msg = '¡Avatares dorados desbloqueados! 🏆';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: PartyColors.success));
  }

  Future<void> _showDevVault() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.primary.withValues(alpha: 0.4))),
        title: Row(children: [const Text('🔐'), const SizedBox(width: 8), Text('Bóveda de creador', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800, fontSize: 16))]),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Guárdalos tú, no los compartas:', style: TextStyle(color: PartyColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 12),
            for (final e in _creatorCodes.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: PartyColors.border)),
                  child: Row(children: [
                    Expanded(child: Text(e.key, style: TextStyle(fontFamily: 'monospace', letterSpacing: 1.5, fontWeight: FontWeight.w800, fontSize: 12, color: PartyColors.text))),
                    const SizedBox(width: 8),
                    Text({ 'ALL': 'Todo', 'GAMES': 'Juegos', 'COSMETICS': 'Cosméticos', 'THEME': 'Tema', 'COINS': '+1000', 'GOLDEN': 'Dorado'}[e.value] ?? e.value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            Text('Maestro: $_masterDevCode (solo tú)', style: TextStyle(color: PartyColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic)),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _confirmFactoryReset() async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Text(
          '¿Seguro?',
          style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Se borrarán jugadores, monedas, avatares, ranking, juegos desbloqueados.',
          style: TextStyle(color: PartyColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: PartyColors.danger),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (firstConfirm != true || !mounted) return;

    // Doble confirmación en release
    if (!kDebugMode) {
      final secondConfirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PartyColors.surface,
          title: Text(
            '¿Realmente seguro?',
            style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(color: PartyColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: PartyColors.danger),
              child: const Text('Sí, borrar todo'),
            ),
          ],
        ),
      );
      if (secondConfirm != true || !mounted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Reset servicios en memoria
    try {
      await EconomyService.instance.resetEconomy();
    } catch (_) {}
    // AvatarService y PlayerStorage no tienen cache en memoria;
    // prefs.clear() ya borra avatares, ranking y jugadores.
    // Limpiamos también el contador de economy por si quedó estado tras clear.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App reiniciada')),
    );
    // Resetear switches locales a valores por defecto
    setState(() {
      soundEnabled = true;
      vibrationEnabled = true;
      musicEnabled = true;
    });
  }

  void _onCreatorCodeTap() => _showCreatorCodeDialog();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return _build(context);
      },
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AJUSTES',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Código de creador',
            icon: Icon(Icons.card_giftcard_rounded, color: PartyColors.primary),
            onPressed: _onCreatorCodeTap,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        children: [
          _SettingItem(
            icon: Icons.volume_up_outlined,
            title: 'Sonido',
            subtitle: 'Efectos y sonidos de los juegos',
            trailing: Switch(
              value: soundEnabled,
              onChanged: (value) {
                _setSound(value);
              },
            ),
          ),
          _SettingItem(
            icon: Icons.vibration_outlined,
            title: 'Vibración',
            subtitle: 'Usar vibración durante los juegos',
            trailing: Switch(
              value: vibrationEnabled,
              onChanged: (value) {
                _setVibration(value);
              },
            ),
          ),
          _SettingItem(
            icon: Icons.music_note_outlined,
            title: 'Música ambiente',
            subtitle: 'Pad suave de fondo',
            trailing: Switch(
              value: musicEnabled,
              onChanged: (value) {
                _setMusic(value);
              },
            ),
          ),
          _SettingItem(
            icon: Icons.screen_rotation_outlined,
            title: 'Inclinación',
            subtitle: 'Inclinar móvil para acierto/fallo (si no, desliza)',
            trailing: Switch(
              value: tiltEnabled,
              onChanged: _setTiltEnabled,
            ),
          ),
          if (tiltEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: PartyColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PartyColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sensibilidad inclinación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.text)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Suave'), icon: Icon(Icons.sensors_outlined, size: 16)),
                      ButtonSegment(value: 1, label: Text('Normal'), icon: Icon(Icons.sensors, size: 16)),
                      ButtonSegment(value: 2, label: Text('Firme'), icon: Icon(Icons.sensors_off_outlined, size: 16)),
                    ],
                    selected: {tiltSensitivity},
                    onSelectionChanged: (s) => _setTiltSensitivity(s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return PartyColors.primary.withValues(alpha: 0.15);
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              final isDark = mode != ThemeMode.light;
              return _SettingItem(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Tema oscuro',
                subtitle: isDark
                    ? 'Interfaz con fondo oscuro'
                    : 'Interfaz con fondo claro',
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) => themeController.setDark(value),
                ),
              );
            },
          ),
          _SettingItem(
            icon: Icons.info_outline,
            title: 'Sobre PARTY',
            subtitle: 'Información de la app',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: PartyColors.textMuted,
            ),
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 20),
          // Botón factory reset visible siempre con confirmación
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: _confirmFactoryReset,
              icon: const Text('🔄', style: TextStyle(fontSize: 18)),
              label: const Text(
                'REINICIAR APP (Borrar todo)',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PartyColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          Text(
            'Borra jugadores, monedas, avatares, ranking y juegos desbloqueados',
            textAlign: TextAlign.center,
            style: TextStyle(color: PartyColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 32),
          // Sección Sobre Party con título PARTY grande - 20 taps para unlock (solo debug)
          Center(
            child: Text(
              'PARTY',
              style: TextStyle(
                color: PartyColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
                  'v1.8.3 • com.n3mesis.party',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PartyColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Text(
          'PARTY',
          style: TextStyle(
            color: PartyColors.text,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Juegos para todos.\nVersión 1.8.3',
          style: TextStyle(color: PartyColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PartyColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Icon(
          icon,
          color: PartyColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: PartyColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: PartyColors.textSecondary,
            fontSize: 12,
          ),
        ),
          trailing: trailing,
        ),
      ),
    );
  }
}
