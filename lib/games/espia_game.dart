// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';
import '../widgets/animated_party_background.dart';
import 'game_utils.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';

class EspiaGame extends StatefulWidget {
  final List<String> players;
  const EspiaGame({super.key, required this.players});

  @override
  State<EspiaGame> createState() => _EspiaGameState();
}

class _EspiaGameState extends State<EspiaGame> {
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  bool _showInstructions = true;
  late String _location;
  int _spyIndex = 0;
  int _currentPlayerIndex = 0;
  bool _showingWord = false;
  bool _setupDone = false;
  final int _maxRounds = 5;
  int _currentRound = 1;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'MENTIRA'); } catch (_) {}
    _location = GameData.randomFrom(GameData.espiaLocations);
    _spyIndex = safeRandomIndex(widget.players.length);
  }

  String get _currentPlayer => widget.players[_currentPlayerIndex];
  bool get _isSpy => _currentPlayerIndex == _spyIndex;

  void _startGameFromInstructions() => setState(() => _showInstructions = false);

  void _revealWord() => setState(() => _showingWord = true);

  void _nextPlayer() {
    setState(() {
      _showingWord = false;
      _currentPlayerIndex++;
      if (_currentPlayerIndex >= widget.players.length) {
        _setupDone = true;
      }
    });
  }

  void _newRound() {
    setState(() {
      _currentRound++;
      _currentPlayerIndex = 0;
      _showingWord = false;
      _setupDone = false;
      _location = GameData.randomFrom(GameData.espiaLocations);
      _spyIndex = safeRandomIndex(widget.players.length);
    });
  }

  void _showSpyGuessDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Text('ADIVINAR UBICACIÓN', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe la ubicación...'),
          onSubmitted: (val) {
            controller.dispose();
            Navigator.pop(ctx);
            final guess = val.trim();
            final correct = guess.toLowerCase() == _location.toLowerCase();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx2) => AlertDialog(
                backgroundColor: PartyColors.surface,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(correct ? Icons.check_circle : Icons.cancel, size: 64, color: correct ? PartyColors.success : PartyColors.danger),
                    const SizedBox(height: 16),
                    Text(correct ? '¡Correcto!' : '¡Incorrecto!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: correct ? PartyColors.success : PartyColors.danger)),
                    const SizedBox(height: 8),
                    Text('La ubicación era: $_location', style: TextStyle(fontSize: 13, color: PartyColors.textMuted)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx2),
                        style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async { controller.dispose(); Navigator.pop(ctx); },
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );
  }

  void _showVoteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Text('¿Quién es el espía?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.players.map((p) => ListTile(
            title: Text(p, style: TextStyle(color: PartyColors.text)),
            onTap: () { Navigator.pop(ctx); _showResult(p); },
          )).toList(),
        ),
      ),
    );
  }

  void _showResult(String votedPlayer) {
    final wasSpy = votedPlayer == widget.players[_spyIndex];
    if (wasSpy) {
      _showSpyLastChanceDialog();
    } else {
      _showIncorrectVoteDialog();
    }
  }

  void _showSpyLastChanceDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Icon(Icons.gps_fixed, size: 24, color: PartyColors.danger),
            const SizedBox(width: 8),
            Expanded(child: Text('ÚLTIMA OPORTUNIDAD', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800, letterSpacing: 1))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¡Espía atrapado!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.success)),
            const SizedBox(height: 8),
            Text('Tienes una última oportunidad de adivinar la ubicación.', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Creo que el lugar es...'),
              onSubmitted: (_) => _submitSpyGuess(ctx, controller),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitSpyGuess(ctx, controller),
                style: ElevatedButton.styleFrom(backgroundColor: PartyColors.danger, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('ADIVINAR', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  void _submitSpyGuess(BuildContext dialogContext, TextEditingController controller) {
    final guess = controller.text.trim();
    Navigator.pop(dialogContext);
    if (!mounted) return;
    final spyWon = guess.toLowerCase() == _location.toLowerCase();
    _showSpyGuessResultDialog(spyWon);
  }

  void _showSpyGuessResultDialog(bool spyWon) {
    final realSpy = widget.players[_spyIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spyWon ? Icons.check_circle : Icons.cancel, size: 64, color: spyWon ? PartyColors.danger : PartyColors.success),
            const SizedBox(height: 16),
            Text(spyWon ? '¡El espía adivinó!' : '¡El espía falló!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: spyWon ? PartyColors.danger : PartyColors.success)),
            const SizedBox(height: 8),
            Text(spyWon ? 'Gana el espía' : 'Ganan los demás', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: spyWon ? PartyColors.danger : PartyColors.success)),
            const SizedBox(height: 4),
            Text(spyWon ? '+3 puntos para $realSpy' : '+1 punto para los demás', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PartyColors.warning)),
            const SizedBox(height: 8),
            Text('La ubicación era: $_location', style: TextStyle(fontSize: 13, color: PartyColors.textMuted)),
            const SizedBox(height: 24),
            _buildRoundButtons(ctx),
          ],
        ),
      ),
    );
  }

  void _showIncorrectVoteDialog() {
    final realSpy = widget.players[_spyIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, size: 64, color: PartyColors.danger),
            const SizedBox(height: 16),
            Text('¡Incorrecto!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.danger)),
            const SizedBox(height: 8),
            Text('El espía era $realSpy', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
            const SizedBox(height: 8),
            Text('La ubicación era: $_location', style: TextStyle(fontSize: 13, color: PartyColors.textMuted)),
            const SizedBox(height: 24),
            _buildRoundButtons(ctx),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButtons(BuildContext dialogContext) {
    final hasMoreRounds = _currentRound < _maxRounds;
    return Column(
      children: [
        if (hasMoreRounds)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async { Navigator.pop(dialogContext); _newRound(); },
              style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('RONDA ${_currentRound + 1}/$_maxRounds', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        if (hasMoreRounds) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async { await _handleGameCompleted(); if (dialogContext.mounted) Navigator.pop(dialogContext); if (!mounted) return; Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: PartyColors.border))),
            child: const Text('VOLVER'),
          ),
        ),
      ],
    );
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
        emoji: '🕵️',
        title: '¿QUIÉN ES EL ESPIA?',
        subtitle: 'Encuentra al espía antes de que descubra la ubicación.',
        steps: [
          'Un jugador es el espía y recibe una ubicación diferente.',
          'Los demás reciben la ubicación real.',
          'Hacéis preguntas sí/no sobre el lugar.',
          'El espía intenta adivinar la ubicación sin ser descubierto.',
          'Votad: ¿quién creéis que es el espía?',
        ],
        onStart: _startGameFromInstructions,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: _setupDone
          ? KeyedSubtree(key: const ValueKey('discussion'), child: _buildDiscussionPhase())
          : KeyedSubtree(key: ValueKey('reveal-$_currentRound'), child: _buildRevealPhase()),
    );
  
        },
      ),
    );
  }

  Widget _buildRevealPhase() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ESPIA - RONDA $_currentRound/$_maxRounds', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.25, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey('turn-$_currentPlayerIndex-$_showingWord'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_currentPlayer, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: PartyColors.text)),
                  const SizedBox(height: 12),
                  Text('Pasa el móvil para ver tu ubicación', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                  const SizedBox(height: 48),
                  if (!_showingWord)
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _revealWord,
                        style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('TAP PARA VER TU UBICACIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: PartyColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _isSpy ? PartyColors.danger.withValues(alpha: 0.5) : PartyColors.primary.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Column(
                        children: [
                          if (_isSpy) ...[
                            const Text('Eres el ESPIA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.danger, letterSpacing: 2)),
                            const SizedBox(height: 12),
                            const Text('???', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: PartyColors.danger)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: PartyColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.warning.withValues(alpha: 0.3))),
                              child: const Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 20, color: PartyColors.warning),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('No sabes la ubicación. Intenta adivinar con las preguntas.', style: TextStyle(fontSize: 13, color: PartyColors.warning, fontStyle: FontStyle.italic))),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text('Tu ubicación es:', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                            const SizedBox(height: 12),
                            Text(_location, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPlayer,
                        style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border))),
                        child: Text(_currentPlayerIndex < widget.players.length - 1 ? 'SIGUIENTE JUGADOR' : 'EMPEZAR PARTIDA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionPhase() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ESPIA - RONDA $_currentRound/$_maxRounds', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.question_answer_outlined, size: 64, color: PartyColors.primary),
              const SizedBox(height: 24),
              Text('Fase de preguntas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 12),
              Text('Haced preguntas sí/no para\ndescubrir al espía.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5, color: PartyColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: PartyColors.border)),
                child: Text('Ejemplo: "¿Hay agua cerca?"', style: TextStyle(fontSize: 13, color: PartyColors.textMuted, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _showSpyGuessDialog,
                  style: OutlinedButton.styleFrom(foregroundColor: PartyColors.danger, side: const BorderSide(color: PartyColors.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('ADIVINAR UBICACIÓN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showVoteDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOTAR AHORA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
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