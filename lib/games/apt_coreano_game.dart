// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/economy_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';

enum _Phase { instructions, setup, playing, gameOver }

class AptCoreanoGame extends StatefulWidget {
  final List<String> players;
  const AptCoreanoGame({super.key, required this.players});

  @override
  State<AptCoreanoGame> createState() => _AptCoreanoGameState();
}

class _AptCoreanoGameState extends State<AptCoreanoGame> {
  _Phase _phase = _Phase.instructions;
  int _secondsLeft = 90;
  int _totalSeconds = 90;
  Timer? _timer;
  int _fails = 0;
  bool _economyAwarded = false;
  final Map<String, int> _scores = {};

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  @override
  void initState() {
    super.initState();
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    try {
      SoundService.instance.playAmbientLoop(category: 'RETO');
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _phase = _Phase.playing;
      _secondsLeft = _totalSeconds;
      _fails = 0;
    });
    try {
      SoundService.instance.playAmbientLoop(category: 'RETO');
    } catch (_) {}
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _phase != _Phase.playing) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _timer?.cancel();
        _finishGame();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 10 && _secondsLeft > 0) SoundService.instance.playTick();
    });
  }

  void _onFail() {
    setState(() => _fails++);
    SoundService.instance.playFail();
    SoundService.instance.vibrateShort();
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    SoundService.instance.playGameOver();
    await _handleGameCompleted();
    await saveGameScores(_scores);
    if (!mounted) return;
    setState(() => _phase = _Phase.gameOver);
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
          _timer?.cancel();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {
          switch (_phase) {
            case _Phase.instructions:
              return GameInstructions(
                emoji: '🖐️',
                title: 'APT COREANO',
                subtitle: 'Ritmo con palmas. El que falla recibe bofetada suave.',
                steps: const [
                  'Todos en círculo, ritmo con palmas (palma-palma, sin lógica automática).',
                  'Seguid el ritmo cantando APT. El que se equivoca falla.',
                  'La app solo pone música, cronómetro y botón de fallo.',
                  'Cuando alguien falla, pulsad ¡FALLO! BOFETADA y da bofetada suave.',
                  'Sin lógica de ritmo: el grupo decide quién falla.',
                  'Jugad con timer 60s/90s/120s. ¡Pura fiesta!',
                ],
                onStart: () => setState(() => _phase = _Phase.setup),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('APT COREANO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🖐️', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('¡PREPARA EL RITMO!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Todos en círculo, palmas al ritmo APT.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 24),
              Text('DURACIÓN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
              const SizedBox(height: 12),
              for (final d in [60, 90, 120])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _totalSeconds = d),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _totalSeconds == d ? PartyColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                        foregroundColor: PartyColors.text,
                        side: BorderSide(color: _totalSeconds == d ? PartyColors.primary : PartyColors.border, width: _totalSeconds == d ? 2 : 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('$d SEGUNDOS', style: TextStyle(fontWeight: FontWeight.w800, color: _totalSeconds == d ? PartyColors.primary : PartyColors.text)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('¡EMPEZAR RITMO!', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    final low = _secondsLeft <= 10;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: const Text('APT COREANO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: AnimatedPartyBackground(
        totalDuration: Duration(seconds: _totalSeconds),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
                  child: Column(
                    children: [
                      Text('RITMO APT — PALMAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary)),
                      const SizedBox(height: 6),
                      Text('Todos en círculo. Palma - palma - APT... El que falla recibe bofetada suave (sin lógica automática).', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('$_secondsLeft s', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: low ? PartyColors.danger : PartyColors.text)),
                const SizedBox(height: 4),
                Text(low ? '¡ÚLTIMOS SEGUNDOS!' : '¡Sigue el ritmo!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: low ? PartyColors.danger : PartyColors.textMuted)),
                const SizedBox(height: 8),
                Text('Bofetadas: $_fails', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.text)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _onFail,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('¡FALLO! BOFETADA 🖐️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Pulsad cuando alguien se equivoque. El grupo decide.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _finishGame,
                    style: OutlinedButton.styleFrom(foregroundColor: PartyColors.textSecondary, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('TERMINAR RONDA', style: TextStyle(fontWeight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: const Text('RESULTADOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🖐️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('¡RITMO TERMINADO!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Total bofetadas suaves: $_fails', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              ...widget.players.map((p) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
                    child: Row(children: [Expanded(child: Text(p, style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w600))), Text('${_scores[p] ?? 0} pts', style: const TextStyle(color: PartyColors.primary, fontWeight: FontWeight.w800))]),
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
