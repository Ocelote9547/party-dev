import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_config.dart';
import '../games/adivina_game.dart';
import '../games/alienigena_game.dart';
import '../games/angeles_demonios_game.dart';
import '../games/apt_coreano_game.dart';
import '../games/bomba_game.dart';
import '../games/debate_game.dart';
import '../games/dibuja_y_adivina_game.dart';
import '../games/ensalada_game.dart';
import '../games/es_un_10_game.dart';
import '../games/espia_game.dart';
import '../games/impostor_game.dart';
import '../games/mascara_infiltrada_game.dart';
import '../games/matar_casar_besar_game.dart';
import '../games/mimica_game.dart';
import '../games/pueblo_duerme_game.dart';
import '../games/quien_es_mas_game.dart';
import '../games/quien_soy_game.dart';
import '../games/secretos_game.dart';
import '../games/tabu_game.dart';
import '../games/verdad_o_reto_game.dart';
import '../games/yo_nunca_equipos_game.dart';
import '../games/yo_nunca_game.dart';
import '../games/yo_nunca_lobo_game.dart';
import '../games/yo_tengo_un_amigo_game.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/roulette_widget.dart';

class RouletteScreen extends StatefulWidget {
  final List<String> players;
  const RouletteScreen({super.key, required this.players});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> {
  bool _isSpinning = false;
  RouletteResult? _result;
  bool _showResultCard = false;

  Set<String> _unlocked = {};
  bool _economyLoaded = false;

  // Catálogo local (sincronizado con GamesScreen).
  static const List<_RouletteGameInfo> _allGames = [
    _RouletteGameInfo(emoji: '🕵️', title: 'IMPOSTOR', category: 'MENTIRA', minPlayers: 4),
    _RouletteGameInfo(emoji: '🌙', title: 'PUEBLO DUERME', category: 'GRUPO', minPlayers: 4),
    _RouletteGameInfo(emoji: '🧠', title: 'ADIVINA', category: 'PALABRAS', minPlayers: 3),
    _RouletteGameInfo(emoji: '🔟', title: 'ES UN 10 PERO...', category: 'RETO', minPlayers: 3),
    _RouletteGameInfo(emoji: '💬', title: 'DEBATE', category: 'OPINIÓN', minPlayers: 4),
    _RouletteGameInfo(emoji: '👀', title: 'QUIÉN ES MÁS', category: 'GRUPO', minPlayers: 4),
    _RouletteGameInfo(emoji: '🚫', title: 'TABÚ', category: 'PALABRAS', minPlayers: 4),
    _RouletteGameInfo(emoji: '🤫', title: 'YO NUNCA', category: 'GRUPO', minPlayers: 3),
    _RouletteGameInfo(emoji: '🎭', title: 'MÍMICA', category: 'RETO', minPlayers: 4),
    _RouletteGameInfo(emoji: '🎭', title: '¿QUIÉN SOY?', category: 'GRUPO', minPlayers: 3),
    _RouletteGameInfo(emoji: '🕵️', title: '¿QUIÉN ES EL ESPIA?', category: 'MENTIRA', minPlayers: 4),
    _RouletteGameInfo(emoji: '🎲', title: 'VERDAD O RETO', category: 'RETO', minPlayers: 2),
    _RouletteGameInfo(emoji: '💋', title: 'MATAR, CASAR, BESAR', category: 'GRUPO', minPlayers: 3),
    _RouletteGameInfo(emoji: '🕵️', title: 'SECRETOS', category: 'MENTIRA', minPlayers: 4),
    _RouletteGameInfo(emoji: '🎭', title: 'LA MÁSCARA INFILTRADA', category: 'MENTIRA', minPlayers: 4),
    _RouletteGameInfo(emoji: '🎨', title: 'DIBUJA Y ADIVINA', category: 'PALABRAS', minPlayers: 3),
    _RouletteGameInfo(emoji: '💣', title: 'BOMBA', category: 'PALABRAS', minPlayers: 3),
    _RouletteGameInfo(emoji: '🥗', title: 'LA ENSALADA', category: 'PALABRAS', minPlayers: 4),
    _RouletteGameInfo(emoji: '👽', title: 'ALIENÍGENA', category: 'MENTIRA', minPlayers: 4),
    _RouletteGameInfo(emoji: '👥', title: 'YO TENGO UN AMIGO', category: 'GRUPO', minPlayers: 6),
    _RouletteGameInfo(emoji: '🤫', title: 'YO NUNCA EQUIPOS', category: 'GRUPO', minPlayers: 6),
    _RouletteGameInfo(emoji: '🖐️', title: 'APT COREANO', category: 'RETO', minPlayers: 4),
    _RouletteGameInfo(emoji: '🐺', title: 'YO NUNCA LOBO', category: 'GRUPO', minPlayers: 4),
    _RouletteGameInfo(emoji: '👼', title: 'ANGELES Y DEMONIOS', category: 'MENTIRA', minPlayers: 4),
  ];

  static const List<String> _genericModes = ['Normal', 'Picante', 'Planes', 'Profundas'];
  static const List<String> _roundOptions = ['3 rondas', '5 rondas', '7 rondas'];
  static const List<String> _timedOptions = ['30s', '60s', '90s'];
  static const List<String> _difficultyOptions = ['Fácil', 'Normal', 'Difícil'];

  static const Set<String> _timedTitles = {
    'BOMBA',
    'MIMICA',
    'TABU',
    'ADIVINA',
    'DIBUJA Y ADIVINA',
  };

  static const Set<String> _difficultyTitles = {
    'TABU',
    'ADIVINA',
    'MIMICA',
    'BOMBA',
    'IMPOSTOR',
    'DIBUJA Y ADIVINA',
  };

  @override
  void initState() {
    super.initState();
    _loadEconomy();
  }

  Future<void> _loadEconomy() async {
    final unlocked = await EconomyService.instance.getUnlockedGames();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked;
      _economyLoaded = true;
    });
  }

  List<_RouletteGameInfo> get _availableGames {
    if (!_economyLoaded) return _allGames;
    // Filtrar por desbloqueados via EconomyService.
    final filtered = _allGames.where((g) {
      final id = EconomyService.normalizeGameId(g.title);
      return _unlocked.contains(id);
    }).toList();
    if (filtered.isEmpty) return _allGames;
    return filtered;
  }

  List<String> _modesForGame(String title) {
    final norm = EconomyService.normalizeGameId(title);
    if (norm == 'YO_NUNCA' || norm == 'YO_NUNCA_LOBO' || norm == 'YO_NUNCA_EQUIPOS') {
      // Usar claves reales de Yo Nunca mapeadas a Normal/Picante...
      return ['😇 Normal', '🔥 Picante', '🥳 Fiesta', '🤪 Caótico'];
    }
    if (norm == 'VERDAD_O_RETO') {
      return ['😇 Suave', '🔥 Picante'];
    }
    if (norm == 'DEBATE') {
      return _genericModes;
    }
    // El resto soporta el set genérico.
    return _genericModes;
  }

  // Pools estables para el widget mientras gira.
  List<String> get _rouletteGameLabels => _availableGames.map((e) => e.title).toList();
  List<String> get _rouletteModeLabels => _genericModes;
  List<String> get _rouletteDurationLabels => [..._roundOptions, ..._timedOptions];

  void _onSorprendeme() {
    if (_isSpinning) return;
    final available = _availableGames;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay juegos desbloqueados', style: TextStyle(color: PartyColors.text)), backgroundColor: PartyColors.surface),
      );
      return;
    }

    // Preferir juegos que cumplan minPlayers, si no hay, usar cualquiera desbloqueado.
    final eligible = available.where((g) {
      final cfg = GameConfig.getConfig(g.title);
      final min = cfg?.minPlayers ?? g.minPlayers;
      return widget.players.length >= min;
    }).toList();
    final pool = eligible.isNotEmpty ? eligible : available;

    final rnd = Random();
    final picked = pool[rnd.nextInt(pool.length)];

    final modes = _modesForGame(picked.title);
    final mode = modes[rnd.nextInt(modes.length)];

    final isTimed = _timedTitles.contains(EconomyService.normalizeGameId(picked.title));
    final durPool = isTimed ? _timedOptions : _roundOptions;
    final duration = durPool[rnd.nextInt(durPool.length)];

    final isDifficultyGame = _difficultyTitles.contains(EconomyService.normalizeGameId(picked.title));
    final String? difficulty = isDifficultyGame && rnd.nextBool()
        ? _difficultyOptions[rnd.nextInt(_difficultyOptions.length)]
        : null;

    final result = RouletteResult(
      title: picked.title,
      emoji: picked.emoji,
      category: picked.category,
      mode: mode,
      duration: duration,
      difficulty: difficulty,
      minPlayers: picked.minPlayers,
    );

    setState(() {
      _result = result;
      _isSpinning = true;
      _showResultCard = false;
    });
    SoundService.instance.playTick();
  }

  void _onSpinFinished() {
    if (!mounted) return;
    setState(() {
      _isSpinning = false;
      _showResultCard = true;
    });
    SoundService.instance.playSuccess();
  }

  Future<void> _onPlay() async {
    final res = _result;
    if (res == null) return;

    // Guardar temporal en SharedPreferences para que el juego lo lea si quiere.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'roulette_params',
        jsonEncode({
          'game': res.title,
          'mode': res.mode,
          'duration': res.duration,
          'difficulty': res.difficulty,
          'emoji': res.emoji,
          'category': res.category,
        }),
      );
    } catch (_) {}

    // Validar jugadores suficientes.
    final cfg = GameConfig.getConfig(res.title);
    final minP = cfg?.minPlayers ?? res.minPlayers;
    if (widget.players.length < minP) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PartyColors.surface,
          title: Text('Jugadores insuficientes', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
          content: Text('Se necesitan $minP jugadores (tienes ${widget.players.length}).', style: TextStyle(color: PartyColors.textSecondary)),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: PartyColors.primary), child: const Text('Vale')),
          ],
        ),
      );
      return;
    }

    final screen = _getGameScreen(res.title);
    if (screen == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Juego no disponible: ${res.title}'), backgroundColor: PartyColors.surface),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget? _getGameScreen(String title) {
    final norm = EconomyService.normalizeGameId(title);
    // Mapeo igual que GamesScreen pero usando norm para robustez.
    switch (norm) {
      case 'IMPOSTOR':
        return ImpostorGame(players: widget.players);
      case 'PUEBLO_DUERME':
        return PuebloDuermeGame(players: widget.players);
      case 'ADIVINA':
        return AdivinaGame(players: widget.players);
      case 'ES_UN_10':
        return EsUn10Game(players: widget.players);
      case 'DEBATE':
        return DebateGame(players: widget.players);
      case 'QUIEN_ES_MAS':
        return QuienEsMasGame(players: widget.players);
      case 'TABU':
        return TabuGame(players: widget.players);
      case 'YO_NUNCA':
        return YoNuncaGame(players: widget.players);
      case 'MIMICA':
        return MimicaGame(players: widget.players);
      case 'QUIEN_SOY':
        return QuienSoyGame(players: widget.players);
      case 'ESPIA':
      case 'QUIEN_ES_EL_ESPIA':
        return EspiaGame(players: widget.players);
      case 'VERDAD_O_RETO':
        return VerdadORetoGame(players: widget.players);
      case 'MATAR_CASAR_BESAR':
        return MatarCasarBesarGame(players: widget.players);
      case 'SECRETOS':
        return SecretosGame(players: widget.players);
      case 'LA_MASCARA_INFILTRADA':
        return MascaraInfiltradaGame(players: widget.players);
      case 'DIBUJA_Y_ADIVINA':
        return DibujaYadivinaGame(players: widget.players);
      case 'BOMBA':
        return BombaGame(players: widget.players);
      case 'LA_ENSALADA':
        return EnsaladaGame(players: widget.players);
      case 'ALIENIGENA':
        return AlienigenaGame(players: widget.players);
      case 'YO_TENGO_UN_AMIGO':
        return YoTengoUnAmigoGame(players: widget.players);
      case 'YO_NUNCA_EQUIPOS':
        return YoNuncaEquiposGame(players: widget.players);
      case 'APT_COREANO':
        return AptCoreanoGame(players: widget.players);
      case 'YO_NUNCA_LOBO':
        return YoNuncaLoboGame(players: widget.players);
      case 'ANGELES_Y_DEMONIOS':
      case 'ANGELES_DEMONIOS':
        return AngelesDemoniosGame(players: widget.players);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameLabels = _rouletteGameLabels;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('RULETA PARTY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.5, color: PartyColors.text)),
        iconTheme: IconThemeData(color: PartyColors.text),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: PartyColors.scaffoldGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                // Ruleta
                RouletteWidget(
                  isSpinning: _isSpinning,
                  result: _result,
                  onFinished: _onSpinFinished,
                  gameOptions: gameLabels,
                  modeOptions: _rouletteModeLabels,
                  durationOptions: _rouletteDurationLabels,
                ),
                const SizedBox(height: 28),
                // Botón grande SORPRÉNDEME
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _isSpinning ? null : _onSorprendeme,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      disabledBackgroundColor: PartyColors.primary.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 8,
                      shadowColor: PartyColors.primary.withValues(alpha: 0.35),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎲', style: TextStyle(fontSize: _isSpinning ? 22 : 26)),
                        const SizedBox(width: 10),
                        Text(
                          _isSpinning ? 'GIRANDO...' : 'SORPRÉNDEME',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _economyLoaded ? '${_availableGames.length} juegos desbloqueados · ${widget.players.length} jugadores' : 'Cargando juegos...',
                  style: TextStyle(fontSize: 12, color: PartyColors.textMuted, letterSpacing: 0.3),
                ),
                const SizedBox(height: 22),
                // Carta grande resultado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  child: _showResultCard && _result != null
                      ? _ResultCard(result: _result!, onPlay: _onPlay, isSpinning: _isSpinning)
                      : _showResultCard && _result == null
                          ? Container(
                              key: const ValueKey('empty'),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: PartyColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: PartyColors.border),
                              ),
                              child: Text('Pulsa SORPRÉNDEME para elegir', textAlign: TextAlign.center, style: TextStyle(color: PartyColors.textSecondary)),
                            )
                          : const SizedBox(key: ValueKey('idle'), height: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RouletteResult result;
  final VoidCallback onPlay;
  final bool isSpinning;

  const _ResultCard({required this.result, required this.onPlay, required this.isSpinning});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('card-${result.title}-${result.mode}-${result.duration}'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PartyColors.primary.withValues(alpha: 0.28), width: 1.4),
        boxShadow: [
          BoxShadow(color: PartyColors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PartyColors.primary.withValues(alpha: 0.10),
              border: Border.all(color: PartyColors.primary.withValues(alpha: 0.22)),
            ),
            child: Center(child: Text(result.emoji, style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          Text(result.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: PartyColors.primary)),
          const SizedBox(height: 6),
          Text(result.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: PartyColors.text)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Chip(label: '🎭 ${result.mode}'),
              _Chip(label: '⏱ ${result.duration}'),
              if (result.difficulty != null) _Chip(label: '⭐ ${result.difficulty}'),
              _Chip(label: '👥 ${result.minPlayers}+'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isSpinning ? null : onPlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: PartyColors.primary,
                foregroundColor: PartyColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('JUGAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Se guardará en la ruleta para el juego', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: PartyColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PartyColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.text)),
    );
  }
}

class _RouletteGameInfo {
  final String emoji;
  final String title;
  final String category;
  final int minPlayers;
  const _RouletteGameInfo({required this.emoji, required this.title, required this.category, this.minPlayers = 2});
}
