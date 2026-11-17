// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';
import '../widgets/animated_party_background.dart';
import 'game_utils.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';
import 'yo_nunca_equipos_game.dart';
import 'yo_nunca_lobo_game.dart';

class YoNuncaGame extends StatefulWidget {
  final List<String> players;
  const YoNuncaGame({super.key, required this.players});

  @override
  State<YoNuncaGame> createState() => _YoNuncaGameState();
}

class _YoNuncaGameState extends State<YoNuncaGame> {
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  static const int _startFingers = 10;
  static const int _totalPrompts = 10;

  bool _showInstructions = true;
  bool _showVariationSelector = false;
  bool _showModeSelect = false;
  String _selectedMode = '😇 Normal';
  late List<String> _shuffledPrompts;
  int _promptsUsed = 0;
  bool _gameStarted = false;
  bool _gameOver = false;
  final Map<String, int> _fingersMap = {};
  int _fingers = 5;

  late final PageController _variationController;
  int _variationIndex = 0;
  static const _variations = [
    _Variation(emoji: '🤫', title: 'NORMAL', description: 'Descubre los secretos del grupo'),
    _Variation(emoji: '🐺', title: 'LOBO', description: 'Yo nunca... pero los lobos acechan en la noche'),
    _Variation(emoji: '👥', title: 'EQUIPOS', description: 'Un equipo pregunta, el otro dice cuántos lo hicieron'),
  ];

  @override
  void initState() {
    super.initState();
    _variationController = PageController(viewportFraction: 0.88);
    try { SoundService.instance.playAmbientLoop(category: 'GRUPO'); } catch (_) {}
    for (final p in widget.players) {
      _fingersMap[p] = _startFingers;
    }
  }

  @override
  void dispose() {
    _variationController.dispose();
    super.dispose();
  }

  void _setupGame() {
    final prompts = List<String>.from(GameData.yoNuncaModos[_selectedMode]!)..shuffle();
    _shuffledPrompts = prompts.take(_totalPrompts).toList();
    _promptsUsed = 0;
    setState(() => _gameStarted = true);
  }

  String get _currentPrompt =>
      _shuffledPrompts.isNotEmpty ? _shuffledPrompts[_promptsUsed.clamp(0, _shuffledPrompts.length - 1)] : '';

  String _fingerVisual(int count) {
    if (count <= 0) return '💀';
    const partials = ['', '☝️', '✌️', '🤟', '🖖'];
    final fullHands = '✋' * (count ~/ 5);
    return ('$fullHands${partials[count % 5]}').trim();
  }

  void _startGameFromInstructions() => setState(() {
    _showInstructions = false;
    _showVariationSelector = true;
  });

