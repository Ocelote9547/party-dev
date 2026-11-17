// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/game_data.dart';
import '../services/economy_service.dart';
import '../services/feedback_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/event_card_overlay.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';

enum _MimicaPhase { instructions, start, diceRoll, actorPreview, playing, gameOver }

const String _kNobody = '__NADIE__';

class MimicaGame extends StatefulWidget {
  final List<String> players;
  const MimicaGame({super.key, required this.players});

  @override
  State<MimicaGame> createState() => _MimicaGameState();
}

class _MimicaGameState extends State<MimicaGame> {
  static const int _maxRounds = 5;

  _MimicaPhase _phase = _MimicaPhase.instructions;

  int _currentRound = 1;
  int _currentPlayerIndex = 0;
  late List<String> _order;
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  int _diceValue = 1;
  int _totalSeconds = 30;
  List<String> _wordsForRound = [];
  int _currentWordIndex = 0;
  int _secondsLeft = 30;
  bool _roundEnded = false;
  bool _showWords = false;
  bool _eventCardShown = false;

  Timer? _timer;

  String get _actor {
    if (_order.isEmpty) return 'Jugador';
    return _order[_currentPlayerIndex];
  }

  String get _currentWord => _wordsForRound[_currentWordIndex];

  int get _guessCount => _wordsForRound.length;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'RETO'); } catch (_) {}
    _order = List.of(widget.players)..shuffle();
    for (final p in widget.players) {
      _scores[p] = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    restoreOrientation();
    super.dispose();
  }

  @override
  void deactivate() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    restoreOrientation();
    super.deactivate();
  }

  void _rollDice() {
    _roundEnded = false;
    _diceValue = 1 + math.Random().nextInt(3);
    _totalSeconds = 30 * _diceValue;
    _wordsForRound = List<String>.from(GameData.mimicaWords)
      ..shuffle();
    _wordsForRound = _wordsForRound.take(_diceValue).toList();
    _currentWordIndex = 0;
    _secondsLeft = _totalSeconds;
    setState(() => _phase = _MimicaPhase.diceRoll);
  }

  void _onDiceRevealed() {
    if (!mounted) return;
    setState(() => _phase = _MimicaPhase.actorPreview);
  }

  void _startRound() {
    setGameOrientation([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    setState(() {
      _showWords = false;
      _phase = _MimicaPhase.playing;
    });
    try { SoundService.instance.playAmbientLoop(category: 'RETO'); } catch (_) {}
    _startTimer();
    // Cartas de Evento: dispara a mitad de rondas (if (round == totalRounds~/2) showEventCard())
    final totalRounds = _maxRounds;
    final round = _currentRound;
    final midRound = (totalRounds + 1) ~/ 2;
    if (!_eventCardShown && (round == totalRounds ~/ 2 || round == midRound)) {
      final shouldShow = round == midRound;
      if (shouldShow || totalRounds.isEven) {
        _eventCardShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showEventCard(context);
        });
      }
    }
  }

  void _checkTick(int secondsLeft) {
    if (kDebugMode) debugPrint('[Mimica] _checkTick $secondsLeft');
    if ([60, 30, 15].contains(secondsLeft) || (secondsLeft <= 10 && secondsLeft >= 0)) {
      SoundService.instance.playTick();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _phase != _MimicaPhase.playing) return;
      if (_secondsLeft <= 1) {
        FeedbackService.countdownTick(0);
        _checkTick(0);
        _handleTimeout();
        return;
      }
      setState(() => _secondsLeft--);
      FeedbackService.countdownTick(_secondsLeft);
      _checkTick(_secondsLeft);
    });
  }

  Future<void> _handleTimeout() async {
    if (_roundEnded) return;
    _timer?.cancel();
    setState(() => _secondsLeft = 0);
    final guessed = await _showTimeoutGuessedDialog();
    if (!mounted) return;
    if (guessed == true) {
      await _onCorrectWord();
      if (!_roundEnded) _endRound();
      return;
    }
    _endRound();
  }

  Future<bool?> _showTimeoutGuessedDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('¿Alguien la ha adivinado?', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text)),
        content: Text('Se acabó el tiempo para «$_currentWord»', textAlign: TextAlign.center, style: TextStyle(color: PartyColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No', style: TextStyle(color: PartyColors.textSecondary, fontWeight: FontWeight.w800))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.success), child: const Text('Sí')),
        ],
      ),
    );
  }

  Future<void> _onCorrectWord() async {
    FeedbackService.selectionClick();
    SoundService.instance.playSuccess();
    SoundService.instance.vibrateSuccess();
    final winner = await _showWhoGuessedDialog();
    if (winner == null || !mounted) return;
    if (_roundEnded) {
      if (winner != _kNobody) {
        setState(() => _scores[winner] = (_scores[winner] ?? 0) + 1);
      }
      return;
    }
    setState(() {
      if (winner != _kNobody) {
        _scores[winner] = (_scores[winner] ?? 0) + 1;
      }
      _currentWordIndex++;
    });
    if (_currentWordIndex >= _wordsForRound.length) {
      _endRound();
    }
  }

  void _endRound() {
    if (_roundEnded) return;
    _roundEnded = true;
    _timer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    setState(() {
      _currentPlayerIndex++;
      if (_currentPlayerIndex >= _order.length) {
        _currentPlayerIndex = 0;
        _currentRound++;
        if (_currentRound > _maxRounds) {
          _phase = _MimicaPhase.gameOver;
          restoreOrientation();
          return;
        }
        _order = List.of(widget.players)..shuffle();
      }
      _phase = _MimicaPhase.start;
    });
  }

  Future<String?> _showWhoGuessedDialog() {
    final options = widget.players.where((p) => p != _actor).toList();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: PartyColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😃', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text(
                '¿Quién adivinó la palabra?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                '«$_currentWord»',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.textSecondary),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  for (final p in options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: PartyColors.border),
                        ),
                        tileColor: PartyColors.background,
                        title: Text(p, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.text)),
                        onTap: () => Navigator.pop(ctx, p),
                      ),
                    ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: PartyColors.border),
                    ),
                    tileColor: PartyColors.background,
                    title: Text('NADIE', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.textMuted)),
                    trailing: Icon(Icons.person_off_outlined, size: 20, color: PartyColors.textSecondary),
                    onTap: () => Navigator.pop(ctx, _kNobody),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          _timer?.cancel();
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    switch (_phase) {
      case _MimicaPhase.instructions:
        return _buildInstructions();
      case _MimicaPhase.start:
        return _buildStart();
      case _MimicaPhase.diceRoll:
        return _buildDiceRoll();
      case _MimicaPhase.actorPreview:
        return _buildActorPreview();
      case _MimicaPhase.playing:
        return _buildPlaying();
      case _MimicaPhase.gameOver:
        return _buildGameOver();
    }
  
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return GameInstructions(
      emoji: '🎭',
      title: 'MÍMICA',
      subtitle: 'Haz gestos sin hablar y deja que el grupo adivine.',
      steps: [
        '5 rondas. En cada ronda todos actúan una vez, por turnos.',
        'El actor tira el dado: sale 1, 2 o 3 palabras.',
        'Solo el actor mira el móvil, el grupo NO ve la palabra.',
        'El actor hace mímica sin hablar/sonidos y el grupo grita la respuesta.',
        'Pulsa ACIERTO cuando acierten y elige quién adivinó.',
        '30s por palabra → 30, 60 o 90 segundos en total.',
        'Punto = quien ADIVINA la palabra (+1). El actor no suma. NADIE = 0 puntos.',
        'Gana quien más palabras adivine en las 5 rondas.',
      ],
      onStart: () => setState(() => _phase = _MimicaPhase.start),
    );
  }

  Widget _buildStart() {
    if (_order.isEmpty) {
      return Scaffold(backgroundColor: PartyColors.background, body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Se necesitan jugadores — añade jugadores en JUGADORES', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: PartyColors.textSecondary)))));
    }
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MÍMICA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤐', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'Turno de $_actor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: PartyColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                'Ronda $_currentRound/$_maxRounds',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 22),
              _ScoreRow(players: widget.players, scores: _scores, compact: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _rollDice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.casino_outlined, size: 26),
                  label: const Text('TIRAR DADO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiceRoll() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MÍMICA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Turno de $_actor', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 28),
              _DiceRollWidget(result: _diceValue, onRevealed: _onDiceRevealed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActorPreview() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MÍMICA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 24, 28, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DiceFace(value: _diceValue, highlighted: true, size: 104),
              const SizedBox(height: 16),
              Text(
                '$_guessCount ${_guessCount == 1 ? 'palabra' : 'palabras'} · $_totalSeconds segundos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PartyColors.text),
              ),
              const SizedBox(height: 4),
              Text('Turno de $_actor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.textSecondary)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PartyColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PartyColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 8),
                    Text(
                      'MEMORIZA TUS PALABRAS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < _wordsForRound.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: PartyColors.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _wordsForRound[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: PartyColors.text),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Listo, $_actor? Solo el actor mira el móvil.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _startRound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('EMPEZAR RONDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    final timerColor = _secondsLeft <= 10
        ? PartyColors.danger
        : _secondsLeft <= 30
            ? PartyColors.warning
            : PartyColors.primary;

    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(
          totalDuration: Duration(seconds: _totalSeconds),
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: PartyColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'PALABRA ${_currentWordIndex + 1}/${_wordsForRound.length}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.primary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Turno: $_actor · Ronda $_currentRound/$_maxRounds',
                    style: TextStyle(color: PartyColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_wordsForRound.length, (i) {
                  final done = i < _currentWordIndex;
                  final current = i == _currentWordIndex;
                  return Container(
                    width: current ? 28 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: done
                          ? PartyColors.success
                          : current
                              ? PartyColors.primary
                              : PartyColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showWords)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Container(
                            key: ValueKey('word_$_currentWordIndex'),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            decoration: BoxDecoration(
                              color: PartyColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Text(
                              _currentWord,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: PartyColors.text),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            color: PartyColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: PartyColors.border, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text('🙈', style: TextStyle(fontSize: 42)),
                              const SizedBox(height: 8),
                              Text(
                                'MÓVIL SOLO PARA EL ACTOR',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1, color: PartyColors.text),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Que el grupo NO mire',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: PartyColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _showWords = !_showWords),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showWords ? PartyColors.surface : PartyColors.primary,
                            foregroundColor: _showWords ? PartyColors.text : PartyColors.onPrimary,
                            side: _showWords ? BorderSide(color: PartyColors.border) : BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(_showWords ? Icons.visibility_off : Icons.visibility, size: 18),
                          label: Text(_showWords ? '🙈 OCULTAR' : '👁️ VER PALABRAS', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: _TimerPulse(
                    active: _secondsLeft <= 10,
                    child: Text(
                      '$_secondsLeft',
                      style: TextStyle(fontSize: 118, height: 1, fontWeight: FontWeight.w900, color: timerColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _ScoreRow(players: widget.players, scores: _scores),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton.icon(
                        onPressed: _onCorrectWord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PartyColors.success,
                          foregroundColor: PartyColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: const Icon(Icons.check_circle, size: 26),
                        label: const Text('PALABRA ACERTADA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: OutlinedButton(
                        onPressed: _endRound,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PartyColors.textSecondary,
                          side: BorderSide(color: PartyColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          _currentWordIndex >= _wordsForRound.length - 1 ? 'TERMINAR RONDA' : 'SALTEAR →',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildGameOver() {
    final sorted = widget.players.toList()..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    final champion = sorted.isNotEmpty ? sorted.first : null;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                champion == null ? 'MÍMICA TERMINADA' : '¡$champion gana!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PartyColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                'Quien más palabras adivinó gana',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 22),
              ...sorted.asMap().entries.map((entry) {
                final isChampion = entry.key == 0 && sorted.length > 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isChampion ? PartyColors.primary : PartyColors.border,
                        width: isChampion ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: PartyColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: isChampion ? 17 : 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: PartyColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_scores[entry.value] ?? 0} pts',
                            style: const TextStyle(color: PartyColors.primary, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    restoreOrientation();
                    await _handleGameCompleted();

                    await saveGameScores(_scores);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  restoreOrientation();
                  Navigator.pop(context);
                },
                child: Text('SALIR DEL JUEGO', style: TextStyle(fontSize: 13, color: PartyColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact scores strip used during the match.
class _ScoreRow extends StatelessWidget {
  final List<String> players;
  final Map<String, int> scores;
  final bool compact;

  const _ScoreRow({required this.players, required this.scores, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: players.map((p) {
        final value = scores[p] ?? 0;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 5 : 6),
          decoration: BoxDecoration(
            color: PartyColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: PartyColors.border),
          ),
          child: Text(
            '$p $value',
            style: TextStyle(
              fontSize: compact ? 12 : 12,
              fontWeight: FontWeight.w800,
              color: value >= 1 ? PartyColors.primary : PartyColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Animated dice: rolls the faces 1–3 for ~1.1s, then settles on [result]
/// and notifies via [onRevealed].
class _DiceRollWidget extends StatefulWidget {
  final int result;
  final VoidCallback onRevealed;

  const _DiceRollWidget({required this.result, required this.onRevealed});

  @override
  State<_DiceRollWidget> createState() => _DiceRollWidgetState();
}

class _DiceRollWidgetState extends State<_DiceRollWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _revealed = false;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_revealed) {
        setState(() => _revealed = true);
        _finishTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) widget.onRevealed();
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_revealed) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final face = (t * 16).floor() % 3 + 1;
          return Transform.rotate(
            angle: math.sin(t * math.pi * 9) * 0.28,
            child: Transform.scale(
              scale: 1 + math.sin(t * math.pi * 7).abs() * 0.25,
              child: _DiceFace(value: face),
            ),
          );
        },
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DiceFace(value: widget.result, highlighted: true),
          const SizedBox(height: 18),
          Text(
            '¡Salió un ${widget.result}!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PartyColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            '${math.min(widget.result, 3)} ${widget.result == 1 ? 'palabra' : 'palabras'} · ${30 * widget.result} segundos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A rendered die face with pips, supporting values 1–3.
class _DiceFace extends StatelessWidget {
  final int value;
  final bool highlighted;
  final double size;

  const _DiceFace({required this.value, this.highlighted = false, this.size = 132});

  @override
  Widget build(BuildContext context) {
    final pips = _pipPositions(value);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: highlighted ? PartyColors.primaryLight : PartyColors.surface,
        borderRadius: BorderRadius.circular(size * 0.17),
        border: Border.all(color: PartyColors.primary, width: highlighted ? 4 : 3),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: PartyColors.primary.withValues(alpha: 0.4),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          for (final f in pips)
            Positioned(
              left: f.dx * size - size * 0.09,
              top: f.dy * size - size * 0.09,
              child: Container(
                width: size * 0.18,
                height: size * 0.18,
                decoration: BoxDecoration(
                  color: PartyColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static List<Offset> _pipPositions(int value) {
    const pos = [
      0.50, 0.50, // 1 -> center
      0.30, 0.30, // 2 -> top-left
      0.70, 0.70, // 3 -> bottom-right
    ];
    return [
      for (int i = 0; i < value; i++)
        Offset(pos[i * 2], pos[i * 2 + 1]),
    ];
  }
}

/// Gently pulsates (scales) its child while [active] is true — used for the
/// timer under 10 seconds.
class _TimerPulse extends StatefulWidget {
  final bool active;
  final Widget child;

  const _TimerPulse({required this.active, required this.child});

  @override
  State<_TimerPulse> createState() => _TimerPulseState();
}

class _TimerPulseState extends State<_TimerPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TimerPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final s = 1 + 0.1 * Curves.easeOut.transform(_controller.value);
        return Transform.scale(scale: s, child: child);
      },
      child: widget.child,
    );
  }
}