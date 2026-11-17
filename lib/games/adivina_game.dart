// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

enum _AdivinaPhase { setup, turnIntro, countdown, playing, gameOver }

class AdivinaGame extends StatefulWidget {
  final List<String> players;
  const AdivinaGame({super.key, required this.players});

  @override
  State<AdivinaGame> createState() => _AdivinaGameState();
}

class _AdivinaGameState extends State<AdivinaGame> {
  bool _showInstructions = true;
  _AdivinaPhase _phase = _AdivinaPhase.setup;

  late List<AdivinaWord> _deck;
  int _wordCount = 10;
  Set<String> _selectedCategories = {'TODAS'};
  int _countdown = 3;
  int _currentIndex = 0;
  int _secondsLeft = 60;
  int _correct = 0;
  bool _turnActive = false;

  int _currentPlayerIndex = 0;
  late List<String> _order;
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  int _flashEpoch = 0;
  bool _flashCorrect = true;
  int _plusOneEpoch = 0;
  bool _eventCardShown = false;

  Timer? _timer;
  Timer? _countdownTimer;

  String get _actor {
    if (widget.players.isEmpty) return 'Jugador';
    return _order[_currentPlayerIndex];
  }

  int get _totalSeconds => _wordCount == 15 ? 90 : 60;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'PALABRAS'); } catch (_) {}
    _order = List.of(widget.players)..shuffle();
    _deck = _pickDeck(_wordCount);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
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

  List<AdivinaWord> _pickDeck(int count) {
    final List<AdivinaWord> pool;
    if (_selectedCategories.contains('TODAS') || _selectedCategories.isEmpty) {
      pool = GameData.adivinaCategories.values.expand((e) => e).toList();
    } else {
      pool = [];
      for (final cat in _selectedCategories) {
        pool.addAll(GameData.adivinaCategories[cat] ?? const <AdivinaWord>[]);
      }
    }
    pool.shuffle();
    return pool.take(count).toList();
  }

  void _toggleCategory(String cat) {
    setState(() {
      if (cat == 'TODAS') {
        _selectedCategories = {'TODAS'};
      } else {
        // si estaba TODAS, quitarla al seleccionar otra
        if (_selectedCategories.contains('TODAS')) {
          _selectedCategories.remove('TODAS');
        }
        if (_selectedCategories.contains(cat)) {
          _selectedCategories.remove(cat);
        } else {
          _selectedCategories.add(cat);
        }
        if (_selectedCategories.isEmpty) {
          _selectedCategories = {'TODAS'};
        }
      }
    });
  }

  List<String> get _categoryOptions {
    return ['TODAS', ...GameData.adivinaCategories.keys];
  }

  void _selectWordCount(int wordCount) {
    if (_wordCount == wordCount) return;
    setState(() => _wordCount = wordCount);
  }

  void _beginTurn() {
    setGameOrientation([DeviceOrientation.landscapeLeft]);
    // Cartas de Evento: dispara a mitad de rondas (if (round == totalRounds~/2) showEventCard())
    final totalRounds = widget.players.length;
    final round = _currentPlayerIndex + 1;
    final midRound = (totalRounds + 1) ~/ 2;
    final shouldShowEvent = !_eventCardShown &&
        (round == totalRounds ~/ 2 || round == midRound);
    setState(() {
      _deck = _pickDeck(_wordCount);
      _currentIndex = 0;
      _correct = 0;
      _secondsLeft = _totalSeconds;
      _countdown = 3;
      _phase = _AdivinaPhase.countdown;
    });
    if (shouldShowEvent) {
      _eventCardShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showEventCard(context);
      });
    }
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _phase = _AdivinaPhase.playing);
        _turnActive = true;
        try { SoundService.instance.playAmbientLoop(category: 'PALABRAS'); } catch (_) {}
        _startTimer();
      }
    });
  }

  void _checkTick(int secondsLeft) {
    if (kDebugMode) debugPrint('[Adivina] _checkTick $secondsLeft');
    if ([60, 30, 15].contains(secondsLeft) || (secondsLeft <= 10 && secondsLeft >= 0)) {
      SoundService.instance.playTick();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_turnActive || _phase != _AdivinaPhase.playing) {
        return;
      }
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
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
    if (!_turnActive) return;
    _timer?.cancel();
    final guessed = await _showTimeoutGuessedDialog();
    if (!mounted) return;
    if (guessed == true) {
      _nextWord(correct: true);
      // _nextWord already calls _endTurn if needed
      if (_turnActive) _endTurn();
      return;
    }
    _endTurn();
  }

  Future<bool?> _showTimeoutGuessedDialog() {
    final word = _deck.isNotEmpty ? _deck[_currentIndex.clamp(0, _deck.length - 1)].word : '';
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('¿Alguien la ha adivinado?', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text)),
        content: Text(word.isEmpty ? 'Se acabó el tiempo' : 'Se acabó el tiempo para «$word»', textAlign: TextAlign.center, style: TextStyle(color: PartyColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No', style: TextStyle(color: PartyColors.textSecondary, fontWeight: FontWeight.w800))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.success), child: const Text('Sí')),
        ],
      ),
    );
  }

  void _nextWord({required bool correct}) {
    if (!_turnActive) return;
    FeedbackService.selectionClick();
    if (correct) {
      SoundService.instance.playSuccess();
      SoundService.instance.vibrateSuccess();
    } else {
      SoundService.instance.playFail();
      SoundService.instance.vibrateShort();
    }
    setState(() {
      if (correct) {
        _correct++;
        _plusOneEpoch++;
      }
      _flashCorrect = correct;
      _flashEpoch++;
    });
    if (_currentIndex >= _deck.length - 1) {
      _endTurn();
      return;
    }
    setState(() => _currentIndex++);
  }

  void _onVerticalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < 0) {
      _nextWord(correct: false);
    } else if (velocity > 0) {
      _nextWord(correct: true);
    }
  }

  void _endGameEarly() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    restoreOrientation();
    if (_turnActive) {
      final name = _actor;
      _scores[name] = (_scores[name] ?? 0) + _correct;
    }
    _turnActive = false;
    setState(() => _phase = _AdivinaPhase.gameOver);
  }

  void _endTurn() {
    if (!_turnActive) return;
    _turnActive = false;
    _timer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    restoreOrientation();
    final name = _actor;
    _scores[name] = (_scores[name] ?? 0) + _correct;
    setState(() {
      if (_currentPlayerIndex >= widget.players.length - 1) {
        _phase = _AdivinaPhase.gameOver;
      } else {
        _currentPlayerIndex++;
        _phase = _AdivinaPhase.turnIntro;
      }
    });
  }

  void _resetGame() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    _turnActive = false;
    restoreOrientation();
    setState(() {
      _showInstructions = false;
      _phase = _AdivinaPhase.setup;
      _order = List.of(widget.players)..shuffle();
      _currentPlayerIndex = 0;
      _eventCardShown = false;
      _scores.clear();
      _correct = 0;
      _currentIndex = 0;
      _secondsLeft = _totalSeconds;
      _flashEpoch = 0;
      _plusOneEpoch = 0;
    });
  }

    @override
  Widget build(BuildContext context) {
    if (widget.players.length < 3) return const NeedPlayersScreen(minPlayers: 3);
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
          _countdownTimer?.cancel();
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    final Widget screen;
    if (_showInstructions) {
      screen = GameInstructions(
        emoji: '🧠',
        title: 'ADIVINA',
        subtitle: 'Ponte el móvil en la frente y adivina con pistas del grupo.',
        steps: [
          'Se juega por turnos: ¡todos los jugadores tendrán su ronda!',
          'Un jugador se pone el móvil en la frente en horizontal.',
          'Desliza abajo o toca ACIERTO: +1 punto. Arriba o PASAR: saltas palabra.',
          'Al acabar el tiempo pasa automáticamente al siguiente jugador.',
          'Gana quien más puntos tenga en la clasificación final.',
        ],
        onStart: () => setState(() => _showInstructions = false),
      );
    } else {
      screen = AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<_AdivinaPhase>(_phase),
          child: _currentScreen(),
        ),
      );
    }
    return Stack(
      children: [screen, const GameBackButton()],
    );
  
        },
      ),
    );
  }

  Widget _currentScreen() {
    switch (_phase) {
      case _AdivinaPhase.setup:
        return _buildSetup();
      case _AdivinaPhase.turnIntro:
        return _buildTurnIntro();
      case _AdivinaPhase.countdown:
        return _buildCountdown();
      case _AdivinaPhase.playing:
        return TiltZone(
          axis: Axis.horizontal,
          onTiltForward: () => _nextWord(correct: false),
          onTiltBackward: () => _nextWord(correct: true),
          enabled: _phase == _AdivinaPhase.playing,
          child: _buildPlaying(),
        ); // Tilt + deslizar/botón (fallback si no hay giroscopio)
      case _AdivinaPhase.gameOver:
        return _buildGameOver();
    }
  }

  Widget _buildSetup() {
    if (_order.isEmpty) {
      return Scaffold(backgroundColor: PartyColors.background, body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Se necesitan jugadores — añade jugadores en JUGADORES', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: PartyColors.textSecondary)))));
    }
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📱', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'ELIGE CATEGORÍA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: PartyColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final cat in _categoryOptions)
                    FilterChip(
                      label: Text(cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _selectedCategories.contains(cat)
                                ? PartyColors.onPrimary
                                : PartyColors.text,
                          )),
                      selected: _selectedCategories.contains(cat),
                      selectedColor: PartyColors.primary,
                      backgroundColor: PartyColors.surface,
                      checkmarkColor: PartyColors.onPrimary,
                      showCheckmark: true,
                      side: BorderSide(
                        color: _selectedCategories.contains(cat)
                            ? PartyColors.primary
                            : PartyColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => _toggleCategory(cat),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '¿Cuántas palabras por jugador?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Juegan ${widget.players.isEmpty ? 1 : widget.players.length} jugadores por turnos.\n10 palabras = 60 s · 15 palabras = 90 s',
                style: TextStyle(
                  fontSize: 14,
                  color: PartyColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildWordCountOption(10, '10 PALABRAS', '60 s')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildWordCountOption(15, '15 PALABRAS', '90 s')),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _phase = _AdivinaPhase.turnIntro),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'EMPEZAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCountOption(int count, String label, String timeLabel) {
    final selected = _wordCount == count;
    return Opacity(
      opacity: selected ? 1 : 0.55,
      child: ElevatedButton(
        onPressed: () => _selectWordCount(count),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? PartyColors.primary.withValues(alpha: 0.18)
              : PartyColors.surface,
          foregroundColor: selected ? PartyColors.primary : PartyColors.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? PartyColors.primary : PartyColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 12,
                color: selected ? PartyColors.primary : PartyColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIntro() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'JUGADOR ${_currentPlayerIndex + 1} DE ${widget.players.isEmpty ? 1 : widget.players.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: PartyColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('📱', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Turno de $_actor',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Ponte el móvil en la frente.\nEl grupo da pistas sin decir la palabra.',
                style: TextStyle(
                  fontSize: 14,
                  color: PartyColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PartyColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: PartyColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          '$_wordCount palabras',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: PartyColors.text,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 36, color: PartyColors.border),
                    Column(
                      children: [
                        const Text('⏱', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalSeconds segundos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: PartyColors.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _beginTurn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '¡ESTOY LISTO!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _endGameEarly,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.textMuted,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'TERMINAR JUEGO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(
          totalDuration: const Duration(seconds: 3),
          child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _actor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Colócate el móvil en la frente!',
                style: TextStyle(fontSize: 16, color: PartyColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  '$_countdown',
                  key: ValueKey<int>(_countdown),
                  style: TextStyle(
                    fontSize: 150,
                    fontWeight: FontWeight.w900,
                    color: PartyColors.primary,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'El grupo prepara las pistas…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: PartyColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildPlaying() {
    final lowTime = _secondsLeft <= 10;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(
          totalDuration: Duration(seconds: _totalSeconds),
          child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: PartyColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: PartyColors.border),
                          ),
                          child: Text(
                            _actor.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: PartyColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: PartyColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_currentIndex + 1}/${_deck.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: PartyColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '✅ $_correct',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PartyColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const TiltUnavailableBanner(),
                const SizedBox(height: 10),
                _Pulse(
                  active: lowTime,
                  min: 1,
                  max: 1.12,
                  duration: const Duration(milliseconds: 420),
                  child: Text(
                    '⏱ $_secondsLeft s',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: lowTime ? PartyColors.danger : PartyColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragEnd: _onVerticalDrag,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _swipeHint(
                                  icon: Icons.north_rounded,
                                  label: 'PASAR',
                                  color: PartyColors.warning,
                                ),
                                Expanded(child: _buildWordCard()),
                                _swipeHint(
                                  icon: Icons.south_rounded,
                                  label: 'ACIERTO',
                                  color: PartyColors.success,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_plusOneEpoch > 0)
                        Positioned(
                          top: 48,
                          child: IgnorePointer(
                            child: _PlusOnePopup(key: ValueKey<int>(_plusOneEpoch)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 62,
                          child: ElevatedButton.icon(
                            onPressed: () => _nextWord(correct: false),
                            icon: const Icon(Icons.north_rounded, size: 26),
                            label: const Text(
                              'PASAR',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PartyColors.warning,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 62,
                          child: ElevatedButton.icon(
                            onPressed: () => _nextWord(correct: true),
                            icon: const Icon(Icons.south_rounded, size: 26),
                            label: const Text(
                              'ACIERTO',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PartyColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_flashEpoch > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: _FlashOverlay(
                    key: ValueKey<int>(_flashEpoch),
                    correct: _flashCorrect,
                  ),
                ),
              ),
          ],
        ),
      )),
    );
  }

  Widget _swipeHint({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return _Pulse(
      active: true,
      min: 0.94,
      max: 1.06,
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.9, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [...previousChildren, ?currentChild],
      ),
      child: Container(
        key: ValueKey<String>('word-$_currentPlayerIndex-$_currentIndex'),
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: PartyColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25), width: 2),
          boxShadow: [
            BoxShadow(
              color: PartyColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MÓVIL EN LA FRENTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: PartyColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 160),
                child: Text(
                  _deck[_currentIndex].word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: PartyColors.primary,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final ranking = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final medals = ['🥇', '🥈', '🥉'];
    final podiumColors = [PartyColors.warning, PartyColors.textSecondary, PartyColors.purple];
    final podiumHeights = [96.0, 72.0, 56.0];

    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                '¡FIN DEL JUEGO!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 8),
              if (ranking.isNotEmpty)
                Text(
                  '🏆 ${ranking.first.key} gana con ${ranking.first.value} puntos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PartyColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              if (ranking.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (ranking.length >= 2)
                      _podiumColumn(2, ranking[1], medals[1], podiumColors[1], podiumHeights[1]),
                    if (ranking.isNotEmpty)
                      _podiumColumn(1, ranking[0], medals[0], podiumColors[0], podiumHeights[0]),
                    if (ranking.length >= 3)
                      _podiumColumn(3, ranking[2], medals[2], podiumColors[2], podiumHeights[2]),
                  ],
                ),
              const SizedBox(height: 24),
              for (var i = 3; i < ranking.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _rankingRow(i + 1, ranking[i].key, ranking[i].value),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PartyColors.primary,
                          foregroundColor: PartyColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'REPETIR',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          restoreOrientation();
                          await _handleGameCompleted();

                          await saveGameScores(_scores);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PartyColors.surface,
                          foregroundColor: PartyColors.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: PartyColors.border),
                          ),
                        ),
                        child: const Text(
                          'VOLVER',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
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

  Widget _podiumColumn(
    int place,
    MapEntry<String, int> entry,
    String medal,
    Color color,
    double height,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(medal, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              entry.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: PartyColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${entry.value} pts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PartyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
              ),
              child: Center(
                child: Text(
                  '$place',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankingRow(int place, String name, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PartyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PartyColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '$place',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: PartyColors.text,
              ),
            ),
          ),
          Text(
            '$score pts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PartyColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final Widget child;
  final bool active;
  final double min;
  final double max;
  final Duration duration;

  const _Pulse({
    required this.child,
    this.active = true,
    this.min = 1.0,
    this.max = 1.1,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
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
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = widget.min + (widget.max - widget.min) * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

class _FlashOverlay extends StatelessWidget {
  final bool correct;

  const _FlashOverlay({super.key, required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct ? PartyColors.success : PartyColors.warning;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, value, _) => ColoredBox(
        color: color.withValues(alpha: value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlusOnePopup extends StatefulWidget {
  const _PlusOnePopup({super.key});

  @override
  State<_PlusOnePopup> createState() => _PlusOnePopupState();
}

class _PlusOnePopupState extends State<_PlusOnePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

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
        final t = _controller.value;
        final dy = -70.0 * Curves.easeOut.transform(t);
        final opacity = t < 0.15 ? t / 0.15 : 1 - ((t - 0.15) / 0.85);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: PartyColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PartyColors.success, width: 2),
          boxShadow: [
            BoxShadow(
              color: PartyColors.success.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Text(
          '+1',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: PartyColors.success,
          ),
        ),
      ),
    );
  }
}