// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';

enum _Phase { instructions, setup, playing, gameOver }
enum _RoundStep { night, prompt, secretRise, wolfVote, dawn, guess }

class YoNuncaLoboGame extends StatefulWidget {
  final List<String> players;
  const YoNuncaLoboGame({super.key, required this.players});

  @override
  State<YoNuncaLoboGame> createState() => _YoNuncaLoboGameState();
}

class _YoNuncaLoboGameState extends State<YoNuncaLoboGame> {
  _Phase _phase = _Phase.instructions;
  _RoundStep _step = _RoundStep.night;

  int _totalRounds = 3;
  int _currentRound = 1;

  final Map<String, int> _scores = {};
  final Set<String> _alive = {};

  String _currentPrompt = '';
  final Set<String> _wolves = {};
  final Set<String> _sleepers = {};
  String? _victim;
  final Map<String, String> _wolfVotes = {};
  final Set<String> _guessSelection = {};

  int _secretIndex = 0;
  int _wolfVoteIndex = 0;

  bool _economyAwarded = false;

  final List<_LoboRoundResult> _history = [];

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  List<String> get _aliveList => _alive.toList();
  List<String> get _wolfList => _wolves.toList();
  List<String> get _sleeperList => _sleepers.toList();

  @override
  void initState() {
    super.initState();
    try {
      SoundService.instance.playAmbientLoop(category: 'GRUPO');
    } catch (_) {}
    for (final p in widget.players) {
      _scores[p] = 0;
      _alive.add(p);
    }
  }

  @override
  void dispose() {
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    super.dispose();
  }

  @override
  void deactivate() {
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    super.deactivate();
  }

  void _startGame() => setState(() => _phase = _Phase.setup);

  void _selectRounds(int n) {
    setState(() {
      _totalRounds = n;
      _currentRound = 1;
      _phase = _Phase.playing;
    });
    _startRound();
  }

  void _startRound() {
    _currentPrompt = _pickRandomYoNunca();
    _wolves.clear();
    _sleepers.clear();
    _victim = null;
    _wolfVotes.clear();
    _guessSelection.clear();
    _secretIndex = 0;
    _wolfVoteIndex = 0;
    setState(() => _step = _RoundStep.night);
    try {
      SoundService.instance.playAmbientLoop(category: 'GRUPO');
    } catch (_) {}
  }

  String _pickRandomYoNunca() {
    final pool = <String>[];
    for (final list in GameData.yoNuncaModos.values) {
      pool.addAll(list);
    }
    if (pool.isEmpty) return 'Yo nunca he mentido';
    pool.shuffle();
    return pool.first;
  }

  String get _currentSecretPlayer {
    final list = _aliveList;
    if (list.isEmpty) return '';
    return list[_secretIndex.clamp(0, list.length - 1)];
  }

  String get _currentWolfVoter {
    final list = _wolfList;
    if (list.isEmpty) return '';
    return list[_wolfVoteIndex.clamp(0, list.length - 1)];
  }

  void _onNightContinue() {
    setState(() => _step = _RoundStep.prompt);
  }

  void _onPromptContinue() {
    setState(() => _step = _RoundStep.secretRise);
  }

  void _onSecretDecision(bool rise) {
    final player = _currentSecretPlayer;
    if (rise) {
      _wolves.add(player);
    } else {
      _sleepers.add(player);
    }
    if (_secretIndex < _aliveList.length - 1) {
      setState(() => _secretIndex++);
    } else {
      // all decided
      // fill remaining sleepers if not already (for players who rose, they are not sleepers)
      // edge: wolves/sleepers already filled
      _advanceAfterSecretRise();
    }
  }

  void _advanceAfterSecretRise() {
    if (_wolves.isEmpty || _wolves.length == _alive.length) {
      // No victim possible: skip killing
      _victim = null;
      setState(() => _step = _RoundStep.dawn);
      return;
    }
    // Ensure sleepers contains those not wolves (already) but ensure complete
    for (final p in _alive) {
      if (!_wolves.contains(p) && !_sleepers.contains(p)) {
        _sleepers.add(p);
      }
    }
    _wolfVotes.clear();
    _wolfVoteIndex = 0;
    setState(() => _step = _RoundStep.wolfVote);
  }

  void _onWolfVote(String target) {
    final voter = _currentWolfVoter;
    _wolfVotes[voter] = target;
    if (_wolfVoteIndex < _wolfList.length - 1) {
      setState(() => _wolfVoteIndex++);
    } else {
      _resolveWolfVotes();
    }
  }

