// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/economy_service.dart';
import '../theme/party_theme.dart';
import '../widgets/animated_party_background.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';

class HistoriaGame extends StatefulWidget {
  final List<String> players;
  const HistoriaGame({super.key, required this.players});

  @override
  State<HistoriaGame> createState() => _HistoriaGameState();
}

class _HistoriaGameState extends State<HistoriaGame> {
  bool _showInstructions = true;
  bool _gameOver = false;
  final List<String> _story = [];
  int _currentPlayerIndex = 0;
  int _secondsLeft = 30;
  Timer? _timer;
  final TextEditingController _controller = TextEditingController();
  bool _economyAwarded = false;

  String get _currentPlayer => widget.players[_currentPlayerIndex % widget.players.length];

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _gameOver || _showInstructions) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _submitPhrase(auto: true);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _startGameFromInstructions() {
    setState(() => _showInstructions = false);
    _startTimer();
  }

  void _submitPhrase({bool auto = false}) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _story.add('$_currentPlayer: $text');
      });
    } else if (auto) {
      // auto skip without adding
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Escribe una frase'), backgroundColor: PartyColors.surface),
      );
      return;
    }
    _controller.clear();
    if (_story.length >= widget.players.length * 3) {
      _finishGame();
      return;
    }
    setState(() {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.players.length;
    });
    _startTimer();
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    await _handleGameCompleted();
    final scores = {for (final p in widget.players) p: 1};
    await saveGameScores(scores);
    if (!mounted) return;
    setState(() => _gameOver = true);
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
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {
          if (_showInstructions) {
            return GameInstructions(
              emoji: '📖',
              title: 'HISTORIA COLECTIVA',
              subtitle: 'Cada jugador añade una frase a la historia.',
              steps: const [
                'Por turnos, cada jugador añade una frase.',
                'Tienes 30 segundos por turno.',
                'La historia crece con cada aportación.',
                'Sin tilt — solo escribe y continúa.',
              ],
              onStart: _startGameFromInstructions,
            );
          }
          if (_gameOver) return _buildGameOver();
          return _buildPlaying();
        },
      ),
    );
  }

  Widget _buildPlaying() {
    final storyText = _story.isEmpty ? 'La historia comienza...' : _story.join('\n\n');
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('HISTORIA COLECTIVA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: AnimatedPartyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('TURNO DE $_currentPlayer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: PartyColors.primary, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                Text('⏱ $_secondsLeft s', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _secondsLeft <= 10 ? PartyColors.danger : PartyColors.primary)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.border)),
                  child: Text(storyText, style: TextStyle(fontSize: 14, height: 1.5, color: PartyColors.text)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(color: PartyColors.text),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu frase...',
                    hintStyle: TextStyle(color: PartyColors.textMuted),
                    filled: true,
                    fillColor: PartyColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: PartyColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: PartyColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: PartyColors.primary, width: 1.2)),
                  ),
                  onSubmitted: (_) => _submitPhrase(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitPhrase,
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('AÑADIR FRASE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _finishGame,
                    style: OutlinedButton.styleFrom(foregroundColor: PartyColors.textSecondary, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('TERMINAR HISTORIA', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${_story.length} frases · ${_story.length}/${widget.players.length * 3}', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final fullStory = _story.join(' ');
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📖', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text('HISTORIA FINAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.text, letterSpacing: 2)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.2))),
                  child: Text(fullStory.isEmpty ? 'No se escribió nada.' : fullStory, style: TextStyle(fontSize: 15, height: 1.6, color: PartyColors.text)),
                ),
                const SizedBox(height: 20),
                ..._story.map((line) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
                      child: Text(line, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('VOLVER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
