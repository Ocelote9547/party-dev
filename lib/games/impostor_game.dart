// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';

class _RoundResult {
  final String impostor;
  final String votedPlayer;
  final bool wasCorrect;
  final String realWord;

  _RoundResult({
    required this.impostor,
    required this.votedPlayer,
    required this.wasCorrect,
    required this.realWord,
  });
}

class ImpostorGame extends StatefulWidget {
  final List<String> players;
  const ImpostorGame({super.key, required this.players});

  @override
  State<ImpostorGame> createState() => _ImpostorGameState();
}

class _ImpostorGameState extends State<ImpostorGame> {
  bool _showInstructions = true;
  bool _setupDone = false;
  bool _hintsForImpostor = true;
  late List<String> _shuffledPlayers;
  late int _impostorIndex;
  late String _realWord;
  late String _currentHint;

  int _currentPlayerIndex = 0;
  bool _showingWord = false;
  bool _revealDone = false;

  static const int _maxRounds = 3;
  int _currentRound = 1;

  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  final List<_RoundResult> _roundResults = [];

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'MENTIRA'); } catch (_) {}
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    _shuffledPlayers = List.from(widget.players)..shuffle();
    _impostorIndex = safeRandomIndex(_shuffledPlayers.length);
    _pickNewWords();
  }

  void _pickNewWords() {
    final pair = GameData.randomFrom(GameData.impostorPairs);
    _realWord = pair.word;
    _currentHint = pair.hint;
  }

  String get _currentPlayer => _shuffledPlayers[_currentPlayerIndex];
  bool get _isImpostor => _currentPlayerIndex == _impostorIndex;

  void _startGame() => setState(() => _showInstructions = false);

  void _revealWord() => setState(() => _showingWord = true);

  void _nextPlayer() {
    setState(() {
      _showingWord = false;
      _currentPlayerIndex++;
      if (_currentPlayerIndex >= _shuffledPlayers.length) {
        _revealDone = true;
      }
    });
  }

  void _showVoteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PartyColors.border),
        ),
        title: Text(
          '¿Quién es el impostor?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: PartyColors.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _shuffledPlayers.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _showResult(p);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.text,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResult(String votedPlayer) {
    final wasImpostor = votedPlayer == _shuffledPlayers[_impostorIndex];
    final realImpostor = _shuffledPlayers[_impostorIndex];

    if (wasImpostor) {
      _showImpostorGuessDialog(realImpostor);
    } else {
      _resolveRound(realImpostor, votedPlayer, false);
    }
  }

  void _showImpostorGuessDialog(String realImpostor) {
    final guessController = TextEditingController();
    final guessError = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PartyColors.border),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PartyColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  size: 48,
                  color: PartyColors.danger,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Impostor atrapado!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$realImpostor era el impostor',
                style: TextStyle(
                  fontSize: 14,
                  color: PartyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PartyColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PartyColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 24, color: PartyColors.warning),
                    SizedBox(height: 8),
                    Text(
                      'Última oportunidad',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.warning,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'El impostor tiene UNA oportunidad de adivinar la palabra real.\nSi acierta, ¡gana la ronda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: PartyColors.warning,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<bool>(
                valueListenable: guessError,
                builder: (_, hasError, _) => Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: PartyColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError ? PartyColors.danger : PartyColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: guessController,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PartyColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: '¿Cuál es la palabra?',
                          hintStyle: TextStyle(color: PartyColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _submitGuess(ctx, guessController, guessError, realImpostor),
                      ),
                    ),
                    if (hasError) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Escribe una palabra',
                        style: TextStyle(fontSize: 11, color: PartyColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _submitGuess(ctx, guessController, guessError, realImpostor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'ADIVINAR',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    guessController.dispose();
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.textMuted,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitGuess(
    BuildContext ctx,
    TextEditingController guessController,
    ValueNotifier<bool> guessError,
    String realImpostor,
  ) {
    final guess = guessController.text.trim();
    if (guess.isEmpty) {
      guessError.value = true;
      return;
    }
    guessController.dispose();
    Navigator.pop(ctx);

    final correct = guess.toLowerCase().trim() == _realWord.toLowerCase().trim();
    _resolveRound(realImpostor, realImpostor, correct);
  }

  void _resolveRound(String realImpostor, String votedPlayer, bool impostorGuessedCorrect) {
    final wasImpostor = votedPlayer == realImpostor;
    final hasMoreRounds = _currentRound < _maxRounds;

    _roundResults.add(_RoundResult(
      impostor: realImpostor,
      votedPlayer: votedPlayer,
      wasCorrect: wasImpostor && !impostorGuessedCorrect,
      realWord: _realWord,
    ));

    setState(() {
      if (wasImpostor && !impostorGuessedCorrect) {
        for (final p in widget.players) {
          if (p != realImpostor) {
            _scores[p] = (_scores[p] ?? 0) + 1;
          }
        }
      } else {
        _scores[realImpostor] = (_scores[realImpostor] ?? 0) + 2;
      }
    });

    final bool villagersWon = wasImpostor && !impostorGuessedCorrect;
    final bool impostorWasCaught = wasImpostor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PartyColors.border),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                villagersWon ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 72,
                color: villagersWon
                    ? PartyColors.primary
                    : PartyColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                villagersWon ? '¡Correcto!' : '¡Incorrecto!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: villagersWon
                      ? PartyColors.primary
                      : PartyColors.danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                impostorWasCaught
                    ? '$realImpostor era el impostor'
                    : 'El impostor era $realImpostor',
                style: TextStyle(
                  fontSize: 14,
                  color: PartyColors.textSecondary,
                ),
              ),
              if (impostorWasCaught) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: impostorGuessedCorrect
                        ? PartyColors.danger.withValues(alpha: 0.1)
                        : PartyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: impostorGuessedCorrect
                          ? PartyColors.danger.withValues(alpha: 0.3)
                          : PartyColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    impostorGuessedCorrect
                        ? '¡El impostor adivinó la palabra! Gana el impostor'
                        : '¡El impostor falló! Ganan los aldeanos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: impostorGuessedCorrect
                          ? PartyColors.danger
                          : PartyColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PartyColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Real: ', style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
                    Text(_realWord, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (villagersWon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Aldeanos +1 punto',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.primary),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: PartyColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PartyColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Impostor +2 puntos',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.danger),
                  ),
                ),
              const SizedBox(height: 20),
              _buildScoresRow(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (hasMoreRounds) {
                      _nextRound();
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _GameOverScreen(
                            roundResults: _roundResults,
                            scores: Map.from(_scores),
                            players: widget.players,
                            onVolver: () async {
                              await _handleGameCompleted();
                              await saveGameScores(Map.from(_scores));
                            },
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    hasMoreRounds ? 'RONDA ${_currentRound + 1}/$_maxRounds' : 'VER RESULTADOS',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.textMuted,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _currentPlayerIndex = 0;
      _showingWord = false;
      _revealDone = false;
      _pickNewWords();
      _shuffledPlayers = List.from(widget.players)..shuffle();
      _impostorIndex = safeRandomIndex(_shuffledPlayers.length);
    });
  }

  Widget _buildScoresRow() {
    final sorted = widget.players.toList()
      ..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PartyColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARCADOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: PartyColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ...sorted.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PartyColors.text,
                  ),
                ),
                Text(
                  '${_scores[p] ?? 0}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.primary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
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
        emoji: '🕵️',
        title: 'IMPOSTOR',
        subtitle: 'Descubre quién está mintiendo entre vosotros.',
        steps: [
          'Todos reciben la palabra. El impostor NO la recibe.',
          'Votad quién creéis que es el impostor.',
          'Si acertáis, el impostor tiene una última oportunidad de adivinar la palabra.',
          'Si la adivina, gana el impostor (+2). Si falla, ganan los demás (+1).',
          'Si no acertáis, gana el impostor (+2 puntos).',
          '3 rondas con palabras distintas. ¡El que más puntos tenga gana!',
        ],
        onStart: _startGame,
      );
    }
    if (!_setupDone) return _buildSetup();
    if (!_revealDone) return _buildRevealPhase();
    return _buildVotingScreen();
  
        },
      ),
    );
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('IMPOSTOR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🕵️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Configuración', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Elige si el impostor recibe pista', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: PartyColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PartyColors.border),
                ),
                child: SwitchListTile(
                  title: const Text('Pistas para el impostor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  subtitle: Text(_hintsForImpostor ? 'El impostor verá una pista' : 'El impostor no verá pista', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
                  value: _hintsForImpostor,
                  activeThumbColor: PartyColors.primary,
                  onChanged: (v) => setState(() => _hintsForImpostor = v),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _setupDone = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('CONTINUAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevealPhase() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RONDA $_currentRound/$_maxRounds',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: PartyColors.text,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _currentPlayer.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: PartyColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pasa el móvil para ver tu palabra',
                style: TextStyle(fontSize: 14, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 40),
              if (!_showingWord)
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _revealWord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'TAP PARA VER TU PALABRA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isImpostor
                          ? PartyColors.danger.withValues(alpha: 0.5)
                          : PartyColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isImpostor) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'ERES EL IMPOSTOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: PartyColors.danger,
                          ),
                        ),
                        if (_hintsForImpostor) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: PartyColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: PartyColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Pista: $_currentHint',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.warning),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ] else ...[
                        Text(
                          'Tu palabra es',
                          style: TextStyle(fontSize: 14, color: PartyColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _realWord,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: PartyColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.surface,
                      foregroundColor: PartyColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: PartyColors.border),
                      ),
                    ),
                    child: Text(
                      _currentPlayerIndex < _shuffledPlayers.length - 1
                          ? 'SIGUIENTE JUGADOR'
                          : 'TODOS HAN VISTO SU PALABRA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RONDA $_currentRound/$_maxRounds',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: PartyColors.text,
          ),
        ),
      ),
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.how_to_vote_outlined, size: 64, color: PartyColors.primary),
              const SizedBox(height: 24),
              Text(
                '¡A votar!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PartyColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Discutid entre vosotros y decidid.\n¿Quién creéis que es el impostor?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _showVoteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'VOTAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.text,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  final List<_RoundResult> roundResults;
  final Map<String, int> scores;
  final List<String> players;
  final Future<void> Function() onVolver;

  const _GameOverScreen({
    required this.roundResults,
    required this.scores,
    required this.players,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = players.toList()
      ..sort((a, b) => (scores[b] ?? 0).compareTo((scores[a] ?? 0)));
    final winner = sorted.first;
    final winnerScore = scores[winner] ?? 0;
    final isTie = sorted.length > 1 && (scores[sorted[1]] ?? 0) == winnerScore;

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RESULTADOS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, color: PartyColors.text),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                isTie ? '¡EMPATE!' : winner.toUpperCase(),
                style: TextStyle(
                  fontSize: isTie ? 24 : 28,
                  fontWeight: FontWeight.w900,
                  color: isTie ? PartyColors.primary : PartyColors.text,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isTie
                    ? 'Varios jugadores empatan con $winnerScore puntos'
                    : '$winnerScore punto${winnerScore == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 15, color: PartyColors.primary),
              ),
              const SizedBox(height: 28),
              ...List.generate(roundResults.length, (i) {
                final r = roundResults[i];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: r.wasCorrect
                          ? PartyColors.primary.withValues(alpha: 0.3)
                          : PartyColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'RONDA ${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: PartyColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            r.wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 18,
                            color: r.wasCorrect ? PartyColors.primary : PartyColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r.wasCorrect ? 'ACERTADA' : 'FALLADA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: r.wasCorrect ? PartyColors.primary : PartyColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _infoChip('Impostor', r.impostor),
                          const SizedBox(width: 8),
                          _infoChip('Votaron a', r.votedPlayer),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.realWord,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PartyColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text(
                'MARCADOR FINAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: PartyColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...sorted.map((p) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: PartyColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: p == winner && !isTie
                        ? Colors.amber.withValues(alpha: 0.5)
                        : PartyColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    if (p == winner && !isTie) const Icon(Icons.emoji_events, size: 22, color: Colors.amber),
                    if (p == winner && !isTie) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: p == winner && !isTie ? FontWeight.w800 : FontWeight.w600,
                          color: PartyColors.text,
                        ),
                      ),
                    ),
                    Text(
                      '${scores[p] ?? 0}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: p == winner && !isTie ? Colors.amber : PartyColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await onVolver();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'VOLVER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PartyColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(fontSize: 11, color: PartyColors.textMuted),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PartyColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}