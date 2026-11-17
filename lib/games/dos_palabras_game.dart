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

enum _Phase { instructions, setup, turnIntro, countdown, playing, gameOver }

class DosPalabrasGame extends StatefulWidget {
  final List<String> players;
  const DosPalabrasGame({super.key, required this.players});

  @override
  State<DosPalabrasGame> createState() => _DosPalabrasGameState();
}

class _DosPalabrasGameState extends State<DosPalabrasGame> {
  _Phase _phase = _Phase.instructions;
  int _wordCount = 10;
  late List<String> _order;
  final Map<String, int> _scores = {};
  int _currentPlayerIndex = 0;
  List<String> _deck = [];
  String _currentWord = '';
  int _secondsLeft = 60;
  Timer? _timer;
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _economyAwarded = false;

  String get _currentPlayer => _order.isEmpty ? 'Jugador' : _order[_currentPlayerIndex];

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.players)..shuffle();
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    try { SoundService.instance.playAmbientLoop(category: 'PALABRAS'); } catch (_) {}
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
    _timer?.cancel();
    _countdownTimer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    restoreOrientation();
    super.deactivate();
  }

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  List<String> _pickDeck(int count) {
    final pool = List<String>.from(GameData.dosPalabrasWords.isNotEmpty ? GameData.dosPalabrasWords : GameData.adivinaCategories.values.expand((e) => e.map((w) => w.word)).toList());
    pool.shuffle(Random());
    return pool.take(count).toList();
  }

  void _beginTurn() {
    _deck = _pickDeck(_wordCount);
    _currentWord = _deck.isNotEmpty ? _deck.removeAt(0) : 'Palabra';
    _countdown = 3;
    setState(() => _phase = _Phase.countdown);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _phase = _Phase.playing);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _endTurn();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 10 && _secondsLeft > 0 || [60,30,15].contains(_secondsLeft)) {
        try { SoundService.instance.playTick(); } catch (_) {}
      }
    });
  }

  void _nextWord({required bool correct}) {
    if (_phase != _Phase.playing) return;
    if (correct) {
      _scores[_currentPlayer] = (_scores[_currentPlayer] ?? 0) + 1;
      try { SoundService.instance.playSuccess(); SoundService.instance.vibrateSuccess(); } catch (_) {}
    } else {
      try { SoundService.instance.playFail(); SoundService.instance.vibrateShort(); } catch (_) {}
    }
    if (_deck.isEmpty) {
      _endTurn();
      return;
    }
    setState(() {
      _currentWord = _deck.removeAt(0);
    });
  }

  void _endTurn() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    if (_currentPlayerIndex < _order.length - 1) {
      setState(() {
        _currentPlayerIndex++;
        _phase = _Phase.turnIntro;
      });
    } else {
      setState(() => _phase = _Phase.gameOver);
    }
  }

  void _onVerticalDrag(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v < 0) {
      _nextWord(correct: false);
    } else if (v > 0) {
      _nextWord(correct: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) return const NeedPlayersScreen(minPlayers: 3);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
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
          try { SoundService.instance.stopAmbient(); } catch (_) {}
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(builder: (context) {
        switch (_phase) {
          case _Phase.instructions:
            return GameInstructions(
              emoji: '💬',
              title: 'DOS PALABRAS',
              subtitle: 'Explica la palabra usando SOLO 2 palabras.',
              steps: [
                'Cada jugador tiene 60s y una lista de palabras.',
                'Para cada palabra di EXACTAMENTE 2 palabras como pista (ej. "animal jungla" para tigre).',
                'El grupo grita respuestas, tú marcas ACIERTO si aciertan o PASAR si no.',
                'No vale decir la palabra ni derivadas, solo 2 palabras.',
                'Al terminar el tiempo o las palabras, pasa al siguiente. Gana quien más acierte.',
              ],
              onStart: () => setState(() => _phase = _Phase.setup),
            );
          case _Phase.setup:
            return _buildSetup();
          case _Phase.turnIntro:
            return _buildTurnIntro();
          case _Phase.countdown:
            return _buildCountdown();
          case _Phase.playing:
            return _buildPlaying();
          case _Phase.gameOver:
            return _buildGameOver();
        }
      }),
    );
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💬', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text('¿Cuántas palabras?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PartyColors.text), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('Cada turno dura 60s. Elige la dificultad.', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _wordOption(10, '10 PALABRAS', 'Fácil')),
                const SizedBox(width: 12),
                Expanded(child: _wordOption(15, '15 PALABRAS', 'Normal')),
                const SizedBox(width: 12),
                Expanded(child: _wordOption(20, '20 PALABRAS', 'Difícil')),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () => setState(() => _phase = _Phase.turnIntro),
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('EMPEZAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordOption(int count, String label, String sub) {
    final sel = _wordCount == count;
    return Opacity(
      opacity: sel ? 1 : 0.6,
      child: ElevatedButton(
        onPressed: () => setState(() => _wordCount = count),
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? PartyColors.primary.withValues(alpha: 0.15) : PartyColors.surface,
          foregroundColor: sel ? PartyColors.primary : PartyColors.text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: sel ? PartyColors.primary : PartyColors.border)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Column(children: [
          Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          Text(sub, style: TextStyle(fontSize: 10, color: PartyColors.textMuted)),
        ]),
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
              Text('Turno de $_currentPlayer', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PartyColors.text), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Recuerda: SOLO 2 palabras por pista', style: TextStyle(fontSize: 13, color: PartyColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: _beginTurn,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('¡ESTOY LISTO!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_countdown', style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: PartyColors.primary)),
            const SizedBox(height: 12),
            Text('¡Prepara tus 2 palabras!', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(
        totalDuration: const Duration(seconds: 60),
        child: SafeArea(
          child: GestureDetector(
            onVerticalDragEnd: _onVerticalDrag,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_currentPlayer, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.text)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: _secondsLeft <= 10 ? PartyColors.danger.withValues(alpha: 0.15) : PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text('$_secondsLeft s', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('SOLO 2 PALABRAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: PartyColors.primary)),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        Text(_currentWord, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: PartyColors.text)),
                        const SizedBox(height: 8),
                        Text('Explica con 2 palabras', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('Desliza ↑ PASAR  •  ↓ ACIERTO', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: OutlinedButton(
                            onPressed: () => _nextWord(correct: false),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: Text('PASAR', style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.textSecondary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () => _nextWord(correct: true),
                            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: const Text('ACIERTO', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final winner = sorted.isNotEmpty ? sorted.first.key : '';
    final isTie = sorted.length > 1 && sorted[0].value == sorted[1].value;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(isTie ? '¡EMPATE!' : '¡$winner GANA!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PartyColors.text), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ...sorted.map((e) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: e.key == winner && !isTie ? PartyColors.primary : PartyColors.border)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text)),
                        Text('${e.value} pts', style: TextStyle(fontWeight: FontWeight.w900, color: PartyColors.primary)),
                      ],
                    ),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();
                    await saveGameScores(_scores);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('VOLVER', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
