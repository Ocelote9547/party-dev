// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';

class QuienEsMasGame extends StatefulWidget {
  final List<String> players;
  const QuienEsMasGame({super.key, required this.players});

  @override
  State<QuienEsMasGame> createState() => _QuienEsMasGameState();
}

class _QuienEsMasGameState extends State<QuienEsMasGame> {
  bool _showInstructions = true;
  late String _currentQuestion;
  bool _showVoting = false;
  bool _showResult = false;
  bool _showVotes = false;
  bool _gameStarted = false;
  int _currentRound = 1;
  final int _maxRounds = 10;
  final Map<String, int> _scores = {};
  String _selectedMode = 'Normal';
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  bool _gameOver = false;

  int _voterIndex = 0;
  final List<MapEntry<String, String>> _votes = [];
  final List<String> _usedQuestions = [];

  String _roundWinner = '';
  int _roundWinnerVotes = 0;
  bool _roundTie = false;

  List<String> get _currentPool => _selectedMode == 'Picante' ? GameData.quienEsMasPicanteQuestions : GameData.quienEsMasQuestions;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'GRUPO'); } catch (_) {}
    _currentQuestion = GameData.randomFrom(GameData.quienEsMasQuestions);
    _usedQuestions.add(_currentQuestion);
  }

  void _refreshQuestionForMode() {
    _usedQuestions.clear();
    _currentQuestion = GameData.randomFrom(_currentPool);
    _usedQuestions.add(_currentQuestion);
  }

  void _startGameFromInstructions() => setState(() => _showInstructions = false);

  void _startVoting() {
    setState(() {
      _showVoting = true;
      _showResult = false;
      _voterIndex = 0;
      _votes.clear();
    });
  }

  void _castVote(String votedPlayer) {
    setState(() {
      final voter = widget.players[_voterIndex];
      _votes.add(MapEntry(voter, votedPlayer));
      _voterIndex++;
      if (_voterIndex >= widget.players.length) {
        _showVoting = false;
        _showResult = true;
        _computeResult();
      }
    });
  }

  void _computeResult() {
    final Map<String, int> voteCounts = {};
    for (final entry in _votes) {
      voteCounts[entry.value] = (voteCounts[entry.value] ?? 0) + 1;
    }
    if (voteCounts.isEmpty) {
      _roundTie = true;
      _roundWinner = '';
      _roundWinnerVotes = 0;
      return;
    }
    final sorted = voteCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topVotes = sorted.first.value;
    final winners = sorted.where((e) => e.value == topVotes).toList();
    if (winners.length > 1) {
      _roundTie = true;
      _roundWinner = '';
      _roundWinnerVotes = topVotes;
    } else {
      _roundTie = false;
      _roundWinner = winners.first.key;
      _roundWinnerVotes = topVotes;
      _scores[_roundWinner] = (_scores[_roundWinner] ?? 0) + 1;
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentRound++;
      if (_currentRound > _maxRounds) {
        _gameOver = true;
        return;
      }
      final available = _currentPool.where((q) => !_usedQuestions.contains(q)).toList();
      if (available.isEmpty) {
        _usedQuestions.clear();
        _currentQuestion = GameData.randomFrom(_currentPool);
      } else {
        _currentQuestion = GameData.randomFrom(available);
      }
      _usedQuestions.add(_currentQuestion);
      _showVoting = false;
      _showResult = false;
      _voterIndex = 0;
      _votes.clear();
      _roundWinner = '';
      _roundWinnerVotes = 0;
      _roundTie = false;
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

  Widget _slideFade(Widget child, Animation<double> animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      );

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
        emoji: '👀',
        title: 'QUIÉN ES MÁS',
        subtitle: 'Votad entre vosotros quién es el más.',
        steps: [
          'Se lee una pregunta: "¿Quién es más probable de...?"',
          'Todos los jugadores votan por turnos, pasando el móvil.',
          'No puedes votarte a ti mismo.',
          'El jugador más votado gana la ronda y recibe +1.',
          'Opcional: activa "Mostrar quién votó a quién" para ver el desglose.',
          'Si hay empate, nadie recibe punto. 10 rondas máxima.',
        ],
        onStart: _startGameFromInstructions,
      );
    }
    if (!_gameStarted) return _buildStartScreen();
    if (_gameOver) return _buildGameOverScreen();
    return _buildGameScreen();
  
        },
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('QUIÉN ES MÁS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👀', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('¿Quién es más?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Leed la pregunta.\nTodos votan por turnos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: PartyColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('😇 Normal'),
                    selected: _selectedMode == 'Normal',
                    onSelected: (v) => setState(() {
                      _selectedMode = 'Normal';
                      _refreshQuestionForMode();
                    }),
                    selectedColor: PartyColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: PartyColors.primary,
                    labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _selectedMode == 'Normal' ? PartyColors.primary : PartyColors.text),
                    side: BorderSide(color: _selectedMode == 'Normal' ? PartyColors.primary : PartyColors.border),
                  ),
                  FilterChip(
                    label: const Text('🔥 Picante'),
                    selected: _selectedMode == 'Picante',
                    onSelected: (v) => setState(() {
                      _selectedMode = 'Picante';
                      _refreshQuestionForMode();
                    }),
                    selectedColor: PartyColors.danger.withValues(alpha: 0.2),
                    checkmarkColor: PartyColors.danger,
                    labelStyle: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.danger),
                    side: BorderSide(color: _selectedMode == 'Picante' ? PartyColors.danger : PartyColors.danger.withValues(alpha: 0.4)),
                    backgroundColor: PartyColors.danger.withValues(alpha: 0.08),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _showVotes,
                onChanged: (v) => setState(() => _showVotes = v),
                title: Text('Mostrar quién votó a quién', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PartyColors.text)),
                activeThumbColor: PartyColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () => setState(() => _gameStarted = true),
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

  Widget _buildGameOverScreen() {
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('RESULTADOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: _entrance(Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Resultados finales', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 24),
              ...sorted.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                  child: Row(children: [
                    Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.text))),
                    const SizedBox(width: 12),
                    Text('${e.value}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                  ]),
                ),
              )),
              if (sorted.isEmpty)
                Text('No se registraron votos', style: TextStyle(fontSize: 14, color: PartyColors.textMuted)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();

                    await saveGameScores(_scores);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('QUIÉN ES MÁS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
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
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentRound >= _maxRounds)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('¡ÚLTIMA RONDA!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.warning, letterSpacing: 1)),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(begin: const Offset(0.3, 0), end: Offset.zero).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentRound),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 1.5)),
                    child: Text(_currentQuestion, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: PartyColors.text, height: 1.4)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _slideFade,
                child: !_showVoting && !_showResult
                    ? KeyedSubtree(
                        key: const ValueKey('vote-button'),
                        child: SizedBox(
                          width: double.infinity, height: 64,
                          child: ElevatedButton(
                            onPressed: _startVoting,
                            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            child: const Text('VOTAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                          ),
                        ),
                      )
                    : _showVoting && !_showResult
                        ? KeyedSubtree(
                            key: const ValueKey('voting'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Vota: ', style: TextStyle(fontSize: 16, color: PartyColors.textSecondary)),
                                      Flexible(child: Text(widget.players[_voterIndex], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.primary))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...widget.players.where((p) => p != widget.players[_voterIndex]).map((player) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SizedBox(
                                    width: double.infinity, height: 52,
                                    child: OutlinedButton(
                                      onPressed: () => _castVote(player),
                                      style: OutlinedButton.styleFrom(foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                      child: Text(player, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          )
                        : KeyedSubtree(
                            key: ValueKey<String>('result-$_currentRound'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _entrance(Container(
                                  width: double.infinity, padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: _roundTie ? PartyColors.warning.withValues(alpha: 0.1) : PartyColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _roundTie ? PartyColors.warning.withValues(alpha: 0.3) : PartyColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(children: [
                                    if (_roundTie) ...[
                                      const Text(' EMPATE ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.warning)),
                                      const SizedBox(height: 4),
                                      Text('$_roundWinnerVotes votos para cada uno', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                                    ] else ...[
                                      Text('🏆 $_roundWinner — $_roundWinnerVotes votos', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PartyColors.primary)),
                                    ],
                                  ]),
                                )),
                                if (_showVotes && _votes.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity, padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Desglose de votos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PartyColors.textSecondary, letterSpacing: 0.5)),
                                        const SizedBox(height: 8),
                                        ..._votes.map((v) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text('${v.key} votó a ${v.value}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: PartyColors.text)),
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity, height: 56,
                                  child: ElevatedButton(
                                    onPressed: _nextQuestion,
                                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: Text(_currentRound >= _maxRounds ? 'FIN' : 'CONTINUAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity, height: 56,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(foregroundColor: PartyColors.text, side: BorderSide(color: PartyColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: const Text('SALIR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}