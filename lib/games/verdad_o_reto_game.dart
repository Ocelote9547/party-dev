// ignore_for_file: use_build_context_synchronously
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';

class VerdadORetoGame extends StatefulWidget {
  final List<String> players;
  const VerdadORetoGame({super.key, required this.players});

  @override
  State<VerdadORetoGame> createState() => _VerdadORetoGameState();
}

class _VerdadORetoGameState extends State<VerdadORetoGame> {
  bool _showInstructions = true;
  int _currentPlayerIndex = 0;
  bool _gameStarted = false;
  bool _showChoice = true;
  String? _currentChoice;
  String? _currentText;
  int _currentRound = 1;
  final int _maxRounds = 20;
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  bool _gameOver = false;
  bool _showCategorySelect = false;
  String _selectedCategory = '😇 Suave';

  late List<String> _truths;
  late List<String> _dares;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'RETO'); } catch (_) {}
    _truths = GameData.verdadORetos.where((p) => p.type == 'verdad').map((p) => p.text).toList()..shuffle();
    _dares = GameData.verdadORetos.where((p) => p.type == 'reto').map((p) => p.text).toList()..shuffle();
    for (final p in widget.players) {
      _scores[p] = 0;
    }
  }

  String get _currentPlayer => widget.players.isNotEmpty
      ? widget.players[_currentPlayerIndex % widget.players.length]
      : 'Jugador';

  void _startGameFromInstructions() => setState(() {
    _showInstructions = false;
    _showCategorySelect = true;
  });

  void _startGame() {
    final items = GameData.verdadORetoCategorias[_selectedCategory]!;
    _truths = items.where((p) => p.type == 'verdad').map((p) => p.text).toList()..shuffle();
    _dares = items.where((p) => p.type == 'reto').map((p) => p.text).toList()..shuffle();
    setState(() {
      _showCategorySelect = false;
      _gameStarted = true;
    });
  }

  void _chooseVerdad() {
    final text = _truths.isEmpty
        ? GameData.verdadORetos.where((p) => p.type == 'verdad').map((p) => p.text).first
        : _truths[_currentRound % _truths.length];
    setState(() {
      _showChoice = false;
      _currentChoice = 'verdad';
      _currentText = text;
    });
  }

  void _chooseReto() {
    final text = _dares.isEmpty
        ? GameData.verdadORetos.where((p) => p.type == 'reto').map((p) => p.text).first
        : _dares[_currentRound % _dares.length];
    setState(() {
      _showChoice = false;
      _currentChoice = 'reto';
      _currentText = text;
    });
  }

  void _done() {
    setState(() {
      _scores[_currentPlayer] = (_scores[_currentPlayer] ?? 0) + 1;
      _showChoice = true;
      _currentChoice = null;
      _currentText = null;
      _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.players.length;
      _currentRound++;
      if (_currentRound > _maxRounds) _gameOver = true;
    });
  }

  void _skip() {
    setState(() {
      _showChoice = true;
      _currentChoice = null;
      _currentText = null;
      _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.players.length;
      _currentRound++;
      if (_currentRound > _maxRounds) _gameOver = true;
    });
  }

  Widget _entrance(Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0).toDouble(), child: child),
        ),
        child: child,
      );

  Widget _flipTransition(Widget child, Animation<double> animation) {
    final incoming = child.key == const ValueKey('reveal-card');
    final curved = CurvedAnimation(
      parent: incoming ? animation : ReverseAnimation(animation),
      curve: Curves.easeOutCubic,
    );
    final rotation = Tween<double>(begin: incoming ? pi / 2 : 0, end: incoming ? 0 : pi / 2).animate(curved);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(rotation.value),
        child: Opacity(opacity: animation.value.clamp(0.0, 1.0).toDouble(), child: child),
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
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
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    if (_showInstructions) {
      return GameInstructions(
        emoji: '⚖️',
        title: 'VERDAD O RETO',
        subtitle: '¿Te atreves a decir la verdad o a hacer el reto?',
        steps: [
          'Cada jugador elige: ¿Verdad o Reto?',
          'Si eliges verdad, responde con honestidad.',
          'Si eliges reto, haz lo que se te pida.',
          'Si te niegas, bebe o suma un punto.',
        ],
        onStart: _startGameFromInstructions,
      );
    }
    if (_showCategorySelect) return _buildCategorySelect();
    if (!_gameStarted) return _buildStartScreen();
    if (_gameOver) return _buildGameOver();
    return _buildGameScreen();
  
        },
      ),
    );
  }

  Widget _buildCategorySelect() {
    final categories = GameData.verdadORetoCategorias.keys.toList();
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('VERDAD O RETO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('Elige categoría', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('¿Qué nivel de intensidad?', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: PartyColors.textSecondary, height: 1.5)),
              const SizedBox(height: 40),
              ...categories.map((cat) {
                final isPicante = cat.contains('Picante');
                final isSelected = _selectedCategory == cat;
                final selectedColor = isPicante ? PartyColors.danger : PartyColors.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity, height: 64,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _selectedCategory = cat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? selectedColor : (isPicante ? PartyColors.danger.withValues(alpha: 0.08) : PartyColors.surface),
                        foregroundColor: isSelected ? PartyColors.onPrimary : (isPicante ? PartyColors.danger : PartyColors.text),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? selectedColor : (isPicante ? PartyColors.danger.withValues(alpha: 0.4) : PartyColors.border),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1, color: isSelected ? PartyColors.onPrimary : (isPicante ? PartyColors.danger : PartyColors.text))),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('CONTINUAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('VERDAD O RETO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('Verdad o Reto', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('¿Te atreves?\nElige sabiamente.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: PartyColors.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(_selectedCategory, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _showCategorySelect = true;
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border))),
                  child: Text('CAMBIAR CATEGORÍA', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.text)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: _startGame,
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

  Widget _buildGameOver() {
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final winner = sorted.isNotEmpty ? sorted.first : null;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _entrance(Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('JUEGO TERMINADO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text, letterSpacing: 2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(_selectedCategory, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.primary)),
              ),
              const SizedBox(height: 32),
              if (winner != null && winner.value > 0) ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.4), width: 1.5)),
                  child: Column(children: [
                    const Text('🏆 MÁS ATREVIDO/A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text(winner.key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                    const SizedBox(height: 8),
                    Text('${winner.value} puntos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 24),
              ],
              Align(alignment: Alignment.centerLeft, child: Text('MARCADOR FINAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted))),
              const SizedBox(height: 12),
              ...sorted.map((entry) {
                final isTop = entry.key == sorted.first.key && entry.value > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isTop ? PartyColors.primary.withValues(alpha: 0.08) : PartyColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isTop ? PartyColors.primary.withValues(alpha: 0.3) : PartyColors.border),
                  ),
                  child: Row(children: [
                    if (isTop) const Padding(padding: EdgeInsets.only(right: 10), child: Text('🏆', style: TextStyle(fontSize: 16)))
                    else const Padding(padding: EdgeInsets.only(right: 10), child: Text('✅', style: TextStyle(fontSize: 14))),
                    Expanded(child: Text(entry.key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isTop ? PartyColors.primary : PartyColors.text))),
                    Text('${entry.value}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isTop ? PartyColors.primary : PartyColors.textSecondary)),
                  ]),
                );
              }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();

                    await saveGameScores(_scores);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('VERDAD O RETO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: _currentRound >= _maxRounds ? PartyColors.warning.withValues(alpha: 0.2) : PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text('RONDA $_currentRound/$_maxRounds', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _currentRound >= _maxRounds ? PartyColors.warning : PartyColors.primary)),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedPartyBackground(child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(_selectedCategory, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.primary)),
              ),
              const SizedBox(height: 16),
              if (_currentRound >= _maxRounds)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('¡ÚLTIMA RONDA!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.warning, letterSpacing: 1)),
                ),
              Text('Turno de $_currentPlayer', style: TextStyle(fontSize: 14, color: PartyColors.textMuted, letterSpacing: 1)),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _flipTransition,
                child: _showChoice
                    ? KeyedSubtree(
                        key: const ValueKey('choice-view'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('¿Qué eliges?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.text)),
                            const SizedBox(height: 8),
                            Text('Piensa bien...', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                            const SizedBox(height: 32),
                            Row(children: [
                              Expanded(
                                child: SizedBox(
                                  height: 80,
                                  child: ElevatedButton(
                                    onPressed: _currentRound >= _maxRounds ? null : _chooseVerdad,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF635BFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('🗣️', style: TextStyle(fontSize: 28)),
                                        SizedBox(height: 4),
                                        Text('VERDAD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 80,
                                  child: ElevatedButton(
                                    onPressed: _currentRound >= _maxRounds ? null : _chooseReto,
                                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('🔥', style: TextStyle(fontSize: 28)),
                                        SizedBox(height: 4),
                                        Text('RETO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('reveal-card'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _currentChoice == 'verdad' ? const Color(0xFF635BFF).withValues(alpha: 0.1) : PartyColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _currentChoice == 'verdad' ? const Color(0xFF635BFF).withValues(alpha: 0.5) : PartyColors.danger.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _currentChoice == 'verdad' ? '🗣️ VERDAD' : '🔥 RETO',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      color: _currentChoice == 'verdad' ? const Color(0xFF635BFF) : PartyColors.danger,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(_currentText ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PartyColors.text, height: 1.4)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _skip,
                                    style: OutlinedButton.styleFrom(foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    child: const Text('PASAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _done,
                                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    child: const Text('HECHO ✓', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              Align(alignment: Alignment.centerLeft, child: Text('MARCADOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted))),
              const SizedBox(height: 12),
              ...sorted.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: PartyColors.border)),
                child: Row(children: [
                  Expanded(child: Text(entry.key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PartyColors.text))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('${entry.value}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary)),
                  ),
                ]),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('SALIR DEL JUEGO', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}