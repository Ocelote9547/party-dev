// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';

enum _Phase { instructions, setup, playing, roundEnd, gameOver }

class EnsaladaGame extends StatefulWidget {
  final List<String> players;
  const EnsaladaGame({super.key, required this.players});

  @override
  State<EnsaladaGame> createState() => _EnsaladaGameState();
}

class _EnsaladaGameState extends State<EnsaladaGame> {
  _Phase _phase = _Phase.instructions;

  bool _includeR4 = true;
  late List<String> _masterWords;
  List<String> _bowl = [];
  String _currentWord = '';

  int _currentRound = 1;
  int get _totalRounds => _includeR4 ? 4 : 3;

  List<List<String>> _pairs = [];
  int _currentPairIndex = 0;
  List<String> get _currentPair => _pairs.isEmpty ? [] : _pairs[_currentPairIndex];
  String get _currentPairLabel => _currentPair.join(' & ');

  final Map<String, int> _pairTotal = {};
  final Map<String, List<int>> _pairRounds = {};

  int _secondsLeft = 30;
  Timer? _timer;
  bool _economyAwarded = false;
  bool _waitingForTurn = true;
  bool _turnActive = false;

  // For roundEnd summary
  Map<String, int> _lastRoundGained = {};

  static const _roundNames = {
    1: 'DESCRIBIR',
    2: 'UNA PALABRA',
    3: 'MÍMICA',
    4: 'SONIDOS',
  };
  static const _roundEmojis = {
    1: '🗣️',
    2: '💬',
    3: '🎭',
    4: '🔊',
  };
  static const _roundHints = {
    1: 'Describe sin decir la palabra.',
    2: 'Solo UNA palabra como pista.',
    3: 'Solo mímica, sin hablar ni sonidos.',
    4: 'Solo sonidos, sin palabras ni mímica.',
  };

