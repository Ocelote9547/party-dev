// ignore_for_file: use_build_context_synchronously
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';
import '../widgets/animated_party_background.dart';
import 'game_utils.dart';
import '../services/economy_service.dart';
import '../services/sound_service.dart';

class MatarCasarBesarGame extends StatefulWidget {
  final List<String> players;
  const MatarCasarBesarGame({super.key, required this.players});
  @override
  State<MatarCasarBesarGame> createState() => _MatarCasarBesarGameState();
}

class _MatarCasarBesarGameState extends State<MatarCasarBesarGame> {
  bool _economyAwarded = false;
  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  bool _showInstructions = true;
  int _currentRound = 1;
  final int _maxRounds = 10;
  bool _gameStarted = false;
  bool _gameOver = false;
  List<String> _currentTrio = [];
  bool _isVoting = false;
  int _voterIndex = 0;
  Map<String, String> _assignments = {};
  Map<String, Map<String, int>> _tally = {};
  bool _showResult = false;
  List<String> _previousTrio = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'GRUPO'); } catch (_) {}
    if (widget.players.length >= 3) {
      _pickNewTrio();
    }
  }

  void _startGameFromInstructions() {
    if (!mounted) return;
    setState(() => _showInstructions = false);
  }

  void _pickNewTrio() {
    if (widget.players.length < 3) {
      _currentTrio = [];
      return;
    }
    List<String> next;
    int attempts = 0;
    do {
      final shuffled = List<String>.from(widget.players)..shuffle(_random);
      next = shuffled.take(3).toList();
      attempts++;
    } while (_previousTrio.isNotEmpty && _listsEqual(next, _previousTrio) && attempts < 10);
    _previousTrio = List.from(next);
    _currentTrio = next;
    _assignments = {};
    _tally = {for (final n in _currentTrio) n: {'matar': 0, 'casar': 0, 'besar': 0}};
    _isVoting = false;
    _voterIndex = 0;
    _showResult = false;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = List<String>.from(a)..sort();
    final sb = List<String>.from(b)..sort();
    for (int i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  void _startVoting() {
    if (!mounted) return;
    setState(() {
      _isVoting = true;
      _voterIndex = 0;
      _assignments = {};
      _showResult = false;
      _tally = {for (final n in _currentTrio) n: {'matar': 0, 'casar': 0, 'besar': 0}};
    });
  }

  void _select(String name, String action) {
    if (!mounted) return;
    setState(() {
      String? previousName;
      for (final entry in _assignments.entries) {
        if (entry.value == action) {
          previousName = entry.key;
          break;
        }
      }
      if (previousName != null) {
        _assignments.remove(previousName);
      }
      _assignments[name] = action;
    });
  }

  bool get _canConfirm {
    if (_assignments.length != 3) return false;
    final values = _assignments.values.toSet();
    return values.length == 3 && values.contains('matar') && values.contains('casar') && values.contains('besar');
  }

  void _confirmVote() {
    if (!_canConfirm) return;
    if (!mounted) return;
    setState(() {
      for (final e in _assignments.entries) {
        final counts = _tally[e.key];
        if (counts == null) continue;
        counts[e.value] = (counts[e.value] ?? 0) + 1;
      }
      _voterIndex++;
      if (_voterIndex >= widget.players.length) {
        _isVoting = false;
        _showResult = true;
      } else {
        _assignments = {};
      }
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

  void _nextRound() {
    if (!mounted) return;
    setState(() {
      _currentRound++;
      if (_currentRound > _maxRounds) {
        _gameOver = true;
        return;
      }
      _pickNewTrio();
    });
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
            title: Text('Seguro que quieres salir?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderas el progreso', style: TextStyle(color: PartyColors.textSecondary)),
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
              emoji: 'X',
              title: 'MATAR, CASAR, BESAR',
              subtitle: 'Con quien te quedarias?',
              steps: [
                'Se muestran 3 nombres del grupo.',
                'Cada jugador elige: a quien matarias, casarias o besarias? (sin repetir).',
                'Pasad el movil por turnos y votad.',
                'Se revela el conteo final por nombre.',
                'Divertios con las respuestas.',
              ],
              onStart: _startGameFromInstructions,
            );
          }
          if (!_gameStarted) return _buildStartScreen();
          if (_gameOver) return _buildGameOver();
          return _buildGameScreen();
        },
      ),
    );
  }

  Widget _buildGameOver() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _entrance(Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('X', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('JUEGO TERMINADO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text, letterSpacing: 2)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 1.5)),
                child: Column(children: [
                  Text('Completasteis $_maxRounds rondas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PartyColors.text)),
                  const SizedBox(height: 8),
                  Text('Esperamos que hayais disfrutado!', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () async { await _handleGameCompleted(); if (context.mounted) Navigator.pop(context); },
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

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('MATAR, CASAR, BESAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('X', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text('Matar, Casar, Besar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PartyColors.text)),
              const SizedBox(height: 8),
              Text('Con quien te quedarias?\nElige sabiamente.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: PartyColors.textSecondary, height: 1.5)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.players.length < 3) return;
                    if (_currentTrio.length != 3) _pickNewTrio();
                    setState(() => _gameStarted = true);
                  },
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
    if (widget.players.length < 3) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('MATAR, CASAR, BESAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
        body: AnimatedPartyBackground(child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: PartyColors.textMuted),
                const SizedBox(height: 16),
                Text('Se necesitan al menos 3 jugadores', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PartyColors.textSecondary)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('VOLVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        )),
      );
    }
    if (_currentTrio.length != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentTrio.length != 3) {
          setState(() => _pickNewTrio());
        }
      });
      return Scaffold(
        backgroundColor: PartyColors.background,
        body: Center(child: CircularProgressIndicator(color: PartyColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('MATAR, CASAR, BESAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
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
              if (_currentRound >= _maxRounds)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('ULTIMA RONDA!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.warning, letterSpacing: 1)),
                ),
              Text('Que harias con...?', style: TextStyle(fontSize: 14, color: PartyColors.textMuted, letterSpacing: 1)),
              const SizedBox(height: 32),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPlayerCard(_currentTrio[0], 'MATAR', PartyColors.danger),
                      _buildPlayerCard(_currentTrio[1], 'CASAR', PartyColors.primary),
                      _buildPlayerCard(_currentTrio[2], 'BESAR', PartyColors.love),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildVotingArea(),
              ),
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

  Widget _buildVotingArea() {
    if (_showResult) {
      return KeyedSubtree(
        key: const ValueKey('result'),
        child: _entrance(Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PartyColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Text('Resultados - Ronda $_currentRound', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.text)),
                  const SizedBox(height: 16),
                  for (final name in _currentTrio) _buildResultRow(name),
                  const SizedBox(height: 8),
                  Text('Votaron ${widget.players.length} jugadores', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextRound,
                style: ElevatedButton.styleFrom(backgroundColor: PartyColors.surface, foregroundColor: PartyColors.text, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border))),
                child: Text(_currentRound >= _maxRounds ? 'VER RESULTADO' : 'SIGUIENTE RONDA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ),
          ],
        )),
      );
    }
    if (_isVoting) {
      final voter = widget.players[_voterIndex % widget.players.length];
      return KeyedSubtree(
        key: ValueKey('voting-$_voterIndex'),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Vota: ', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                Flexible(child: Text(voter, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.primary))),
                const SizedBox(width: 8),
                Text('(${_voterIndex + 1}/${widget.players.length})', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
              ]),
            ),
            const SizedBox(height: 16),
            for (final name in _currentTrio) _buildVoteRow(name),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _canConfirm ? _confirmVote : null,
                style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text(_voterIndex + 1 < widget.players.length ? 'CONFIRMAR Y SIGUIENTE' : 'CONFIRMAR VOTO', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Asigna cada nombre a una accion distinta', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
          ],
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('start-vote'),
      child: Column(children: [
        _entrance(Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PartyColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PartyColors.border),
          ),
          child: Text('Cada jugador elige MATAR / CASAR / BESAR sin repetir.\nPasad el movil por turnos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: PartyColors.textSecondary, height: 1.4)),
        )),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _startVoting,
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('VOTAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }

  Widget _buildVoteRow(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: PartyColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PartyColors.text)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildActionChip(name, 'matar', 'X', PartyColors.danger),
                const SizedBox(width: 8),
                _buildActionChip(name, 'casar', 'X', PartyColors.primary),
                const SizedBox(width: 8),
                _buildActionChip(name, 'besar', 'X', PartyColors.love),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String name, String action, String emoji, Color color) {
    final selected = _assignments[name] == action;
    return Expanded(
      child: InkWell(
        onTap: () => _select(name, action),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : PartyColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : PartyColors.border, width: selected ? 2 : 1),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(action.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? color : PartyColors.textSecondary, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultRow(String name) {
    final counts = _tally[name] ?? {'matar': 0, 'casar': 0, 'besar': 0};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: PartyColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: PartyColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PartyColors.text)),
            const SizedBox(height: 8),
            Row(children: [
              _buildCountChip('X', '${counts['matar']}', PartyColors.danger),
              const SizedBox(width: 8),
              _buildCountChip('X', '${counts['casar']}', PartyColors.primary),
              const SizedBox(width: 8),
              _buildCountChip('X', '${counts['besar']}', PartyColors.love),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String emoji, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ]),
      ),
    );
  }

  Widget _buildPlayerCard(String name, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Center(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.text)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
      ],
    );
  }
}
