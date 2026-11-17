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

class YoNuncaEquiposGame extends StatefulWidget {
  final List<String> players;
  const YoNuncaEquiposGame({super.key, required this.players});

  @override
  State<YoNuncaEquiposGame> createState() => _YoNuncaEquiposGameState();
}

class _YoNuncaEquiposGameState extends State<YoNuncaEquiposGame> {
  _Phase _phase = _Phase.instructions;

  List<String> _teamA = [];
  List<String> _teamB = [];
  int _askingTeam = 0; // 0 = A pregunta, B responde
  int _round = 1;
  final int _maxRounds = 4;

  int _secondsLeft = 60;
  Timer? _timer;

  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  // playing sub-steps
  int _step = 0; // 0 pregunta, 1 dice numero, 2 adivina quienes
  final TextEditingController _questionCtrl = TextEditingController();
  int _saidNumber = 0;
  final Set<String> _guessed = {};

  List<String> get _askingNames => _askingTeam == 0 ? _teamA : _teamB;
  List<String> get _answeringNames => _askingTeam == 0 ? _teamB : _teamA;

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
    _questionCtrl.dispose();
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
      _step = 0;
      _secondsLeft = 60;
      _saidNumber = 0;
      _guessed.clear();
      _questionCtrl.clear();
    });
    try {
      SoundService.instance.playAmbientLoop(category: 'GRUPO');
    } catch (_) {}
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _phase != _Phase.playing) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 10 && _secondsLeft > 0) SoundService.instance.playTick();
    });
  }

  void _nextStep() {
    setState(() {
      if (_step < 2) {
        _step++;
        _secondsLeft = 60;
      } else {
        // next round or end
        if (_round >= _maxRounds) {
          _finishGame();
        } else {
          _round++;
          _askingTeam = 1 - _askingTeam;
          _step = 0;
          _secondsLeft = 60;
          _saidNumber = 0;
          _guessed.clear();
          _questionCtrl.clear();
        }
      }
    });
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
                emoji: '🤫',
                title: 'YO NUNCA EQUIPOS',
                subtitle: 'Dos equipos frente a frente. Uno pregunta, el otro dice cuántos lo hicieron.',
                steps: const [
                  'Formad 2 equipos aleatorios (frente a frente).',
                  'Por turnos: un equipo lanza una pregunta Yo Nunca (ej. Yo nunca he cantado en karaoke).',
                  'El otro equipo susurra entre ellos si lo hizo y dice SOLO el número (ej. 5 de 7), sin decir quiénes.',
                  'El equipo preguntador adivina quiénes fueron marcando nombres en la lista.',
                  'Revelad la verdad en voz alta. Sin puntuación automática: la app solo guía.',
                  '4 rondas alternando quién pregunta. ¡Sin validación automática!',
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('YO NUNCA EQUIPOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤫', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('FORMA LOS EQUIPOS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('6+ jugadores. 2 equipos cara a cara.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 24),
              Wrap(spacing: 8, runSpacing: 8, children: widget.players.map((p) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)), child: Text(p, style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text)))).toList()),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _formTeams,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('FORMAR EQUIPOS', style: TextStyle(fontWeight: FontWeight.w800)),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text('RONDA $_round/$_maxRounds', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2))),
      body: AnimatedPartyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _step == 0 ? _buildAskStep() : _step == 1 ? _buildNumberStep() : _buildGuessStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildAskStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Text('PREGUNTA: ${_askingNames.join(", ")}'.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: PartyColors.primary))),
              const Spacer(),
              Text('$_secondsLeft s', style: TextStyle(fontWeight: FontWeight.w900, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.text)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Equipo ${_askingTeam == 0 ? "A" : "B"} lanza Yo Nunca', style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 6),
              Text('Ej: Yo nunca he hecho puenting', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
              const SizedBox(height: 12),
              TextField(
                controller: _questionCtrl,
                decoration: InputDecoration(hintText: 'Escribe Yo nunca...', filled: true, fillColor: PartyColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: PartyColors.border))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.2))),
          child: Column(
            children: [
              Text('EQUIPO QUE RESPONDE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: _answeringNames.map((p) => Chip(label: Text(p, style: const TextStyle(fontSize: 12)), backgroundColor: PartyColors.surface)).toList()),
              const SizedBox(height: 6),
              Text('Susurrad entre vosotros si lo hicisteis', style: TextStyle(fontSize: 12, color: PartyColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => setState(() {
              _step = 1;
              _secondsLeft = 60;
            }),
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('YA HAN SUSURRADO → DECIR NÚMERO', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberStep() {
    final total = _answeringNames.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
          child: Column(
            children: [
              Text('EQUIPO QUE RESPONDE DICE NÚMERO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: PartyColors.primary)),
              const SizedBox(height: 8),
              Text('Decid solo el número, no quiénes. Ej: 5 de $total', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: PartyColors.text)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setState(() => _saidNumber = (_saidNumber - 1).clamp(0, total)), icon: const Icon(Icons.remove_circle_outline), color: PartyColors.primary),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
                    child: Text('$_saidNumber de $total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                  ),
                  IconButton(onPressed: () => setState(() => _saidNumber = (_saidNumber + 1).clamp(0, total)), icon: const Icon(Icons.add_circle_outline), color: PartyColors.primary),
                ],
              ),
              const SizedBox(height: 8),
              Text('$_secondsLeft s', style: TextStyle(fontWeight: FontWeight.w700, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => setState(() {
              _step = 2;
              _secondsLeft = 60;
            }),
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('SIGUIENTE → ADIVINAR QUIÉNES', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildGuessStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
          child: Column(
            children: [
              Text('DICEN: $_saidNumber de ${_answeringNames.length} lo hicieron', style: TextStyle(fontWeight: FontWeight.w900, color: PartyColors.primary)),
              const SizedBox(height: 6),
              Text('Equipo preguntador: ¡adivinad quiénes!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
              const SizedBox(height: 4),
              Text('$_secondsLeft s', style: TextStyle(fontWeight: FontWeight.w700, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Marca a quienes crees que lo hicieron:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
        const SizedBox(height: 8),
        ..._answeringNames.map((p) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _guessed.contains(p) ? PartyColors.primary : PartyColors.border)),
              child: CheckboxListTile(
                value: _guessed.contains(p),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _guessed.add(p);
                  } else {
                    _guessed.remove(p);
                  }
                }),
                title: Text(p, style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text)),
                subtitle: Text(_guessed.contains(p) ? 'Marcado como "lo hizo"' : 'No marcado', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                activeColor: PartyColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
        const SizedBox(height: 8),
        Text('Seleccionados: ${_guessed.length} / $_saidNumber dichos. Sin validación automática.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(_round >= _maxRounds ? 'REVELAR Y TERMINAR' : 'REVELAR → SIGUIENTE RONDA', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 8),
        Text('Revelad la verdad en voz alta y el grupo decide si acertaron.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
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
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('¡JUEGO TERMINADO!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('$_maxRounds rondas completadas. ¡Revelad quién ganó el debate!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
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
