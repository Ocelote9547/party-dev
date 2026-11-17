// ignore_for_file: use_build_context_synchronously
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/angeles_service.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';

enum _Phase { instructions, assignReveal, playing, guessing, gameOver }

class AngelesDemoniosGame extends StatefulWidget {
  final List<String> players;
  const AngelesDemoniosGame({super.key, required this.players});

  @override
  State<AngelesDemoniosGame> createState() => _AngelesDemoniosGameState();
}

class _AngelesDemoniosGameState extends State<AngelesDemoniosGame> {
  _Phase _phase = _Phase.instructions;

  // Asignación ángel/demonio
  final Map<String, String> _angelOf = {};
  final Map<String, String> _demonOf = {};
  Map<String, ({String angel, String demon})> _assigned = {};
  int _currentRevealIndex = 0;
  bool _showingReveal = false;

  // Guessing
  int _currentGuesserIndex = 0;
  final Map<String, (String?, String?)> _guesses = {};
  String? _tempAngelGuess;
  String? _tempDemonGuess;

  // Scores
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  @override
  void initState() {
    super.initState();
    try {
      SoundService.instance.playAmbientLoop(category: 'MENTIRA');
    } catch (_) {}
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    _assignAngelsAndDemons();
  }

  @override
  void dispose() {
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    restoreOrientation();
    super.dispose();
  }

  @override
  void deactivate() {
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    restoreOrientation();
    super.deactivate();
  }

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  void _assignAngelsAndDemons() {
    _angelOf.clear();
    _demonOf.clear();
    _assigned = {};
    final players = List<String>.from(widget.players);
    if (players.length < 2) return;
    final rnd = Random();
    players.shuffle(rnd);

    final angelCount = <String, int>{for (final p in widget.players) p: 0};
    final demonCount = <String, int>{for (final p in widget.players) p: 0};

    for (final p in players) {
      final others = widget.players.where((o) => o != p).toList();

      String angel;
      if (others.length == 1) {
        angel = others.first;
      } else {
        final shuffledOthers = List<String>.from(others)..shuffle(rnd);
        shuffledOthers.sort(
            (a, b) => (angelCount[a] ?? 0).compareTo(angelCount[b] ?? 0));
        final minCount = angelCount[shuffledOthers.first] ?? 0;
        final candidates = shuffledOthers
            .where((c) => (angelCount[c] ?? 0) == minCount)
            .toList();
        angel = candidates[rnd.nextInt(candidates.length)];
      }

      String demon;
      final demonPool = others.where((o) => o != angel).toList();
      if (demonPool.isEmpty) {
        demon = angel;
      } else if (demonPool.length == 1) {
        demon = demonPool.first;
      } else {
        final shuffledDemonPool = List<String>.from(demonPool)..shuffle(rnd);
        shuffledDemonPool.sort(
            (a, b) => (demonCount[a] ?? 0).compareTo(demonCount[b] ?? 0));
        final minD = demonCount[shuffledDemonPool.first] ?? 0;
        final cands = shuffledDemonPool
            .where((c) => (demonCount[c] ?? 0) == minD)
            .toList();
        demon = cands[rnd.nextInt(cands.length)];
      }

      _angelOf[p] = angel;
      _demonOf[p] = demon;
      angelCount[angel] = (angelCount[angel] ?? 0) + 1;
      demonCount[demon] = (demonCount[demon] ?? 0) + 1;
    }
    _assigned = {
      for (final p in widget.players)
        if (_angelOf.containsKey(p) && _demonOf.containsKey(p))
          p: (angel: _angelOf[p]!, demon: _demonOf[p]!),
    };
  }

  void _startFromInstructions() {
    setState(() => _phase = _Phase.assignReveal);
  }

  void _onTapReveal() {
    setState(() => _showingReveal = true);
  }

