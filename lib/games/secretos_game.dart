// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';

class SecretosGame extends StatefulWidget {
  final List<String> players;
  const SecretosGame({super.key, required this.players});

  @override
  State<SecretosGame> createState() => _SecretosGameState();
}

class _SecretosGameState extends State<SecretosGame> {
  bool _showInstructions = true;
  int _currentRound = 1;
  final int _maxRounds = 10;
  bool _showVoting = false;
  bool _showResult = false;
  late List<String> _shuffledSecrets;
  String _currentSecret = '';
  String? _votedPlayer;
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  bool _gameOver = false;

  int _writingPlayerIndex = 0;
  final Map<String, String> _playerSecrets = {};
  final TextEditingController _secretController = TextEditingController();
  bool _writePhaseDone = false;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'MENTIRA'); } catch (_) {}
  }

  @override
  void dispose() {
    _secretController.dispose();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.dispose();
  }

  void _startGameFromInstructions() => setState(() => _showInstructions = false);

  void _saveSecret() {
    final text = _secretController.text.trim();
    if (text.isEmpty) return;
    final player = widget.players[_writingPlayerIndex];
    _playerSecrets[player] = text;
    _secretController.clear();

    if (_writingPlayerIndex < widget.players.length - 1) {
      setState(() => _writingPlayerIndex++);
    } else {
      final allSecrets = _playerSecrets.values.toList()..shuffle();
      _shuffledSecrets = allSecrets;
      if (_shuffledSecrets.isEmpty) {
        setState(() => _gameOver = true);
        return;
      }
      _currentSecret = _shuffledSecrets[0];
      setState(() {
        _writePhaseDone = true;
      });
    }
  }

  void _startVoting() => setState(() => _showVoting = true);

  void _voteFor(String player) {
    final writer = _writerOfCurrentSecret;
    final wasCorrect = writer == player;
    setState(() {
      _votedPlayer = player;
      _showVoting = false;
      _showResult = true;
      if (wasCorrect) {
        _scores[player] = (_scores[player] ?? 0) + 1;
      } else {
        _scores[player] = (_scores[player] ?? 0) - 1;
        _scores[writer] = (_scores[writer] ?? 0) + 2;
      }
    });
  }

  String get _writerOfCurrentSecret {
    for (final entry in _playerSecrets.entries) {
      if (entry.value == _currentSecret) return entry.key;
    }
    return '';
  }

  void _nextRound() {
    if (_currentRound >= _maxRounds) {
      setState(() => _gameOver = true);
      return;
    }
    setState(() {
      _currentRound++;
      _currentSecret = _shuffledSecrets[(_currentRound - 1) % _shuffledSecrets.length];
      _showResult = false;
      _showVoting = false;
      _votedPlayer = null;
    });
  }

  Widget _entrance(Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0).toDouble(), child: child),
        ),
        child: child,
      );

  Widget _slideFade(Widget child, Animation<double> animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      );

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
            title: Text('¿Seguro que quieres salir?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
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

    if (_showInstructions) {
      return GameInstructions(
        emoji: '🔐',
        title: 'SECRETOS',
        subtitle: '¿Quién se esconde detrás del secreto?',
        steps: [
          'Cada jugador escribe un secreto personal.',
          'Los secretos se mezclan y se leen en voz alta.',
          'Todos votan a quién creen que le corresponde.',
          'Aciertas: +1 punto. Fallas: -1 punto, autor +2.',
        ],
        onStart: _startGameFromInstructions,
      );
    }
    if (!_writePhaseDone) return _buildWritingPhase();
    if (_gameOver) return _buildGameOverScreen();
    return _buildGameScreen();
  
        },
      ),
    );
  }

  Widget _buildWritingPhase() {
    final currentPlayer = widget.players[_writingPlayerIndex];
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SECRETOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔐', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _slideFade,
                child: Container(
                  key: ValueKey<int>(_writingPlayerIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Turno de $currentPlayer',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Escribe un secreto personal',
                style: TextStyle(fontSize: 15, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _secretController,
                maxLines: 3,
                style: TextStyle(color: PartyColors.text, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Escribe tu secreto aquí...',
                  hintStyle: TextStyle(color: PartyColors.textMuted),
                  filled: true,
                  fillColor: PartyColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: PartyColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: PartyColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: PartyColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _saveSecret,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    _writingPlayerIndex < widget.players.length - 1 ? 'GUARDAR SECRETO' : 'EMPEZAR JUEGO',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_writingPlayerIndex + 1} / ${widget.players.length}',
                style: TextStyle(fontSize: 14, color: PartyColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('RESULTADOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _entrance(Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔐', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Resultados finales', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 24),
              ...sorted.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                  child: Row(children: [
                    Text(e.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.text)),
                    const Spacer(),
                    Text('${e.value}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                  ]),
                ),
              )),
              if (sorted.isEmpty)
                Text('No se registraron puntos', style: TextStyle(fontSize: 14, color: PartyColors.textMuted)),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();

                    await saveGameScores(_scores);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final isCorrectGuess = _votedPlayer == _writerOfCurrentSecret;
    final writerName = _writerOfCurrentSecret;

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('SECRETOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: _currentRound >= _maxRounds ? PartyColors.warning.withValues(alpha: 0.2) : PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text('RONDA $_currentRound/$_maxRounds', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _currentRound >= _maxRounds ? PartyColors.warning : PartyColors.primary)),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedPartyBackground(child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentRound >= _maxRounds)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('¡ÚLTIMA RONDA!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.warning, letterSpacing: 1)),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _slideFade,
                child: _showVoting
                    ? KeyedSubtree(
                        key: const ValueKey('vote'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('¿Quién es?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.text)),
                            const SizedBox(height: 8),
                            Text('Vota a quien creas que escribió esto', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                            const SizedBox(height: 24),
                            ...widget.players.map((p) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _voteFor(p),
                                style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: PartyColors.border))),
                                child: Text(p, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            )),
                          ],
                        ),
                      )
                    : _showResult
                        ? KeyedSubtree(
                            key: ValueKey<String>('result-$_currentRound'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _entrance(Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isCorrectGuess ? PartyColors.success.withValues(alpha: 0.1) : PartyColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: isCorrectGuess ? PartyColors.success.withValues(alpha: 0.5) : PartyColors.warning.withValues(alpha: 0.5), width: 2),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(isCorrectGuess ? '✅' : '❌', style: const TextStyle(fontSize: 48)),
                                      const SizedBox(height: 12),
                                      Text(
                                        isCorrectGuess ? '¡Correcto! +1 punto' : '¡Incorrecto!',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isCorrectGuess ? PartyColors.success : PartyColors.warning),
                                      ),
                                      if (!isCorrectGuess) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Votante: -1  ·  ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PartyColors.danger)),
                                            Text('Autor: +2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PartyColors.success)),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Text('Votaste por:', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(_votedPlayer ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PartyColors.text)),
                                      const SizedBox(height: 16),
                                      Text('El secreto era de:', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(writerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PartyColors.primary)),
                                      const SizedBox(height: 12),
                                      Text(_currentSecret, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PartyColors.textSecondary, height: 1.4)),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _currentRound >= _maxRounds ? () => setState(() => _gameOver = true) : _nextRound,
                                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: Text(_currentRound >= _maxRounds ? 'JUEGO TERMINADO' : 'SIGUIENTE SECRETO', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : KeyedSubtree(
                            key: ValueKey<String>('secret-$_currentRound'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: PartyColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('🔐', style: TextStyle(fontSize: 48)),
                                      const SizedBox(height: 16),
                                      Text(_currentSecret, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PartyColors.text, height: 1.5)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 64,
                                  child: ElevatedButton(
                                    onPressed: _startVoting,
                                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: const Text('VOTAR AHORA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('SALIR DEL JUEGO', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}