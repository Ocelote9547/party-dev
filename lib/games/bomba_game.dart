// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/event_card_overlay.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';

enum _Phase { instructions, setup, playing, gameOver }

class BombaGame extends StatefulWidget {
  final List<String> players;
  const BombaGame({super.key, required this.players});

  @override
  State<BombaGame> createState() => _BombaGameState();
}

class _BombaGameState extends State<BombaGame> {
  _Phase _phase = _Phase.instructions;

  int _totalRounds = 3;
  int _currentRound = 1;
  String _currentSilaba = '';
  int _secondsLeft = 15;
  int _currentPlayerIndex = 0;
  late List<String> _order;

  final Map<String, int> _scores = {};
  final List<_BombaRoundResult> _results = [];
  Timer? _timer;
  bool _exploded = false;
  bool _economyAwarded = false;
  bool _eventCardShown = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'PALABRAS'); } catch (_) {}
    _order = List.from(widget.players)..shuffle();
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

  void _startGame() {
    setState(() => _phase = _Phase.setup);
  }

  void _selectRounds(int rounds) {
    _eventCardShown = false;
    setState(() {
      _totalRounds = rounds;
      _startRound();
    });
  }

  void _startRound() {
    _currentSilaba = GameData.randomFrom(GameData.bombaSilabas);
    // random start player each round for variety
    if (_currentRound > 1) {
      _order.shuffle();
      _currentPlayerIndex = safeRandomIndex(_order.length);
    }
    _secondsLeft = 15;
    _exploded = false;
    setState(() => _phase = _Phase.playing);
    try { SoundService.instance.playAmbientLoop(category: 'PALABRAS'); } catch (_) {}
    _startTimer();
    // Cartas de Evento: dispara a mitad de rondas (if (round == totalRounds~/2) showEventCard())
    // Usa SoundService.playSuccess() dentro de showEventCard con animación scale.
    final midRound = (_totalRounds + 1) ~/ 2;
    // Mantiene compatibilidad con spec literal totalRounds~/2
    if (!_eventCardShown && (_currentRound == midRound || _currentRound == _totalRounds ~/ 2)) {
      // Solo dispara una vez y a mitad real; para impares prioriza midRound.
      final shouldShow = _currentRound == midRound;
      if (shouldShow) {
        _eventCardShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showEventCard(context);
        });
      } else if (_totalRounds.isEven) {
        _eventCardShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showEventCard(context);
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _phase != _Phase.playing || _exploded) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _onExplode();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 5 && _secondsLeft > 0) {
        SoundService.instance.playTick();
        // slight vibration for urgency
        if (_secondsLeft <= 3) SoundService.instance.vibrateShort();
      }
    });
  }

  void _onExplode() {
    if (_exploded) return;
    _exploded = true;
    _timer?.cancel();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    SoundService.instance.playGameOver();
    SoundService.instance.vibrateSuccess();
    final explodedPlayer = _order[_currentPlayerIndex];
    // scoring: everyone except exploded gets +1
    setState(() {
      for (final p in _order) {
        if (p != explodedPlayer) {
          _scores[p] = (_scores[p] ?? 0) + 1;
        }
      }
    });
    _results.add(_BombaRoundResult(
      round: _currentRound,
      silaba: _currentSilaba,
      explodedPlayer: explodedPlayer,
    ));
    _showExplosionDialog(explodedPlayer);
  }

  void _showExplosionDialog(String exploded) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text('¡BOOM!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PartyColors.danger)),
            const SizedBox(height: 8),
            Text('$exploded ha explotado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.text)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
              child: Text('Sílaba: $_currentSilaba', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary)),
            ),
            const SizedBox(height: 12),
            Text('El resto +1 punto', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (_currentRound < _totalRounds) {
                    setState(() => _currentRound++);
                    _startRound();
                  } else {
                    try { SoundService.instance.stopAmbient(); } catch (_) {}
                    setState(() => _phase = _Phase.gameOver);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(_currentRound < _totalRounds ? 'SIGUIENTE RONDA' : 'VER RANKING', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPalabraDicha() {
    if (_phase != _Phase.playing || _exploded) return;
    SoundService.instance.playSuccess();
    SoundService.instance.vibrateShort();
    // pass to next player in order (cyclic next)
    setState(() {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _order.length;
      _secondsLeft = 15;
    });
    // restart timer for next turn (keep interval)
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
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {
          switch (_phase) {
            case _Phase.instructions:
              return GameInstructions(
                emoji: '💣',
                title: 'BOMBA',
                subtitle: 'Di una palabra con la sílaba antes de que la bomba explote.',
                steps: [
                  'Elige cuántas rondas (3/5/7). Cada ronda una sílaba distinta.',
                  'La bomba pasa de jugador en jugador con 15s por turno.',
                  'Di una palabra que contenga la sílaba y pulsa "¡HECHO!" para pasar la bomba.',
                  'El grupo decide si la palabra vale (no hay diccionario).',
                  'Si el temporizador llega a 0, ¡BOOM! Explota: el jugador actual no puntúa, el resto +1.',
                  'La sílaba se mantiene toda la ronda. Gana quien más puntos tenga al final.',
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
                const Text('💣', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('¿CUÁNTAS RONDAS?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
                const SizedBox(height: 8),
                Text('Cada ronda una bomba con sílaba distinta', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                const SizedBox(height: 32),
                for (final c in [3, 5, 7])
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
    final currentPlayer = _order[_currentPlayerIndex];
    final lowTime = _secondsLeft <= 5;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_currentRound/$_totalRounds — BOMBA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.text, fontSize: 14))),
      body: AnimatedPartyBackground(
        totalDuration: Duration(seconds: 15 * _totalRounds),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
                  child: Text(currentPlayer.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1, color: PartyColors.primary)),
                ),
                const SizedBox(height: 10),
                Text('tiene la bomba', style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
                  child: Column(
                    children: [
                      Text('SÍLABA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted)),
                      const SizedBox(height: 6),
                      Text(_currentSilaba, style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 4, color: PartyColors.primary)),
                      const SizedBox(height: 4),
                      Text('di una palabra que la contenga', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Pulse(
                  active: lowTime,
                  child: Text('$_secondsLeft s', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: lowTime ? PartyColors.danger : PartyColors.text)),
                ),
                const SizedBox(height: 6),
                Text(lowTime ? '¡RÁPIDO!' : 'la bomba está caliente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: lowTime ? PartyColors.danger : PartyColors.textMuted)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: _onPalabraDicha,
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: const Text('¡HECHO! — PALABRA DICHA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ),
                const SizedBox(height: 12),
                Text('El grupo decide si vale. Si no vale, no pulses y sigue el timer.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Puntos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _order.map((p) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: p == currentPlayer ? PartyColors.danger.withValues(alpha: 0.12) : PartyColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: p == currentPlayer ? PartyColors.danger.withValues(alpha: 0.3) : PartyColors.border),
                                ),
                                child: Text('$p: ${_scores[p] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.text)),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
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
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                  child: Row(
                    children: [
                      Text('R${r.round}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.textMuted)),
                      const SizedBox(width: 10),
                      Text(r.silaba, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                      const Spacer(),
                      const Text('💥 ', style: TextStyle(fontSize: 12)),
                      Text(r.explodedPlayer, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.text)),
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

class _BombaRoundResult {
  final int round;
  final String silaba;
  final String explodedPlayer;
  const _BombaRoundResult({required this.round, required this.silaba, required this.explodedPlayer});
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