  void _onVariationComenzar() {
    if (_variationIndex == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => YoNuncaLoboGame(players: widget.players)));
      return;
    }
    if (_variationIndex == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => YoNuncaEquiposGame(players: widget.players)));
      return;
    }
    setState(() {
      _showVariationSelector = false;
      _showModeSelect = true;
    });
  }

  void _nextPrompt() {
    setState(() => _promptsUsed++);
    if (_promptsUsed >= _totalPrompts) {
      setState(() => _gameOver = true);
    }
  }

  void _onYoNunca() {
    setState(() {
      if (_fingers > 0) _fingers--;
    });
    _nextPrompt();
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
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    if (_showInstructions) {
      return GameInstructions(
        emoji: '🤫',
        title: 'YO NUNCA',
        subtitle: 'Versión de la vida real.',
        steps: [
          'Todos empiezan con 10 dedos.',
          'Se lee el "yo nunca" en voz alta.',
          'Los que lo hayan hecho bajan un dedo.',
          'El último con dedos gana.',
        ],
        onStart: _startGameFromInstructions,
      );
    }
    if (_showVariationSelector) return _buildVariationSelector();
    if (_showModeSelect) return _buildModeSelect();
    if (!_gameStarted) return _buildStartScreen();
    if (_gameOver) return _buildGameOver();
    return _buildGameScreen();
  
        },
      ),
    );
  }

  Widget _buildVariationSelector() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('YO NUNCA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text('Elige variación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.text)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _variationController,
              physics: const BouncingScrollPhysics(),
              itemCount: _variations.length,
              onPageChanged: (i) => setState(() => _variationIndex = i),
              itemBuilder: (context, index) {
                final v = _variations[index];
                final selected = index == _variationIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? PartyColors.primary.withValues(alpha: 0.08) : PartyColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? PartyColors.primary : PartyColors.border, width: selected ? 1.5 : 1),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(v.emoji, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(v.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: PartyColors.text)),
                        const SizedBox(height: 8),
                        Text(v.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: PartyColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_variations.length, (i) {
              final selected = i == _variationIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(color: selected ? PartyColors.primary : PartyColors.border, borderRadius: BorderRadius.circular(10)),
              );
            }),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: _onVariationComenzar,
                style: FilledButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: const Text('COMENZAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelect() {
    final modes = GameData.yoNuncaModos.keys.toList();
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('YO NUNCA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('Elige el modo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Selecciona el estilo de frases', style: TextStyle(fontSize: 15, color: PartyColors.textSecondary)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: modes.map((mode) {
                  final isSelected = _selectedMode == mode;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? PartyColors.primary.withValues(alpha: 0.15) : PartyColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? PartyColors.primary : PartyColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(mode, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? PartyColors.primary : PartyColors.text)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showModeSelect = false),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('YO NUNCA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🙌', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(_selectedMode, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PartyColors.primary)),
              ),
              const SizedBox(height: 16),
              Text('$_startFingers Dedos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Todos empiezan con $_startFingers dedos.\nSe lee el "yo nunca" en voz alta y quien\nlo haya hecho baja un dedo de verdad.\n$_totalPrompts frases. El último con dedos gana.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: PartyColors.textSecondary, height: 1.5)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: _setupGame,
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

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('YO NUNCA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Text(_selectedMode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PartyColors.primary)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text('$_promptsUsed / $_totalPrompts', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.primary)),
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
              LinearProgressIndicator(
                value: _promptsUsed / _totalPrompts,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: PartyColors.surface,
                color: PartyColors.primary,
              ),
              const SizedBox(height: 24),
              Text('YO NUNCA NUNCA...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 3, color: PartyColors.textMuted)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 1.5)),
                child: Text(_currentPrompt.replaceFirst('Yo nunca ', ''), textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: PartyColors.text, height: 1.4)),
              ),
              const SizedBox(height: 16),
              Text('Lee la frase en voz alta 👆\nQuien lo haya hecho, baja un dedo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('✋ x$_fingers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                  const SizedBox(width: 12),
                  Row(children: List.generate(5, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Icon(Icons.back_hand, size: 18, color: i < _fingers ? PartyColors.primary : PartyColors.border)))),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: SizedBox(height: 64, child: ElevatedButton(onPressed: _onYoNunca, style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('YO NUNCA 🍺', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1))))),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 64, child: ElevatedButton(onPressed: _nextPrompt, style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(_promptsUsed == _totalPrompts - 1 ? 'VER RESULTADOS' : 'SIGUIENTE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1))))),
              ]),
              const SizedBox(height: 32),
              Align(alignment: Alignment.centerLeft, child: Text('JUGADORES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted))),
              const SizedBox(height: 12),
              ...widget.players.map((p) {
                final f = _fingersMap[p] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PartyColors.border),
                  ),
                  child: Row(children: [
                    Text(_fingerVisual(f), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PartyColors.text)),
                    ),
                    Text('$f dedos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: f > 0 ? PartyColors.primary : PartyColors.danger)),
                  ]),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: TextButton(
                  onPressed: () async {
                    await _handleGameCompleted();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text('SALIR DEL JUEGO', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildGameOver() {
    final sorted = widget.players.toList()
      ..sort((a, b) => (_fingersMap[b] ?? 0).compareTo(_fingersMap[a] ?? 0));
    final topFingers = sorted.isNotEmpty ? (_fingersMap[sorted.first] ?? 0) : 0;
    final winners = sorted.where((p) => (_fingersMap[p] ?? 0) == topFingers).toList();

    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('JUEGO TERMINADO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text, letterSpacing: 2)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.4), width: 1.5)),
                child: Column(children: [
                  Text(winners.length > 1 ? '🏆 EMPATE' : '🏆 GANADOR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  ...winners.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(w, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                  )),
                  const SizedBox(height: 8),
                  Text('$topFingers dedos restantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 24),
              Align(alignment: Alignment.centerLeft, child: Text('RESULTADOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted))),
              const SizedBox(height: 12),
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final f = _fingersMap[p] ?? 0;
                final isWinner = winners.contains(p);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isWinner ? PartyColors.primary.withValues(alpha: 0.08) : PartyColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isWinner ? PartyColors.primary.withValues(alpha: 0.4) : PartyColors.border),
                  ),
                  child: Row(children: [
                    Text('#${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.textMuted)),
                    const SizedBox(width: 12),
                    Text(_fingerVisual(f), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PartyColors.text))),
                    Text('$f dedos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: f > 0 ? PartyColors.primary : PartyColors.danger)),
                  ]),
                );
              }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Variation {
  final String emoji;
  final String title;
  final String description;
  const _Variation({required this.emoji, required this.title, required this.description});
}