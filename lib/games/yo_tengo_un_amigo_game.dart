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

class YoTengoUnAmigoGame extends StatefulWidget {
  final List<String> players;
  const YoTengoUnAmigoGame({super.key, required this.players});

  @override
  State<YoTengoUnAmigoGame> createState() => _YoTengoUnAmigoGameState();
}

class _YoTengoUnAmigoGameState extends State<YoTengoUnAmigoGame> {
  _Phase _phase = _Phase.instructions;

  List<String> _teamA = [];
  List<String> _teamB = [];
  int _playingStep = 0; // 0 piensa 60s, 1 pregunta, 2 votacion
  int _secondsLeft = 60;
  Timer? _timer;
  bool _economyAwarded = false;
  final Map<String, int> _scores = {};
  final Set<String> _voted = {};

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
      SoundService.instance.playAmbientLoop(category: 'GRUPO');
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

  void _formTeams() {
    final shuffled = List<String>.from(widget.players)..shuffle();
    final mid = (shuffled.length / 2).ceil();
    setState(() {
      _teamA = shuffled.sublist(0, mid);
      _teamB = shuffled.sublist(mid);
      _phase = _Phase.playing;
      _playingStep = 0;
      _secondsLeft = 60;
    });
    try {
      SoundService.instance.playAmbientLoop(category: 'GRUPO');
    } catch (_) {}
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _phase != _Phase.playing || _playingStep != 0) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _timer?.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 10 && _secondsLeft > 0) {
        SoundService.instance.playTick();
      }
    });
  }

  void _goToQuestions() {
    _timer?.cancel();
    setState(() => _playingStep = 1);
  }

  void _goToVoting() {
    setState(() => _playingStep = 2);
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    try {
      SoundService.instance.stopAmbient();
    } catch (_) {}
    await _handleGameCompleted();
    await saveGameScores(_scores);
    if (!mounted) return;
    setState(() => _phase = _Phase.gameOver);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.length < 6) return const NeedPlayersScreen(minPlayers: 6);
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
                emoji: '👥',
                title: 'YO TENGO UN AMIGO...',
                subtitle: 'Un equipo cuenta anécdota anónima, el otro adivina de quién es.',
                steps: const [
                  'Formad 2 equipos (3 vs 3). La app los forma aleatoriamente.',
                  'Equipo A piensa UNA anécdota real que no haya contado antes (60s). Solo ellos la conocen.',
                  'Equipo B hace 1 pregunta por jugador para adivinar de quién es. La primera pregunta siempre es el título de la anécdota.',
                  'Luego Equipo B vota quién cree que vivió la anécdota. Sin validación automática.',
                  'Revelad al dueño y ¡siguiente ronda si queréis repetir cambiando equipos!',
                  'App solo guía: muestra instrucciones, forma equipos, cronómetro y votación.',
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('YO TENGO UN AMIGO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👥', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('FORMA LOS EQUIPOS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Se necesitan 6+ jugadores. Se crean 2 equipos aleatorios 3 vs 3 (o equilibrados).', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: widget.players.map((p) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)), child: Text(p, style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text)))).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _formTeams,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('FORMAR EQUIPOS ALEATORIOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text(_playingStep == 0 ? 'EQUIPO A PIENSA' : _playingStep == 1 ? 'EQUIPO B PREGUNTA' : 'VOTACIÓN', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: AnimatedPartyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _playingStep == 0 ? _buildThinkStep() : _playingStep == 1 ? _buildQuestionStep() : _buildVotingStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildThinkStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
          child: Column(
            children: [
              Text('EQUIPO A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: _teamA.map((p) => Chip(label: Text(p, style: const TextStyle(fontWeight: FontWeight.w700)), backgroundColor: PartyColors.primary.withValues(alpha: 0.1))).toList()),
              const SizedBox(height: 12),
              Text('Pensad UNA anécdota real que NO hayáis contado antes. Elegid de quién es entre vosotros pero no lo digáis.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.text, height: 1.4)),
              const SizedBox(height: 8),
              Text('Solo una anécdota. Equipo B no mira.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('$_secondsLeft s', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.text)),
        const SizedBox(height: 4),
        Text(_secondsLeft == 0 ? '¡Tiempo!' : 'Equipo A piensa en silencio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.textMuted)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToQuestions,
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('¡LISTO! ANÉCDOTA PENSADA', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
          child: Column(
            children: [
              Text('EQUIPO B ESPERA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: _teamB.map((p) => Text(p, style: TextStyle(fontSize: 12, color: PartyColors.textSecondary))).toList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
          child: Column(
            children: [
              Text('EQUIPO B PREGUNTA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary)),
              const SizedBox(height: 8),
              Text('Haced 1 pregunta por jugador al Equipo A para adivinar de quién es la anécdota.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.text, height: 1.4)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: Text('1ª pregunta siempre: ¿Cuál es el TÍTULO de la anécdota?', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(_teamB.length, (i) {
          final player = _teamB[i];
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
            child: Row(
              children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: PartyColors.primary.withValues(alpha: 0.15), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))), child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: PartyColors.primary, fontSize: 12)))),
                const SizedBox(width: 12),
                Expanded(child: Text(player, style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text))),
                Text(i == 0 ? '→ Título' : '→ 1 pregunta', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text('La app solo guía. El grupo decide si las respuestas valen. Sin validación automática.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToVoting,
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('IR A VOTACIÓN', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildVotingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
          child: Column(
            children: [
              Text('VOTACIÓN — EQUIPO B', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.primary)),
              const SizedBox(height: 8),
              Text('¿De quién creéis que es la anécdota? Marcad vuestra sospecha.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.text)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Candidatos (Equipo A):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
        const SizedBox(height: 8),
        ..._teamA.map((p) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _voted.contains(p) ? PartyColors.primary : PartyColors.border)),
              child: CheckboxListTile(
                value: _voted.contains(p),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _voted.add(p);
                  } else {
                    _voted.remove(p);
                  }
                }),
                title: Text(p, style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text)),
                activeColor: PartyColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
        const SizedBox(height: 8),
        Text('Podéis marcar varios si dudáis. Luego el Equipo A revela la verdad en voz alta.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _finishGame,
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('REVELAR Y TERMINAR', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
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
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('¡ANÉCDOTA REVELADA!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Equipo A desvela de quién era. ¿Acertó el Equipo B?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
                child: Column(
                  children: [
                    Text('EQUIPO A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.primary)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: _teamA.map((p) => Chip(label: Text(p), backgroundColor: PartyColors.primary.withValues(alpha: 0.08))).toList()),
                    const SizedBox(height: 12),
                    Text('EQUIPO B', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: _teamB.map((p) => Chip(label: Text(p))).toList()),
                  ],
                ),
              ),
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
