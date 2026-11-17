// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/feedback_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';

enum _Phase { instructions, setup, turnIntro, countdown, playing, gameOver }

class EsUn10Game extends StatefulWidget {
  final List<String> players;

  const EsUn10Game({super.key, required this.players});

  @override
  State<EsUn10Game> createState() => _EsUn10GameState();
}

class _EsUn10GameState extends State<EsUn10Game> {
  static const List<int> _roundOptions = [5, 7, 10];
  static const List<String> _medals = ['🥇', '🥈', '🥉'];

  _Phase _phase = _Phase.instructions;
  int _selectedRounds = 5;
  int _round = 1;

  int _countdown = 3;
  int _currentNumber = 1;
  bool _isHeart = true; // true=♥, false=♦  (renderizado con Icons para evitar Noto missing)
  String get _currentSuit => _isHeart ? '♥' : '♦';
  int _acertadosEsteTurno = 0;
  int _currentPlayerIndex = 0;

  bool _showPlusOne = false;
  int _plusOneCount = 0;

  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  late List<String> _order;

  Timer? _countdownTimer;

  String get _currentPlayer =>
      _order.isEmpty ? 'Jugador' : _order[_currentPlayerIndex];

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'RETO'); } catch (_) {}
    _round = 1;
    _order = List.of(widget.players)..shuffle();
    for (final player in widget.players) {
      _scores[player] = 0;
    }
  }

  @override
  void dispose() {
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

  void _selectRounds(int rounds) {
    if (_selectedRounds == rounds) return;
    setState(() => _selectedRounds = rounds);
  }

  void _beginFirstTurn() {
    setState(() {
      _round = 1;
      _currentPlayerIndex = 0;
      _phase = _Phase.turnIntro;
    });
  }

  void _startCountdown() {
    setGameOrientation([DeviceOrientation.portraitUp]);
    setState(() {
      _phase = _Phase.countdown;
      _countdown = 3;
      _currentNumber = 1 + Random().nextInt(10);
      _isHeart = Random().nextBool();
      _acertadosEsteTurno = 0;
      _showPlusOne = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _phase = _Phase.playing);
        try { SoundService.instance.playAmbientLoop(category: 'RETO'); } catch (_) {}
      }
    });
  }

  void _nextNumber({required bool correct}) {
    if (_phase != _Phase.playing) return;
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
        _acertadosEsteTurno = 1;
        _showPlusOne = true;
        _plusOneCount++;
      }
    });
    _finishTurn();
  }

  void _hidePlusOne() {
    if (!mounted || !_showPlusOne) return;
    setState(() => _showPlusOne = false);
  }

  void _endGameEarly() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    restoreOrientation();
    setState(() => _phase = _Phase.gameOver);
  }

  void _finishTurn() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    _scores[_currentPlayer] =
        (_scores[_currentPlayer] ?? 0) + _acertadosEsteTurno;
    restoreOrientation();
    if (_currentPlayerIndex < _order.length - 1) {
      setState(() {
        _currentPlayerIndex++;
        _phase = _Phase.turnIntro;
      });
    } else {
      _round++;
      if (_round > _selectedRounds) {
        setState(() => _phase = _Phase.gameOver);
      } else {
        setState(() {
          _order = List.of(widget.players)..shuffle();
          _currentPlayerIndex = 0;
          _phase = _Phase.turnIntro;
        });
      }
    }
  }

  void _onVerticalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < 0) {
      _nextNumber(correct: false);
    } else if (velocity > 0) {
      _nextNumber(correct: true);
    }
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
          _countdownTimer?.cancel();
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    final Widget screen;
    switch (_phase) {
      case _Phase.instructions:
        screen = GameInstructions(
          emoji: '🔟',
          title: 'ES UN 10 PERO...',
          subtitle:
              'Ponte el móvil en la frente y adivina el número oculto con las pistas del grupo.',
          steps: [
            'Elegid cuántas rondas jugaréis (5, 7 o 10). En cada ronda TODOS reciben un número secreto en su turno y lo adivinan o pasan.',
            'En su turno, el jugador se pone el móvil en la frente en vertical y pulsa EMPEZAR.',
            'El grupo da pistas con frases tipo "Es un 10 pero..." que mencionen el número (sin decirlo).',
            'Desliza abajo o toca ACIERTO: +1 punto. Arriba o PASAR: 0 puntos.',
            'Juegan todos por turnos en cada ronda: gana quien más aciertos tenga al final.',
          ],
          onStart: () => setState(() => _phase = _Phase.setup),
        );
      case _Phase.setup:
        screen = _buildSetup();
        break;
      case _Phase.turnIntro:
        screen = _buildTurnIntro();
        break;
      case _Phase.countdown:
        screen = _buildCountdown();
        break;
      case _Phase.playing:
        screen = TiltZone(
          axis: Axis.vertical,
          onTiltForward: () => _nextNumber(correct: false),
          onTiltBackward: () => _nextNumber(correct: true),
          enabled: _phase == _Phase.playing,
          child: _buildGameScreen(),
        ); // Tilt + deslizar/botón
        break;
      case _Phase.gameOver:
        screen = _buildGameOver();
        break;
    }
    return Stack(
      children: [screen, const GameBackButton()],
    );
  
        },
      ),
    );
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔟', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text('ES UN 10 PERO...',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: PartyColors.text),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('¿Cuántas rondas?',
                  style: TextStyle(
                      fontSize: 14, color: PartyColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Row(
                children: [
                  for (var i = 0; i < _roundOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: _buildRoundChip(_roundOptions[i])),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text('${widget.players.length} jugadores por turnos · sin límite de tiempo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PartyColors.textSecondary)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _beginFirstTurn,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: const Text('EMPEZAR',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundChip(int rounds) {
    final selected = _selectedRounds == rounds;
    return Opacity(
      opacity: selected ? 1 : 0.55,
      child: ElevatedButton(
        onPressed: () => _selectRounds(rounds),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? PartyColors.primary.withValues(alpha: 0.18)
              : PartyColors.surface,
          foregroundColor: selected ? PartyColors.primary : PartyColors.text,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: selected ? PartyColors.primary : PartyColors.border,
                  width: selected ? 1.5 : 1)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Column(
          children: [
            Text('$rounds',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('rondas',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: selected
                        ? PartyColors.primary
                        : PartyColors.textMuted)),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📱', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text('Ronda $_round/$_selectedRounds',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: PartyColors.primary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('Turno de $_currentPlayer',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: PartyColors.text),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('Ponte el móvil en la frente con la pantalla hacia el grupo.',
                  style: TextStyle(
                      fontSize: 14, color: PartyColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PartyColors.border)),
                child: Text('1 número · sin tiempo',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.primary)),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _startCountdown,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: const Text('EMPEZAR',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _endGameEarly,
                style:
                    TextButton.styleFrom(foregroundColor: PartyColors.textMuted),
                child: const Text('TERMINAR JUEGO',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
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
      body: AnimatedPartyBackground(child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_currentPlayer,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: PartyColors.primary)),
              const SizedBox(height: 8),
              Text('¡Colócate el móvil en la frente!',
                  style: TextStyle(
                      fontSize: 16, color: PartyColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                      parent: animation, curve: Curves.easeOutBack),
                  child:
                      FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  '$_countdown',
                  key: ValueKey<int>(_countdown),
                  style: TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.w900,
                      color: PartyColors.primary,
                      height: 1),
                ),
              ),
              const SizedBox(height: 32),
              Text('El grupo prepara las pistas…',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: PartyColors.textMuted)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color:
                            PartyColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14)),
                    child: Text('RONDA $_round/$_selectedRounds',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: PartyColors.primary)),
                  ),
                  Text('✅ $_acertadosEsteTurno',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PartyColors.success)),
                ],
              ),
            ),
            const TiltUnavailableBanner(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: _onVerticalDrag,
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration:
                                  const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero)
                                    .animate(animation),
                                child: FadeTransition(
                                    opacity: animation, child: child),
                              ),
                              child: AspectRatio(
                                key: ValueKey<String>(
                                    '${_currentNumber}_$_currentSuit'),
                                aspectRatio: 2.5 / 3.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFE0E0E0),
                                          width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.18),
                                            blurRadius: 18,
                                            offset:
                                                const Offset(0, 10)),
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset:
                                                const Offset(0, 2)),
                                      ]),
                                  child: Stack(
                                    children: [
                                      // Esquina superior izquierda
                                      Positioned(
                                        top: 10,
                                        left: 12,
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Text('$_currentNumber',
                                                style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                    color: Colors.black,
                                                    height: 1)),
                                            const SizedBox(height: 2),
                                            Icon(_isHeart ? Icons.favorite : Icons.diamond,
                                                size: 18, color: Color(0xFFD32F2F)),
                                          ],
                                        ),
                                      ),
                                      // Esquina inferior derecha rotada
                                      Positioned(
                                        bottom: 10,
                                        right: 12,
                                        child: Transform.rotate(
                                          angle: 3.1415926535,
                                          child: Column(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Text('$_currentNumber',
                                                  style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight
                                                              .w900,
                                                      color:
                                                          Colors.black,
                                                      height: 1)),
                                              const SizedBox(height: 2),
                                              Icon(_isHeart ? Icons.favorite : Icons.diamond,
                                                  size: 18, color: Color(0xFFD32F2F)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Centro carta
                                      Center(
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Text('$_currentNumber',
                                                textAlign:
                                                    TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 96,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                    color: Colors.black,
                                                    height: 1)),
                                            const SizedBox(height: 6),
                                            Icon(_isHeart ? Icons.favorite : Icons.diamond,
                                                size: 52, color: Color(0xFFD32F2F)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('↑ PASAR / ↓ ACIERTO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color:
                                        PartyColors.textSecondary)),
                            const SizedBox(height: 6),
                            Text(
                                '↑ Desliza arriba o PASAR para saltar\n↓ Desliza abajo o ACIERTO si lo sabes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        PartyColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                    if (_showPlusOne)
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey<int>(_plusOneCount),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                const Duration(milliseconds: 700),
                            onEnd: _hidePlusOne,
                            builder: (context, t, child) => Opacity(
                              opacity: 1 - t,
                              child: Transform.translate(
                                  offset: Offset(0, -60 * t),
                                  child: child),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                  color: PartyColors.success,
                                  borderRadius:
                                      BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                        color: PartyColors.success
                                            .withValues(alpha: 0.35),
                                        blurRadius: 16)
                                  ]),
                              child: const Text('+1',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _nextNumber(correct: false),
                        icon: const Icon(Icons.north_rounded,
                            size: 26),
                        label: const Text('PASAR',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: PartyColors.warning,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _nextNumber(correct: true),
                        icon: const Icon(Icons.south_rounded,
                            size: 26),
                        label: const Text('ACIERTO',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: PartyColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildGameOver() {
    final sorted = widget.players.toList()
      ..sort((a, b) =>
          (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 18),
                Text('RESULTADOS',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: PartyColors.text),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                    '${widget.players.length} jugadores · $_selectedRounds rondas',
                    style: TextStyle(
                        fontSize: 13,
                        color: PartyColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                _buildPodium(sorted),
                const SizedBox(height: 24),
                ..._buildRankingRows(sorted),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _handleGameCompleted();

                      await saveGameScores(_scores);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18))),
                    child: const Text('VOLVER',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<String> sorted) {
    if (sorted.isEmpty) return const SizedBox.shrink();
    final heights = [104.0, 76.0, 58.0];
    final podium = sorted.take(3).toList();
    final indices = podium.length == 3
        ? [1, 0, 2]
        : podium.length == 2
            ? [1, 0]
            : [0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final i in indices)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: i == indices.first ? 0 : 8,
                  right: i == indices.last ? 0 : 8),
              child:
                  _buildPodiumColumn(podium[i], i, heights[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildPodiumColumn(String player, int rank, double height) {
    final score = _scores[player] ?? 0;
    final isFirst = rank == 0;
    return Column(
      children: [
        Text(_medals[rank],
            style: TextStyle(fontSize: isFirst ? 40 : 30)),
        const SizedBox(height: 6),
        Text(player,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: PartyColors.text)),
        const SizedBox(height: 6),
        Container(
          height: height,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: isFirst
                ? PartyColors.primary.withValues(alpha: 0.18)
                : PartyColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
                color: isFirst
                    ? PartyColors.primary
                    : PartyColors.border,
                width: isFirst ? 2 : 1),
          ),
          child: Text('$score',
              style: TextStyle(
                  fontSize: isFirst ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: isFirst
                      ? PartyColors.primary
                      : PartyColors.textSecondary)),
        ),
      ],
    );
  }

  List<Widget> _buildRankingRows(List<String> sorted) {
    return List.generate(sorted.length, (i) {
      final player = sorted[i];
      final isWinner = i == 0 &&
          (sorted.length > 1 || (_scores[player] ?? 0) > 0);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isWinner
              ? PartyColors.primary.withValues(alpha: 0.08)
              : PartyColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isWinner
                  ? PartyColors.primary.withValues(alpha: 0.4)
                  : PartyColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(i < 3 ? _medals[i] : '${i + 1}.',
                  style: TextStyle(
                      fontSize: i < 3 ? 18 : 15,
                      fontWeight: FontWeight.w800,
                      color: PartyColors.textSecondary)),
            ),
            Expanded(
                child: Text(player,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PartyColors.text),
                    overflow: TextOverflow.ellipsis)),
            Text('${_scores[player] ?? 0}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: PartyColors.primary)),
          ],
        ),
      );
    });
  }
}