  void _resolveWolfVotes() {
    if (_wolfVotes.isEmpty) {
      _victim = null;
      setState(() => _step = _RoundStep.dawn);
      return;
    }
    final counts = <String, int>{};
    for (final v in _wolfVotes.values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    int maxVotes = 0;
    for (final c in counts.values) {
      if (c > maxVotes) maxVotes = c;
    }
    final top = counts.entries.where((e) => e.value == maxVotes).map((e) => e.key).toList()..shuffle();
    _victim = top.first;
    setState(() => _step = _RoundStep.dawn);
  }

  void _onDawnContinue() {
    if (_victim == null) {
      // no victim -> round ends without guess, wolves score nothing, just next round
      _history.add(_LoboRoundResult(
        round: _currentRound,
        prompt: _currentPrompt,
        wolves: Set<String>.from(_wolves),
        victim: null,
        guessedCorrectly: false,
        guess: const {},
      ));
      _nextOrGameOver(noVictim: true);
      return;
    }
    setState(() => _step = _RoundStep.guess);
  }

  void _toggleGuess(String player) {
    setState(() {
      if (_guessSelection.contains(player)) {
        _guessSelection.remove(player);
      } else {
        _guessSelection.add(player);
      }
    });
  }

  void _submitGuess() {
    final victim = _victim;
    if (victim == null) return;
    final correct = _guessSelection.length == _wolves.length && _guessSelection.containsAll(_wolves);
    if (correct) {
      SoundService.instance.playSuccess();
      SoundService.instance.vibrateSuccess();
    } else {
      SoundService.instance.playFail();
      SoundService.instance.vibrateShort();
      for (final w in _wolves) {
        _scores[w] = (_scores[w] ?? 0) + 1;
      }
    }

    _history.add(_LoboRoundResult(
      round: _currentRound,
      prompt: _currentPrompt,
      wolves: Set<String>.from(_wolves),
      victim: victim,
      guessedCorrectly: correct,
      guess: Set<String>.from(_guessSelection),
    ));

    // Victim dies for next rounds (remove from alive) - keep at least 2 alive
    if (_alive.length > 2) {
      _alive.remove(victim);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(correct ? Icons.verified_rounded : Icons.pets_rounded, size: 56, color: correct ? PartyColors.success : PartyColors.danger),
            const SizedBox(height: 12),
            Text(correct ? '¡ACERTÓ!' : '¡FALLÓ!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: correct ? PartyColors.success : PartyColors.danger)),
            const SizedBox(height: 8),
            Text(
              correct ? 'El muerto adivinó a todos los lobos. Los lobos pierden.' : 'No acertó a todos los lobos. Lobos +1 punto cada uno.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: PartyColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text('Lobos reales:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(_wolves.isEmpty ? '— ninguno —' : _wolves.join(', '), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.danger)),
                  const SizedBox(height: 8),
                  Text('Su intento: ${_guessSelection.isEmpty ? '—' : _guessSelection.join(', ')}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _nextOrGameOver();
                },
                style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(_currentRound < _totalRounds && _alive.length >= 2 ? 'SIGUIENTE RONDA' : 'VER RESULTADOS', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextOrGameOver({bool noVictim = false}) {
    if (noVictim) {
      // show dialog for no-victim case before proceeding
      final isLast = _currentRound >= _totalRounds || _alive.length < 2;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: PartyColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😴', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(_wolves.isEmpty ? 'Nadie se levantó' : 'Todos se levantaron', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('No hay víctimas esta ronda. Nadie puntúa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _proceedToNext(isLast);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(isLast ? 'VER RESULTADOS' : 'SIGUIENTE RONDA', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    final isLast = _currentRound >= _totalRounds || _alive.length < 2;
    _proceedToNext(isLast);
  }

  void _proceedToNext(bool isLast) {
    if (isLast) {
      try {
        SoundService.instance.stopAmbient();
      } catch (_) {}
      setState(() => _phase = _Phase.gameOver);
    } else {
      setState(() => _currentRound++);
      _startRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.length < 4) return const NeedPlayersScreen(minPlayers: 4);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PartyColors.surface,
            title: Text('¿Salir?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderás el progreso', style: TextStyle(color: PartyColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.danger), child: const Text('Salir')),
            ],
          ),
        );
        if (shouldPop == true) {
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {
          switch (_phase) {
            case _Phase.instructions:
              return GameInstructions(
                emoji: '🐺',
                title: 'YO NUNCA LOBO',
                subtitle: 'Mezcla de Pueblo Duerme + Yo Nunca. De noche todos duermen... pero algunos despiertan.',
                steps: [
                  'Todos se duermen (pantalla noche). Se anuncia un "Yo nunca..." al azar.',
                  'Pasando el móvil, cada jugador elige en secreto: "Me levanto / Sigo dormido". Quien se levanta es lobo de la ronda.',
                  'Los lobos votan en secreto a quién matar entre los dormidos.',
                  'Todos despiertan: se revela el muerto. El muerto debe adivinar quiénes eran los lobos.',
                  'Si acierta a TODOS los lobos, los lobos pierden. Si falla, cada lobo gana 1 punto.',
                  'Rondas 3 o 5. El muerto sale de la partida (si quedan 2, fin). Gana quien más puntos tenga.',
                ],
                onStart: _startGame,
              );
            case _Phase.setup:
              return _buildSetup();
            case _Phase.playing:
              return _buildPlaying();
            case _Phase.gameOver:
              return _buildGameOver();
          }
        },
      ),
    );
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐺', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('¿CUÁNTAS RONDAS?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
                const SizedBox(height: 8),
                Text('Cada ronda un "Yo nunca..." distinto', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                const SizedBox(height: 32),
                for (final c in [3, 5])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => _selectRounds(c),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _totalRounds == c ? PartyColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          foregroundColor: PartyColors.text,
                          side: BorderSide(color: _totalRounds == c ? PartyColors.primary : PartyColors.border, width: _totalRounds == c ? 2 : 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('$c RONDAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _totalRounds == c ? PartyColors.primary : PartyColors.text)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    switch (_step) {
      case _RoundStep.night:
        return _buildNight();
      case _RoundStep.prompt:
        return _buildPrompt();
      case _RoundStep.secretRise:
        return _buildSecretRise();
      case _RoundStep.wolfVote:
        return _buildWolfVote();
      case _RoundStep.dawn:
        return _buildDawn();
      case _RoundStep.guess:
        return _buildGuess();
    }
  }

  Widget _buildNight() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white))),
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text('EL PUEBLO DUERME', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Todos cierran los ojos...\nSe va a anunciar el "Yo nunca..."', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _onNightContinue,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('🌙 ANUNCIAR YO NUNCA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Vivos: ${_alive.join(', ')}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('YO NUNCA...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 1.5)),
                child: Text(_currentPrompt.replaceFirst('Yo nunca ', ''), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PartyColors.text, height: 1.4)),
              ),
              const SizedBox(height: 12),
              Text('Quien SÍ lo ha hecho se levantará como lobo', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _onPromptContinue,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('EMPEZAR LEVANTADAS SECRETAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecretRise() {
    final player = _currentSecretPlayer;
    final progress = '${_secretIndex + 1}/${_aliveList.length}';
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.text))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(progress, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.primary)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF0B1020), borderRadius: BorderRadius.circular(20)),
                child: Text(player.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Text('Pasa el móvil a $player\nNadie debe mirar', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                child: Text('"${_currentPrompt.replaceFirst('Yo nunca ', '')}"\n\n¿Tú SÍ lo has hecho?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.text, height: 1.5)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _onSecretDecision(true),
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('🐺 ME LEVANTO (SOY LOBO)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _onSecretDecision(false),
                  style: OutlinedButton.styleFrom(foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('😴 SIGO DORMIDO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Pulsa en secreto y pasa el móvil', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWolfVote() {
    final voter = _currentWolfVoter;
    final targets = _sleeperList;
    final progress = '${_wolfVoteIndex + 1}/${_wolfList.length}';
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds — LOBOS', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white, fontSize: 13))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: PartyColors.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('LOBO $progress', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.danger)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: PartyColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.danger.withValues(alpha: 0.3))),
                child: Text(voter.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.danger)),
              ),
              const SizedBox(height: 8),
              Text('Pasa el móvil a $voter\nVota en secreto a quién matar', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 20),
              Text('Dormidos: ${targets.join(', ')}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
              const SizedBox(height: 16),
              ...targets.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _onWolfVote(t),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDawn() {
    final hasVictim = _victim != null;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('☀️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('¡AMANECER!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                  child: Column(
                    children: [
                      Text('Yo nunca: "${_currentPrompt.replaceFirst('Yo nunca ', '')}"', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PartyColors.textSecondary, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      if (hasVictim) ...[
                        const Text('💀 MUERTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.danger)),
                        const SizedBox(height: 6),
                        Text(_victim!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PartyColors.danger)),
                        const SizedBox(height: 6),
                        Text('Los lobos lo eligieron', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
                      ] else ...[
                        const Text('😴 SIN VÍCTIMA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.success)),
                        const SizedBox(height: 6),
                        Text(_wolves.isEmpty ? 'Nadie era lobo' : 'Todos eran lobos', style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (hasVictim)
                  Text('Ahora $_victim debe adivinar quiénes eran los lobos', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onDawnContinue,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: Text(hasVictim ? '🔍 ADIVINAR LOBOS' : 'CONTINUAR', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuess() {
    final victim = _victim!;
    final candidates = _aliveList.where((p) => p != victim).toList();
    // Also include dead? For guess we show all except victim (alive at start)
    // Add old wolves maybe already included
    final allForGuess = Set<String>.from(candidates)..addAll(_wolves.where((w) => w != victim));
    final display = allForGuess.toList()..sort();
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.text))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: PartyColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('TURNO DE $victim', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.danger, letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              Text('¿Quiénes eran los lobos?', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 6),
              Text('Marca exactamente a todos los lobos (${_wolves.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              ...display.map((p) {
                final selected = _guessSelection.contains(p);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _toggleGuess(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? PartyColors.danger.withValues(alpha: 0.12) : PartyColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? PartyColors.danger : PartyColors.border, width: selected ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 22, color: selected ? PartyColors.danger : PartyColors.textMuted),
                          const SizedBox(width: 12),
                          Expanded(child: Text(p, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PartyColors.text))),
                          if (selected) const Text('🐺', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _guessSelection.isEmpty ? null : _submitGuess,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('CONFIRMAR ADIVINANZA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 8),
              Text('Si acierta todos, lobos 0. Si falla, lobos +1 cada uno', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final sorted = widget.players.toList()..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    final winner = sorted.isNotEmpty ? sorted.first : '';
    final winnerScore = _scores[winner] ?? 0;
    final isTie = sorted.length > 1 && (_scores[sorted[1]] ?? 0) == winnerScore;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RESULTADOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, color: PartyColors.text))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(isTie ? '¡EMPATE!' : winner.toUpperCase(), style: TextStyle(fontSize: isTie ? 24 : 28, fontWeight: FontWeight.w900, color: isTie ? PartyColors.primary : PartyColors.text, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(isTie ? 'Varios empatan con $winnerScore puntos' : '$winnerScore punto${winnerScore == 1 ? '' : 's'}', style: const TextStyle(fontSize: 15, color: PartyColors.primary)),
              const SizedBox(height: 24),
              ..._history.map((r) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('RONDA ${r.round}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
                            const Spacer(),
                            Icon(r.guessedCorrectly ? Icons.verified_rounded : Icons.pets_rounded, size: 14, color: r.guessedCorrectly ? PartyColors.success : PartyColors.danger),
                            const SizedBox(width: 4),
                            Text(r.guessedCorrectly ? 'ACIERTO' : (r.victim == null ? 'SIN VÍCTIMA' : 'FALLO'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.guessedCorrectly ? PartyColors.success : PartyColors.danger)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(r.prompt.replaceFirst('Yo nunca ', ''), style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: PartyColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text('Lobos: ${r.wolves.isEmpty ? '—' : r.wolves.join(', ')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PartyColors.text)),
                        if (r.victim != null) Text('Víctima: ${r.victim} • Intento: ${r.guess.isEmpty ? '—' : r.guess.join(', ')}', style: TextStyle(fontSize: 11, color: PartyColors.textSecondary)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              ...sorted.map((p) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p == winner && !isTie ? Colors.amber.withValues(alpha: 0.5) : PartyColors.border)),
                    child: Row(
                      children: [
                        if (p == winner && !isTie) const Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                        if (p == winner && !isTie) const SizedBox(width: 8),
                        Expanded(child: Text(p, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PartyColors.text))),
                        Text('${_scores[p] ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p == winner && !isTie ? Colors.amber : PartyColors.primary)),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();
                    await saveGameScores(_scores);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoboRoundResult {
  final int round;
  final String prompt;
  final Set<String> wolves;
  final String? victim;
  final bool guessedCorrectly;
  final Set<String> guess;
  const _LoboRoundResult({required this.round, required this.prompt, required this.wolves, required this.victim, required this.guessedCorrectly, required this.guess});
}