  Future<void> _nextReveal() async {
    SoundService.instance.playTick();
    if (_currentRevealIndex < widget.players.length - 1) {
      setState(() {
        _currentRevealIndex++;
        _showingReveal = false;
      });
    } else {
      // Último jugador: guardar asignación y pasar a playing
      try {
        await AngelesService.instance.saveAssignment(_assigned);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _phase = _Phase.playing;
      });
    }
  }

  void _goToGuessing() {
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    for (final p in widget.players) {
      _guesses[p] = (null, null);
    }
    setState(() {
      _phase = _Phase.guessing;
      _currentGuesserIndex = 0;
      _tempAngelGuess = null;
      _tempDemonGuess = null;
    });
  }

  Future<void> _reviewMyAssignment() async {
    // Paso 1: elegir quién eres (pasar el móvil)
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Text('¿Quién eres?',
            style: TextStyle(
                color: PartyColors.text, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pasa el móvil y toca tu nombre en privado.',
                    style:
                        TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                const SizedBox(height: 12),
                ...widget.players.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, p),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: PartyColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: PartyColors.text)),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final assignment = _assigned[selected];
    final angel = assignment?.angel ?? _angelOf[selected] ?? '-';
    final demon = assignment?.demon ?? _demonOf[selected] ?? '-';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Text(selected.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: PartyColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Solo tú debes ver esto',
                style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: PartyColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: PartyColors.primary.withValues(alpha: 0.3))),
              child: Column(
                children: [
                  const Text('👼', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Tu ángel es:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PartyColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(angel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: PartyColors.success)),
                  const SizedBox(height: 12),
                  Container(height: 1, color: PartyColors.border),
                  const SizedBox(height: 12),
                  const Text('😈', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Tu demonio es:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PartyColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(demon,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: PartyColors.danger)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
                backgroundColor: PartyColors.primary,
                foregroundColor: PartyColors.onPrimary),
            child: const Text('OCULTAR'),
          ),
        ],
      ),
    );
  }

  void _nextGuesser() {
    final player = widget.players[_currentGuesserIndex];
    _guesses[player] = (_tempAngelGuess, _tempDemonGuess);
    SoundService.instance.playTick();
    if (_currentGuesserIndex < widget.players.length - 1) {
      setState(() {
        _currentGuesserIndex++;
        _tempAngelGuess = null;
        _tempDemonGuess = null;
      });
    } else {
      _calculateScoresAndFinish();
    }
  }

  void _calculateScoresAndFinish() {
    for (final p in widget.players) {
      int pts = 0;
      final guess = _guesses[p];
      final gAngel = guess?.$1;
      final gDemon = guess?.$2;
      if (gAngel != null && gAngel == _angelOf[p]) pts += 2;
      if (gDemon != null && gDemon == _demonOf[p]) pts += 2;
      _scores[p] = pts;
    }
    setState(() => _phase = _Phase.gameOver);
    SoundService.instance.playGameOver();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) {
      return const NeedPlayersScreen(minPlayers: 4);
    }
    if (widget.players.length < 4) {
      return const NeedPlayersScreen(minPlayers: 4);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PartyColors.surface,
            title: Text('¿Seguro que quieres salir?',
                style: TextStyle(
                    color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderás el progreso',
                style: TextStyle(color: PartyColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                      backgroundColor: PartyColors.danger),
                  child: const Text('Salir')),
            ],
          ),
        );
        if (shouldPop == true) {
          try {
            SoundService.instance.stopAmbient();
          } catch (_) {}
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {
          switch (_phase) {
            case _Phase.instructions:
              return GameInstructions(
                emoji: '👼😈',
                title: 'ÁNGELES Y DEMONIOS',
                subtitle: 'Adivina quién es tu ángel y tu demonio.',
                steps: [
                  'Al inicio a cada jugador se le asigna 1 ángel y 1 demonio (otros jugadores).',
                  'Tú también eres ángel/demonio de alguien.',
                  'Ángeles deben hablar bien a su consentido, demonios putear/ignorar pero puedes hacer de ángel/demonio de quien quieras para despistar.',
                  'Pasa el móvil y mira en privado quiénes son tu ángel y tu demonio.',
                  'Partida guardada: jugad a otros juegos y actuad como ángel/demonio durante la noche.',
                  'Al final volved aquí a adivinar quién es tu ángel y tu demonio: +2 puntos por cada acierto.',
                ],
                onStart: _startFromInstructions,
              );
            case _Phase.assignReveal:
              return _buildAssignReveal();
            case _Phase.playing:
              return _buildPlaying();
            case _Phase.guessing:
              return _buildGuessing();
            case _Phase.gameOver:
              return _buildGameOver();
          }
        },
      ),
    );
  }

  Widget _buildAssignReveal() {
    final player = widget.players[_currentRevealIndex];
    final angel = _angelOf[player] ?? '';
    final demon = _demonOf[player] ?? '';
    final isLast = _currentRevealIndex == widget.players.length - 1;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('REVELACIÓN ${_currentRevealIndex + 1}/${widget.players.length}',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: PartyColors.text,
                fontSize: 13)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PartyColors.primary.withValues(alpha: 0.3))),
                child: Text(player.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: PartyColors.primary)),
              ),
              const SizedBox(height: 12),
              Text(
                  _showingReveal
                      ? 'Solo tú debes ver esto'
                      : 'Pasa el móvil a $player',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 32),
              if (!_showingReveal) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: PartyColors.border)),
                  child: Column(
                    children: [
                      const Text('👀', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('Toca para revelar',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PartyColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('No muestres a los demás',
                          style: TextStyle(
                              fontSize: 12, color: PartyColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onTapReveal,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('VER MI ÁNGEL Y DEMONIO',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: PartyColors.primary.withValues(alpha: 0.4),
                          width: 1.5)),
                  child: Column(
                    children: [
                      const Text('👼', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text('Tu ángel es:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: PartyColors.textMuted)),
                      const SizedBox(height: 6),
                      Text(angel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: PartyColors.success)),
                      const SizedBox(height: 20),
                      Container(height: 1, color: PartyColors.border),
                      const SizedBox(height: 20),
                      const Text('😈', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text('Tu demonio es:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: PartyColors.textMuted)),
                      const SizedBox(height: 6),
                      Text(demon,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: PartyColors.danger)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                    'Recuerda: háblale bien a tu ángel, putea/ignora a tu demonio. Puedes despistar haciendo de ángel/demonio de quien quieras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: PartyColors.textSecondary,
                        height: 1.4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextReveal,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: Text(isLast ? 'GUARDAR Y JUGAR' : 'SIGUIENTE',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ),
              ],
              if (_showingReveal) ...[
                const SizedBox(height: 10),
                Text('Tapa la pantalla antes de pasar el móvil',
                    style:
                        TextStyle(fontSize: 11, color: PartyColors.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('ÁNGELES Y DEMONIOS',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: PartyColors.text,
                  fontSize: 13))),
      body: AnimatedPartyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: PartyColors.primary.withValues(alpha: 0.3))),
                  child: Column(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text('PARTIDA GUARDADA',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: PartyColors.text)),
                      const SizedBox(height: 10),
                      Text(
                          'Juega a otros juegos y actúa como ángel/demonio. Cuando acabe la noche, volved aquí a adivinar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: PartyColors.textSecondary,
                              height: 1.4)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color:
                                PartyColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: PartyColors.primary
                                    .withValues(alpha: 0.15))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save_rounded,
                                size: 14, color: PartyColors.primary),
                            const SizedBox(width: 6),
                            Text('${widget.players.length} jugadores • asignación guardada',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: PartyColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PartyColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('JUGADORES',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: PartyColors.textMuted)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.players
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: PartyColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: PartyColors.border)),
                                  child: Text(p,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: PartyColors.text)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PartyColors.border)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('👼', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('Habla bien a tu ángel',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: PartyColors.text))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('😈', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('Putea/ignora a tu demonio',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: PartyColors.text))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '¡Despista haciendo de ángel/demonio de quien quieras!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: PartyColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _reviewMyAssignment,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.text,
                        side: BorderSide(color: PartyColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('REVISAR MI ASIGNACIÓN',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _goToGuessing,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('IR A VOTACIÓN',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessing() {
    final player = widget.players[_currentGuesserIndex];
    final others = widget.players.where((p) => p != player).toList();
    final canContinue = _tempAngelGuess != null && _tempDemonGuess != null;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('VOTACIÓN ${_currentGuesserIndex + 1}/${widget.players.length}',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: PartyColors.text,
                fontSize: 13)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PartyColors.primary.withValues(alpha: 0.3))),
                child: Text(player.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: PartyColors.primary)),
              ),
              const SizedBox(height: 8),
              Text('¿Quién crees que es tu ángel y tu demonio?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PartyColors.success.withValues(alpha: 0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('👼', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('Tu ángel es...',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: PartyColors.text))
                    ]),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: others.map((o) {
                        final selected = _tempAngelGuess == o;
                        return ChoiceChip(
                          label: Text(o),
                          selected: selected,
                          onSelected: (v) => setState(() => _tempAngelGuess = o),
                          selectedColor:
                              PartyColors.success.withValues(alpha: 0.2),
                          backgroundColor: PartyColors.background,
                          side: BorderSide(
                              color: selected
                                  ? PartyColors.success
                                  : PartyColors.border),
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? PartyColors.success
                                  : PartyColors.text,
                              fontSize: 13),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PartyColors.danger.withValues(alpha: 0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('😈', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('Tu demonio es...',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: PartyColors.text))
                    ]),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: others.map((o) {
                        final selected = _tempDemonGuess == o;
                        return ChoiceChip(
                          label: Text(o),
                          selected: selected,
                          onSelected: (v) => setState(() => _tempDemonGuess = o),
                          selectedColor:
                              PartyColors.danger.withValues(alpha: 0.15),
                          backgroundColor: PartyColors.background,
                          side: BorderSide(
                              color: selected
                                  ? PartyColors.danger
                                  : PartyColors.border),
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? PartyColors.danger
                                  : PartyColors.text,
                              fontSize: 13),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canContinue ? _nextGuesser : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      disabledBackgroundColor: PartyColors.border,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: Text(
                      _currentGuesserIndex < widget.players.length - 1
                          ? 'SIGUIENTE'
                          : 'VER RESULTADOS',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ),
              if (!canContinue) ...[
                const SizedBox(height: 8),
                Text('Elige tu ángel y tu demonio para continuar',
                    style:
                        TextStyle(fontSize: 11, color: PartyColors.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final sorted = widget.players.toList()
      ..sort((a, b) => (_scores[b] ?? 0).compareTo((_scores[a] ?? 0)));
    final winner = sorted.isNotEmpty ? sorted.first : '';
    final winnerScore = _scores[winner] ?? 0;
    final isTie =
        sorted.length > 1 && (_scores[sorted[1]] ?? 0) == winnerScore;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('RESULTADOS',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: PartyColors.text))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(isTie ? '¡EMPATE!' : winner.toUpperCase(),
                  style: TextStyle(
                      fontSize: isTie ? 24 : 28,
                      fontWeight: FontWeight.w900,
                      color: isTie ? PartyColors.primary : PartyColors.text,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(
                  isTie
                      ? 'Varios empatan con $winnerScore puntos'
                      : '$winnerScore punto${winnerScore == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 15, color: PartyColors.primary)),
              const SizedBox(height: 24),
              ...sorted.map((p) {
                final isWinner = p == winner && !isTie;
                final angelReal = _angelOf[p] ?? '-';
                final demonReal = _demonOf[p] ?? '-';
                final guess = _guesses[p];
                final gAngel = guess?.$1 ?? '-';
                final gDemon = guess?.$2 ?? '-';
                final angelOk = gAngel == angelReal;
                final demonOk = gDemon == demonReal;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isWinner
                            ? Colors.amber.withValues(alpha: 0.5)
                            : PartyColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isWinner)
                            const Icon(Icons.emoji_events,
                                size: 20, color: Colors.amber),
                          if (isWinner) const SizedBox(width: 8),
                          Expanded(
                              child: Text(p,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: PartyColors.text))),
                          Text('${_scores[p] ?? 0} pts',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isWinner
                                      ? Colors.amber
                                      : PartyColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                  color: angelOk
                                      ? PartyColors.success
                                          .withValues(alpha: 0.12)
                                      : PartyColors.danger
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: angelOk
                                          ? PartyColors.success
                                              .withValues(alpha: 0.3)
                                          : PartyColors.danger
                                              .withValues(alpha: 0.2))),
                              child: Column(
                                children: [
                                  Text('👼 Ángel',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: PartyColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(angelReal,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: PartyColors.text)),
                                  const SizedBox(height: 2),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(gAngel,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    PartyColors.textSecondary)),
                                        const SizedBox(width: 4),
                                        Icon(
                                            angelOk
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            size: 14,
                                            color: angelOk
                                                ? PartyColors.success
                                                : PartyColors.danger),
                                      ]),
                                  Text(angelOk ? '+2' : '+0',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: angelOk
                                              ? PartyColors.success
                                              : PartyColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                  color: demonOk
                                      ? PartyColors.success
                                          .withValues(alpha: 0.12)
                                      : PartyColors.danger
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: demonOk
                                          ? PartyColors.success
                                              .withValues(alpha: 0.3)
                                          : PartyColors.danger
                                              .withValues(alpha: 0.2))),
                              child: Column(
                                children: [
                                  Text('😈 Demonio',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: PartyColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(demonReal,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: PartyColors.text)),
                                  const SizedBox(height: 2),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(gDemon,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    PartyColors.textSecondary)),
                                        const SizedBox(width: 4),
                                        Icon(
                                            demonOk
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            size: 14,
                                            color: demonOk
                                                ? PartyColors.success
                                                : PartyColors.danger),
                                      ]),
                                  Text(demonOk ? '+2' : '+0',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: demonOk
                                              ? PartyColors.success
                                              : PartyColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();
                    await saveGameScores(_scores);
                    try {
                      await AngelesService.instance.clear();
                    } catch (_) {}
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOLVER',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