  String get _roundName => _roundNames[_currentRound] ?? 'RONDA $_currentRound';
  String get _roundEmoji => _roundEmojis[_currentRound] ?? '🥗';
  String get _roundHint => _roundHints[_currentRound] ?? '';

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  @override
  void initState() {
    super.initState();
    try {
      SoundService.instance.playAmbientLoop(category: 'PALABRAS');
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _startSetup() {
    setState(() => _phase = _Phase.setup);
  }

  void _makePairs() {
    final shuffled = List<String>.from(widget.players)..shuffle(Random());
    _pairs = [];
    for (int i = 0; i < shuffled.length; i += 2) {
      if (i + 1 < shuffled.length) {
        _pairs.add([shuffled[i], shuffled[i + 1]]);
      } else {
        // odd leftover -> merge into last pair as trio
        if (_pairs.isNotEmpty) {
          _pairs.last = [..._pairs.last, shuffled[i]];
        } else {
          _pairs.add([shuffled[i]]);
        }
      }
    }
    // edge: 5 players -> pairs like [2,2,1] merged -> [2,3]; good.
    // ensure at least 2 pairs when possible
  }

  void _initScores() {
    _pairTotal.clear();
    _pairRounds.clear();
    for (final p in _pairs) {
      final label = p.join(' & ');
      _pairTotal[label] = 0;
      _pairRounds[label] = List.filled(4, 0);
    }
  }

  void _generateMasterWords() {
    final pool = List<String>.from(GameData.ensaladaPool)..shuffle(Random());
    final n = widget.players.length * 3;
    final needed = n.clamp(0, pool.length);
    _masterWords = pool.take(needed).toList();
    if (_masterWords.length < needed) {
      // if not enough pool (should not happen 80 > 30), repeat shuffle
      while (_masterWords.length < needed) {
        pool.shuffle(Random());
        for (final w in pool) {
          if (_masterWords.length >= needed) break;
          if (!_masterWords.contains(w)) _masterWords.add(w);
        }
      }
    }
  }

  void _startGame() {
    _makePairs();
    _initScores();
    _generateMasterWords();
    _currentRound = 1;
    _startRound();
  }

  void _startRound() {
    _bowl = List<String>.from(_masterWords)..shuffle(Random());
    _currentPairIndex = 0;
    _waitingForTurn = true;
    _turnActive = false;
    _currentWord = _bowl.isNotEmpty ? _bowl.first : '';
    _lastRoundGained = {};
    setState(() => _phase = _Phase.playing);
    try {
      SoundService.instance.playAmbientLoop(category: 'PALABRAS');
    } catch (_) {}
  }

  void _beginTurn() {
    if (_bowl.isEmpty) {
      _finishRound();
      return;
    }
    _currentWord = _bowl.first;
    _secondsLeft = 30;
    _waitingForTurn = false;
    _turnActive = true;
    setState(() {});
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_turnActive || _phase != _Phase.playing || _waitingForTurn) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _onTurnTimeUp();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 5 && _secondsLeft > 0) {
        SoundService.instance.playTick();
        if (_secondsLeft <= 3) SoundService.instance.vibrateShort();
      }
    });
  }

  void _onTurnTimeUp() {
    if (!_turnActive) return;
    _turnActive = false;
    _timer?.cancel();
    SoundService.instance.playFail();
    SoundService.instance.vibrateShort();
    // word not guessed stays in bowl for next pair
    _advanceToNextPair();
  }

  void _advanceToNextPair() {
    _timer?.cancel();
    _turnActive = false;
    if (_bowl.isEmpty) {
      _finishRound();
      return;
    }
    setState(() {
      _currentPairIndex = (_currentPairIndex + 1) % _pairs.length;
      _waitingForTurn = true;
    });
  }

  void _onAcierto() {
    if (!_turnActive || _waitingForTurn || _phase != _Phase.playing) return;
    if (_currentWord.isEmpty || _bowl.isEmpty) return;
    SoundService.instance.playSuccess();
    SoundService.instance.vibrateShort();
    final label = _currentPairLabel;
    setState(() {
      _pairTotal[label] = (_pairTotal[label] ?? 0) + 1;
      final rounds = _pairRounds[label]!;
      rounds[_currentRound - 1] = rounds[_currentRound - 1] + 1;
      _lastRoundGained[label] = (_lastRoundGained[label] ?? 0) + 1;
      // remove word from bowl
      _bowl.removeAt(0);
      if (_bowl.isEmpty) {
        _turnActive = false;
        _timer?.cancel();
        // round finished in middle of turn
        Future.microtask(_finishRound);
        return;
      }
      _currentWord = _bowl.first;
      // keep same timer, continue turn
    });
  }

  void _finishRound() {
    _timer?.cancel();
    _turnActive = false;
    _waitingForTurn = false;
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    // ensure all pairs have entry
    for (final p in _pairs) {
      final label = p.join(' & ');
      _pairRounds.putIfAbsent(label, () => List.filled(4, 0));
      _pairTotal.putIfAbsent(label, () => 0);
    }
    if (_currentRound >= _totalRounds) {
      setState(() => _phase = _Phase.gameOver);
      SoundService.instance.playGameOver();
    } else {
      setState(() => _phase = _Phase.roundEnd);
      SoundService.instance.playSuccess();
    }
  }

  void _nextRound() {
    setState(() => _currentRound++);
    _startRound();
  }

  void _resetGame() {
    _timer?.cancel();
    _economyAwarded = false;
    setState(() {
      _phase = _Phase.setup;
      _currentRound = 1;
      _currentPairIndex = 0;
      _waitingForTurn = true;
      _turnActive = false;
      _secondsLeft = 30;
    });
    try {
      SoundService.instance.playAmbientLoop(category: 'PALABRAS');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text('¿Salir?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderás el progreso', style: TextStyle(color: PartyColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.danger), child: const Text('Salir')),
            ],
          ),
        );
        if (shouldPop == true) {
          _timer?.cancel();
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
                emoji: '🥗',
                title: 'LA ENSALADA',
                subtitle: '4 rondas con las mismas palabras. ¡Parejas a contrarreloj!',
                steps: [
                  'Cada jugador aporta 3 palabras (la app genera ${widget.players.length * 3} palabras del bowl).',
                  'La app forma parejas aleatorias. Cada pareja tiene 30s por turno.',
                  'Si aciertas guardas la palabra y pillas otra al instante. ¡No se vale pasar!',
                  'Al acabar el turno pasa a la siguiente pareja con el tiempo restante.',
                  'Cuando se acaban las palabras acaba la ronda y se rellenan las MISMAS palabras para la siguiente.',
                  'R1 Describir (habla libre), R2 Una sola palabra, R3 Mímica, R4 Sonidos (opcional con toggle).',
                  'Gana la pareja con más puntos sumando todas las rondas.',
                ],
                onStart: _startSetup,
              );
            case _Phase.setup:
              return _buildSetup();
            case _Phase.playing:
              return _buildPlaying();
            case _Phase.roundEnd:
              return _buildRoundEnd();
            case _Phase.gameOver:
              return _buildGameOver();
          }
        },
      ),
    );
  }

  Widget _buildSetup() {
    final nWords = widget.players.length * 3;
    final previewPairs = (() {
      final tmp = List<String>.from(widget.players)..shuffle(Random(0));
      final res = <List<String>>[];
      for (int i = 0; i < tmp.length; i += 2) {
        if (i + 1 < tmp.length) {
          res.add([tmp[i], tmp[i + 1]]);
        } else {
          if (res.isNotEmpty) {
            res.last = [...res.last, tmp[i]];
          } else {
            res.add([tmp[i]]);
          }
        }
      }
      return res;
    })();
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('🥗', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('LA ENSALADA', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('$nWords palabras  •  ${widget.players.length} jugadores  •  ${_pairs.isEmpty ? previewPairs.length : _pairs.length} parejas', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: PartyColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('PAREJAS ALEATORIAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: PartyColors.textMuted)),
                    const SizedBox(height: 12),
                    ...previewPairs.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)),
                          child: Row(
                            children: [
                              const Text('👥', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(p.join('  &  '), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.text))),
                            ],
                          ),
                        )),
                    Text('Se formarán al empezar (aleatorias).', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: PartyColors.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RONDA 4: SONIDOS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.text)),
                          const SizedBox(height: 4),
                          Text('Solo sonidos, sin palabras ni mímica', style: TextStyle(fontSize: 11, color: PartyColors.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _includeR4,
                      onChanged: (v) => setState(() => _includeR4 = v),
                      activeThumbColor: PartyColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.2))),
                child: Text('Se generan $nWords palabras aleatorias del bowl (80). Cada ronda son las mismas palabras barajadas. 30s por turno, sin pasar.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.4, color: PartyColors.textSecondary)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: const Text('¡EMPEZAR!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 8),
              Text('4 rondas: Describir → Una palabra → Mímica → Sonidos${_includeR4 ? '' : ' (R4 desactivada)'}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    final isWaiting = _waitingForTurn;
    final lowTime = _secondsLeft <= 5;
    final bowlLeft = _bowl.length;
    final totalWords = _masterWords.length;
    final roundProgress = totalWords == 0 ? 0.0 : (totalWords - bowlLeft) / totalWords;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds — $_roundName', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.text, fontSize: 13))),
      body: AnimatedPartyBackground(
        totalDuration: Duration(seconds: 30 * _pairs.length * _totalRounds),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                // Round header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
                  child: Row(
                    children: [
                      Text(_roundEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RONDA $_currentRound: $_roundName', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: PartyColors.primary)),
                            Text(_roundHint, style: TextStyle(fontSize: 11, color: PartyColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)),
                        child: Text('$bowlLeft/$totalWords', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.text)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: roundProgress, backgroundColor: PartyColors.border, color: PartyColors.primary, minHeight: 6, borderRadius: BorderRadius.circular(99)),
                const SizedBox(height: 12),
                // Pair indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.28))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text('PAREJA ${(_currentPairIndex + 1).toString()}/${_pairs.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PartyColors.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_currentPairLabel.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PartyColors.text))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Center(
                    child: isWaiting ? _buildWaitingCard() : _buildTurnCard(lowTime),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPairScoresStrip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.2))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Turno de $_currentPairLabel', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text)),
          const SizedBox(height: 8),
          Text('Pasa el móvil a esta pareja.\nTendréis 30 segundos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary, height: 1.4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)),
            child: Text('RONDA $_currentRound: $_roundName  $_roundEmoji', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.primary)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _beginTurn,
              style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('¡LISTOS! 30s', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnCard(bool lowTime) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // timer
        _Pulse(
          active: lowTime,
          child: Text('$_secondsLeft s', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: lowTime ? PartyColors.danger : PartyColors.text, height: 1)),
        ),
        Text(lowTime ? '¡RÁPIDO!' : 'sin pasar — sigue hasta que acabe el tiempo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: lowTime ? PartyColors.danger : PartyColors.textMuted)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 2)),
          child: Column(
            children: [
              Text(_roundName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted)),
              const SizedBox(height: 6),
              Text(_currentWord, textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: PartyColors.primary, height: 1.1)),
              const SizedBox(height: 8),
              Text(_roundHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton.icon(
            onPressed: _onAcierto,
            icon: const Icon(Icons.check_circle, size: 24),
            label: const Text('¡ACIERTO! +1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          ),
        ),
        const SizedBox(height: 8),
        Text('Si aciertas guarda la palabra y pilla otra al instante', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
      ],
    );
  }

  Widget _buildPairScoresStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _pairs.map((p) {
            final label = p.join(' & ');
            final isCurrent = label == _currentPairLabel;
            final total = _pairTotal[label] ?? 0;
            final roundScore = _pairRounds[label]?[_currentRound - 1] ?? 0;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent ? PartyColors.primary.withValues(alpha: 0.12) : PartyColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isCurrent ? PartyColors.primary.withValues(alpha: 0.35) : PartyColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.text)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.primary)),
                  ),
                  if (roundScore > 0) ...[
                    const SizedBox(width: 4),
                    Text('(+$roundScore R$_currentRound)', style: TextStyle(fontSize: 10, color: PartyColors.textMuted)),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundEnd() {
    final sorted = _pairTotal.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(_roundEmoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text('RONDA $_currentRound COMPLETADA', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: PartyColors.primary)),
              const SizedBox(height: 6),
              Text(_roundName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.text)),
              const SizedBox(height: 4),
              Text('Mismas palabras para la siguiente ronda', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: PartyColors.border)),
                child: Column(
                  children: [
                    Text('PUNTOS ESTA RONDA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: PartyColors.textMuted)),
                    const SizedBox(height: 12),
                    ..._pairs.map((p) {
                      final label = p.join(' & ');
                      final roundPts = _pairRounds[label]?[_currentRound - 1] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)),
                        child: Row(
                          children: [
                            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PartyColors.text))),
                            Text('+$roundPts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: roundPts > 0 ? PartyColors.success : PartyColors.textMuted)),
                            const SizedBox(width: 8),
                            Text('Total ${_pairTotal[label] ?? 0}', style: TextStyle(fontSize: 11, color: PartyColors.textSecondary)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (sorted.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🥇 ', style: TextStyle(fontSize: 18)),
                      Flexible(child: Text('${sorted.first.key} va ganando con ${sorted.first.value} pts', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.text))),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextRound,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(_currentRound + 1 <= _totalRounds ? 'SIGUIENTE RONDA: ${_roundNames[_currentRound + 1]}' : 'VER RESULTADOS', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final sorted = _pairTotal.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final winner = sorted.isNotEmpty ? sorted.first.key : '';
    final winnerScore = sorted.isNotEmpty ? sorted.first.value : 0;
    final isTie = sorted.length > 1 && sorted[1].value == winnerScore;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RESULTADOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, color: PartyColors.text))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 10),
              Text(isTie ? '¡EMPATE!' : winner.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: PartyColors.text)),
              const SizedBox(height: 4),
              Text(isTie ? 'Varias parejas empatan con $winnerScore puntos' : '$winnerScore puntos en total', style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: PartyColors.border)),
                child: Column(
                  children: [
                    Text('DESGLOSE POR RONDAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: PartyColors.textMuted)),
                    const SizedBox(height: 10),
                    // header
                    Row(
                      children: [
                        const Expanded(flex: 3, child: SizedBox()),
                        for (int r = 1; r <= 4; r++)
                          Expanded(
                            child: Center(
                              child: Text('R$r', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: r <= _totalRounds ? PartyColors.primary : PartyColors.textMuted)),
                            ),
                          ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const Divider(height: 16),
                    ...sorted.map((e) {
                      final rounds = _pairRounds[e.key] ?? List.filled(4, 0);
                      final isWinner = e.key == winner && !isTie;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isWinner ? PartyColors.primary.withValues(alpha: 0.08) : PartyColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isWinner ? PartyColors.primary.withValues(alpha: 0.35) : PartyColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  if (isWinner) const Text('👑 ', style: TextStyle(fontSize: 14)),
                                  Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.text))),
                                ],
                              ),
                            ),
                            for (int r = 0; r < 4; r++)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    r < _totalRounds ? '${rounds[r]}' : '-',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: r < _totalRounds ? (rounds[r] > 0 ? PartyColors.text : PartyColors.textMuted) : PartyColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: isWinner ? Colors.amber.withValues(alpha: 0.2) : PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${e.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isWinner ? Colors.amber.shade700 : PartyColors.primary)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('${_masterWords.length} palabras  •  Mismas palabras en todas las rondas', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _resetGame,
                        style: OutlinedButton.styleFrom(side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text('REPETIR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.text)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _handleGameCompleted();
                          final map = Map<String, int>.from(_pairTotal);
                          await saveGameScores(map);
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('VOLVER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final Widget child;
  final bool active;
  const _Pulse({required this.child, this.active = true});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = 1.0 + 0.08 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
