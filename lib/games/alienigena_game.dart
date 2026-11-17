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

class AlienigenaGame extends StatefulWidget {
  final List<String> players;
  const AlienigenaGame({super.key, required this.players});

  @override
  State<AlienigenaGame> createState() => _AlienigenaGameState();
}

class _AlienigenaGameState extends State<AlienigenaGame> {
  _Phase _phase = _Phase.instructions;

  int _totalRounds = 3;
  int _currentRound = 1;

  late List<String> _shuffledPlayers;
  late int _alienIndex;
  late String _word;
  List<String> _alienOptions = [];

  int _currentPlayerIndex = 0;
  bool _showingWord = false;
  bool _revealDone = false;

  final Map<String, int> _scores = {};
  final List<_AlienRoundResult> _results = [];
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'MENTIRA'); } catch (_) {}
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    _shuffledPlayers = List.from(widget.players)..shuffle();
    _alienIndex = safeRandomIndex(_shuffledPlayers.length);
    _pickNewWord();
  }

  @override
  void dispose() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.dispose();
  }

  @override
  void deactivate() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.deactivate();
  }

  void _pickNewWord() {
    _word = GameData.randomFrom(GameData.alienWords);
    // build 4 options for alien guess: correct + 3 random distractors
    final pool = List<String>.from(GameData.alienWords)..remove(_word);
    pool.shuffle();
    final distractors = pool.take(3).toList();
    _alienOptions = [...distractors, _word]..shuffle();
  }

  String get _currentPlayer => _shuffledPlayers[_currentPlayerIndex];
  bool get _isAlien => _currentPlayerIndex == _alienIndex;

  void _startGame() => setState(() => _phase = _Phase.setup);

  void _selectRounds(int n) {
    setState(() {
      _totalRounds = n;
      _phase = _Phase.playing;
      _currentRound = 1;
      // reset reveal for round 1
      _currentPlayerIndex = 0;
      _showingWord = false;
      _revealDone = false;
    });
    try { SoundService.instance.playAmbientLoop(category: 'MENTIRA'); } catch (_) {}
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        title: Text('¿Quién es el alienígena?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _shuffledPlayers.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _onVoted(p);
                },
                style: OutlinedButton.styleFrom(foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                child: Text(p, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _onVoted(String votedPlayer) {
    final alien = _shuffledPlayers[_alienIndex];
    final caught = votedPlayer == alien;
    if (caught) {
      _showAlienGuessDialog(alien, votedPlayer);
    } else {
      _resolveRound(alien, votedPlayer, false, alienGuessedCorrect: false);
    }
  }

  void _showAlienGuessDialog(String alien, String votedPlayer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: PartyColors.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.lightbulb_outline, size: 40, color: PartyColors.warning),
              ),
              const SizedBox(height: 16),
              Text('¡Alien atrapado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text)),
              const SizedBox(height: 6),
              Text('$alien era el alien. Tiene una última oportunidad de adivinar la palabra.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary, height: 1.4)),
              const SizedBox(height: 16),
              ..._alienOptions.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final correct = opt == _word;
                      if (correct) {
                        SoundService.instance.playSuccess();
                        SoundService.instance.vibrateSuccess();
                      } else {
                        SoundService.instance.playFail();
                        SoundService.instance.vibrateShort();
                      }
                      _resolveRound(alien, votedPlayer, true, alienGuessedCorrect: correct, alienGuess: opt);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary.withValues(alpha: 0.1), foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(opt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    SoundService.instance.playFail();
                    _resolveRound(alien, votedPlayer, true, alienGuessedCorrect: false);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: PartyColors.textMuted, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('PASAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resolveRound(String alien, String votedPlayer, bool wasCaught, {required bool alienGuessedCorrect, String? alienGuess}) {
    final groupWon = wasCaught && !alienGuessedCorrect;
    _results.add(_AlienRoundResult(
      round: _currentRound,
      alien: alien,
      votedPlayer: votedPlayer,
      word: _word,
      groupWon: groupWon,
      alienGuessedCorrect: alienGuessedCorrect,
      alienGuess: alienGuess,
    ));

    setState(() {
      if (groupWon) {
        for (final p in widget.players) {
          if (p != alien) _scores[p] = (_scores[p] ?? 0) + 1;
        }
        SoundService.instance.playSuccess();
        SoundService.instance.vibrateSuccess();
      } else {
        _scores[alien] = (_scores[alien] ?? 0) + 2;
        SoundService.instance.playFail();
        SoundService.instance.vibrateShort();
      }
    });

    final hasMore = _currentRound < _totalRounds;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(groupWon ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 64, color: groupWon ? PartyColors.primary : PartyColors.danger),
              const SizedBox(height: 12),
              Text(groupWon ? '¡Correcto!' : '¡El alien gana!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: groupWon ? PartyColors.primary : PartyColors.danger)),
              const SizedBox(height: 8),
              Text('Alien era $alien', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Palabra: ', style: TextStyle(color: PartyColors.textSecondary, fontSize: 13)), Text(_word, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PartyColors.primary))]),
              ),
              if (wasCaught) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: alienGuessedCorrect ? PartyColors.danger.withValues(alpha: 0.1) : PartyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: alienGuessedCorrect ? PartyColors.danger.withValues(alpha: 0.3) : PartyColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(alienGuessedCorrect ? '¡El alien adivinó "$_word"! Gana el alien' : 'El alien falló. Gana el grupo', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: alienGuessedCorrect ? PartyColors.danger : PartyColors.primary)),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: groupWon ? PartyColors.primary.withValues(alpha: 0.1) : PartyColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: groupWon ? PartyColors.primary.withValues(alpha: 0.3) : PartyColors.danger.withValues(alpha: 0.3))),
                child: Text(groupWon ? 'Grupo +1 punto' : 'Alien +2 puntos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: groupWon ? PartyColors.primary : PartyColors.danger)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (hasMore) {
                      _nextRound();
                    } else {
                      try { SoundService.instance.stopAmbient(); } catch (_) {}
                      setState(() => _phase = _Phase.gameOver);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(hasMore ? 'RONDA ${_currentRound + 1}/$_totalRounds' : 'VER RESULTADOS', style: const TextStyle(fontWeight: FontWeight.w800)),
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
      _shuffledPlayers = List.from(widget.players)..shuffle();
      _alienIndex = safeRandomIndex(_shuffledPlayers.length);
      _pickNewWord();
      _currentPlayerIndex = 0;
      _showingWord = false;
      _revealDone = false;
    });
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
                emoji: '👽',
                title: 'ALIENÍGENA',
                subtitle: 'Todos ven una palabra menos el alien. Preguntas, votación y última oportunidad.',
                steps: [
                  'Elige partidas 1/3/5. Cada partida una palabra distinta.',
                  'Todos ven la palabra secreta menos el alien, que ve "ERES EL ALIENÍGENA".',
                  'Pasa el móvil para ver tu rol en secreto.',
                  'Haced una ronda de preguntas: cada uno pregunta a otro sobre la palabra.',
                  'Votad quién creéis que es el alien.',
                  'Si pillan al alien +1 al grupo, si no +2 al alien. Si lo pillan, el alien elige entre 4 opciones: si acierta la palabra, roba los 2 puntos.',
                  'Gana quien más puntos tenga al final.',
                ],
                onStart: _startGame,
              );
            case _Phase.setup:
              return _buildSetup();
            case _Phase.playing:
              if (!_revealDone) return _buildReveal();
              return _buildDiscussion();
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
                const Text('👽', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('¿CUÁNTAS PARTIDAS?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
                const SizedBox(height: 8),
                Text('Cada partida una palabra secreta distinta', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                const SizedBox(height: 32),
                for (final c in [1, 3, 5])
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
                        child: Text('$c PARTIDA${c > 1 ? 'S' : ''}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _totalRounds == c ? PartyColors.primary : PartyColors.text)),
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

  Widget _buildReveal() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, color: PartyColors.text))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
                child: Text(_currentPlayer.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary)),
              ),
              const SizedBox(height: 12),
              Text('Pasa el móvil para ver tu palabra', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 32),
              if (!_showingWord)
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _revealWord,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('TAP PARA VER', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: _isAlien ? PartyColors.danger.withValues(alpha: 0.5) : PartyColors.primary.withValues(alpha: 0.5), width: 2)),
                  child: Column(
                    children: [
                      if (_isAlien) ...[
                        const Text('ERES EL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: PartyColors.danger)),
                        const SizedBox(height: 8),
                        const Text('ALIENÍGENA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3, color: PartyColors.danger)),
                        const SizedBox(height: 12),
                        const Text('👽', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No sabes la palabra. Finge que sí sabes y engaña.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
                      ] else ...[
                        Text('Tu palabra es', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                        const SizedBox(height: 12),
                        Text(_word, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                        const SizedBox(height: 8),
                        Text('🤫 no la digas', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPlayer,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border))),
                    child: Text(_currentPlayerIndex < _shuffledPlayers.length - 1 ? 'SIGUIENTE JUGADOR' : 'TODOS HAN VISTO', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussion() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, color: PartyColors.text))),
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.question_answer_outlined, size: 64, color: PartyColors.primary),
                const SizedBox(height: 16),
                Text('Ronda de preguntas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PartyColors.text)),
                const SizedBox(height: 10),
                Text('Cada uno hace una pregunta a otro sobre la palabra.\nEl alien intenta pasar desapercibido.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: PartyColors.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
                  child: Column(
                    children: [
                      Text('Palabra oculta (solo para referencia)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.textMuted, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text('Ej: "¿Dónde la encuentras?"', style: TextStyle(fontSize: 13, color: PartyColors.textMuted, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _showVoteDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('VOTAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: PartyColors.textMuted, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('SALIR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
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
              ...List.generate(_results.length, (i) {
                final r = _results[i];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: r.groupWon ? PartyColors.primary.withValues(alpha: 0.3) : PartyColors.danger.withValues(alpha: 0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('RONDA ${r.round}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
                          const Spacer(),
                          Icon(r.groupWon ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: r.groupWon ? PartyColors.primary : PartyColors.danger),
                          const SizedBox(width: 4),
                          Text(r.groupWon ? 'GRUPO' : 'ALIEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.groupWon ? PartyColors.primary : PartyColors.danger)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Alien: ${r.alien} • Votaron: ${r.votedPlayer}', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Palabra: ${r.word}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.primary)),
                    ],
                  ),
                );
              }),
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

class _AlienRoundResult {
  final int round;
  final String alien;
  final String votedPlayer;
  final String word;
  final bool groupWon;
  final bool alienGuessedCorrect;
  final String? alienGuess;
  const _AlienRoundResult({required this.round, required this.alien, required this.votedPlayer, required this.word, required this.groupWon, required this.alienGuessedCorrect, this.alienGuess});
}
