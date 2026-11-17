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

class _RoundResult {
  final String infiltrator;
  final String votedPlayer;
  final bool groupCorrect;
  final String commonMaskName;
  final String commonMaskEmoji;
  final String infiltratorMaskEmoji;
  final bool infiltratorGuessedCorrect;

  _RoundResult({
    required this.infiltrator,
    required this.votedPlayer,
    required this.groupCorrect,
    required this.commonMaskName,
    required this.commonMaskEmoji,
    required this.infiltratorMaskEmoji,
    required this.infiltratorGuessedCorrect,
  });
}

class MascaraInfiltradaGame extends StatefulWidget {
  final List<String> players;
  const MascaraInfiltradaGame({super.key, required this.players});

  @override
  State<MascaraInfiltradaGame> createState() => _MascaraInfiltradaGameState();
}

class _MascaraInfiltradaGameState extends State<MascaraInfiltradaGame> {
  bool _showInstructions = true;
  bool _showSetup = true;

  int _totalRounds = 3;
  int _currentRound = 0;

  late List<String> _shuffledPlayers;
  late int _infiltratorIndex;

  late String _commonMaskEmoji;
  late String _commonMaskName;
  late String _infiltratorMaskEmoji;
  late String _infiltratorMaskName;

  int _currentPlayerIndex = 0;
  bool _showingMask = false;
  bool _revealDone = false;

  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }
  final List<_RoundResult> _roundResults = [];
  late List<_MaskPair> _availablePairs;

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'MENTIRA'); } catch (_) {}
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    _preparePairs();
    _shuffledPlayers = List.from(widget.players)..shuffle();
    _infiltratorIndex = safeRandomIndex(_shuffledPlayers.length);
    _pickNewMasks();
  }

  void _preparePairs() {
    final allMascara = GameData.mascaras;
    final shuffled = List.generate(allMascara.length, (i) => i)..shuffle();
    _availablePairs = [];
    for (var i = 0; i < shuffled.length - 1; i += 2) {
      _availablePairs.add(_MaskPair(
        mask1Emoji: allMascara[shuffled[i]].emoji,
        mask1Name: allMascara[shuffled[i]].name,
        mask2Emoji: allMascara[shuffled[i + 1]].emoji,
        mask2Name: allMascara[shuffled[i + 1]].name,
      ));
    }
    _availablePairs.shuffle();
  }

  void _pickNewMasks() {
    if (_availablePairs.isEmpty) {
      _preparePairs();
    }
    final pair = _availablePairs.removeLast();
    final assignCommonFirst = Random().nextBool();
    if (assignCommonFirst) {
      _commonMaskEmoji = pair.mask1Emoji;
      _commonMaskName = pair.mask1Name;
      _infiltratorMaskEmoji = pair.mask2Emoji;
      _infiltratorMaskName = pair.mask2Name;
    } else {
      _commonMaskEmoji = pair.mask2Emoji;
      _commonMaskName = pair.mask2Name;
      _infiltratorMaskEmoji = pair.mask1Emoji;
      _infiltratorMaskName = pair.mask1Name;
    }
  }

  String get _currentPlayer => _shuffledPlayers[_currentPlayerIndex];
  bool get _isInfiltrator => _currentPlayerIndex == _infiltratorIndex;

  void _startGame() => setState(() {
        _showInstructions = false;
      });

  void _confirmRounds(int count) => setState(() {
        _totalRounds = count;
        _showSetup = false;
      });

  void _revealMask() => setState(() => _showingMask = true);

  void _nextPlayer() {
    setState(() {
      _showingMask = false;
      _currentPlayerIndex++;
      if (_currentPlayerIndex >= _shuffledPlayers.length) {
        _revealDone = true;
      }
    });
  }

  void _showVoteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PartyColors.border),
        ),
        title: Text(
          '¿Quién tiene la máscara distinta?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: PartyColors.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _shuffledPlayers.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _showResult(p);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.text,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResult(String votedPlayer) {
    final realInfiltrator = _shuffledPlayers[_infiltratorIndex];
    final wasInfiltrator = votedPlayer == realInfiltrator;

    if (wasInfiltrator) {
      _showLastChanceDialog(realInfiltrator);
    } else {
      _resolveRound(realInfiltrator, votedPlayer, false);
    }
  }

  void _showLastChanceDialog(String realInfiltrator) {
    final allMasks = GameData.mascaras;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PartyColors.border),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PartyColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 48,
                  color: PartyColors.warning,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Última oportunidad',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El infiltrado debe adivinar cuál era la máscara REAL (la común).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: PartyColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: allMasks.length,
                  itemBuilder: (_, i) {
                    final m = allMasks[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        final correct = m.name == _commonMaskName;
                        _resolveRound(realInfiltrator, realInfiltrator, correct);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: PartyColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PartyColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              m.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: PartyColors.text,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _resolveRound(realInfiltrator, realInfiltrator, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.textMuted,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'PASAR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resolveRound(
    String realInfiltrator,
    String votedPlayer,
    bool infiltratorGuessedCorrect,
  ) {
    final groupCorrect = votedPlayer == realInfiltrator;
    final hasMoreRounds = _currentRound + 1 < _totalRounds;

    final result = _RoundResult(
      infiltrator: realInfiltrator,
      votedPlayer: votedPlayer,
      groupCorrect: groupCorrect,
      commonMaskName: _commonMaskName,
      commonMaskEmoji: _commonMaskEmoji,
      infiltratorMaskEmoji: _infiltratorMaskEmoji,
      infiltratorGuessedCorrect: infiltratorGuessedCorrect,
    );
    _roundResults.add(result);

    setState(() {
      if (groupCorrect && !infiltratorGuessedCorrect) {
        for (final p in widget.players) {
          if (p != realInfiltrator) {
            _scores[p] = (_scores[p] ?? 0) + 1;
          }
        }
      } else {
        _scores[realInfiltrator] = (_scores[realInfiltrator] ?? 0) + 2;
      }
    });

    final villagersWon = groupCorrect && !infiltratorGuessedCorrect;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PartyColors.border),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                villagersWon ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 72,
                color: villagersWon ? PartyColors.primary : PartyColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                villagersWon ? '¡Correcto!' : '¡Incorrecto!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: villagersWon
                      ? PartyColors.primary
                      : PartyColors.danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$realInfiltrator era el infiltrado',
                style: TextStyle(
                  fontSize: 14,
                  color: PartyColors.textSecondary,
                ),
              ),
              if (groupCorrect) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: infiltratorGuessedCorrect
                        ? PartyColors.danger.withValues(alpha: 0.1)
                        : PartyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: infiltratorGuessedCorrect
                          ? PartyColors.danger.withValues(alpha: 0.3)
                          : PartyColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    infiltratorGuessedCorrect
                        ? '¡El infiltrado adivinó la máscara! Gana el infiltrado'
                        : '¡El infiltrado falló! Ganan los demás',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: infiltratorGuessedCorrect
                          ? PartyColors.danger
                          : PartyColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PartyColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Real: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: PartyColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_commonMaskEmoji $_commonMaskName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PartyColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Infiltrado: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: PartyColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_infiltratorMaskEmoji $_infiltratorMaskName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (villagersWon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: PartyColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Grupo +1 punto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PartyColors.primary,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: PartyColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: PartyColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Infiltrado +2 puntos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PartyColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _buildScoresRow(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (hasMoreRounds) {
                      _nextRound();
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _GameOverScreen(
                            roundResults: _roundResults,
                            scores: Map.from(_scores),
                            players: widget.players,
                            onVolver: () async {
                              await _handleGameCompleted();
                              await saveGameScores(Map.from(_scores));
                            },
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    hasMoreRounds
                        ? 'RONDA ${_currentRound + 2}/$_totalRounds'
                        : 'VER RESULTADOS',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.textMuted,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _currentPlayerIndex = 0;
      _showingMask = false;
      _revealDone = false;
      _pickNewMasks();
      _shuffledPlayers = List.from(widget.players)..shuffle();
      _infiltratorIndex = safeRandomIndex(_shuffledPlayers.length);
    });
  }

  Widget _buildScoresRow() {
    final sorted = widget.players.toList()
      ..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PartyColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARCADOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: PartyColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ...sorted.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PartyColors.text,
                      ),
                    ),
                    Text(
                      '${_scores[p] ?? 0}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
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
        emoji: '🎭',
        title: 'LA MÁSCARA INFILTRADA',
        subtitle: 'Descubre quién tiene una máscara diferente a la tuya.',
        steps: [
          'Todos reciben la misma máscara. Uno recibe una diferente sin saberlo.',
          'Pasa el móvil y mira tu máscara en secreto.',
          '¿Quién cree que tiene la máscara distinta?',
          'Votad al sospechoso. Si acertáis, el infiltrado tiene una última oportunidad.',
          'Si adivina la máscara real, gana el infiltrado (+2). Si falla, ganan los demás (+1).',
          'Si no acertáis, gana el infiltrado (+2 puntos).',
          '$_totalRounds rondas con máscaras distintas. ¡El que más puntos tenga gana!',
        ],
        onStart: _startGame,
      );
    }
    if (_showSetup) return _buildSetupScreen();
    if (!_revealDone) return _buildRevealPhase();
    return _buildVotingScreen();
  
        },
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎭', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  '¿CUÁNTAS PARTIDAS?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: PartyColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cada partida usa una pareja de máscaras distinta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: PartyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ...[1, 3, 5, 10].map((count) {
                  final isSelected = count == _totalRounds;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => _confirmRounds(count),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? PartyColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          foregroundColor: PartyColors.text,
                          side: BorderSide(
                            color: isSelected
                                ? PartyColors.primary
                                : PartyColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '$count PARTIDA${count > 1 ? 'S' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: isSelected
                                ? PartyColors.primary
                                : PartyColors.text,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealPhase() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RONDA ${_currentRound + 1}/$_totalRounds',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: PartyColors.text,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: PartyColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _currentPlayer.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: PartyColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pasa el móvil para ver tu máscara',
                style:
                    TextStyle(fontSize: 14, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 40),
              if (!_showingMask)
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _revealMask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'TAP PARA VER TU MÁSCARA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: PartyColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tu máscara es',
                        style: TextStyle(
                            fontSize: 14,
                            color: PartyColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isInfiltrator ? _infiltratorMaskEmoji : _commonMaskEmoji,
                        style: const TextStyle(fontSize: 72),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isInfiltrator ? _infiltratorMaskName : _commonMaskName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: PartyColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.surface,
                      foregroundColor: PartyColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: PartyColors.border),
                      ),
                    ),
                    child: Text(
                      _currentPlayerIndex < _shuffledPlayers.length - 1
                          ? 'SIGUIENTE JUGADOR'
                          : 'TODOS HAN VISTO SU MÁSCARA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingScreen() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RONDA ${_currentRound + 1}/$_totalRounds',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: PartyColors.text,
          ),
        ),
      ),
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.how_to_vote_outlined,
                  size: 64, color: PartyColors.primary),
              const SizedBox(height: 24),
              Text(
                '¡A votar!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Discutid entre vosotros y decidid.\n¿Quién creéis que tiene la máscara distinta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _showVoteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'VOTAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartyColors.text,
                    side: BorderSide(color: PartyColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1),
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

class _MaskPair {
  final String mask1Emoji;
  final String mask1Name;
  final String mask2Emoji;
  final String mask2Name;

  const _MaskPair({
    required this.mask1Emoji,
    required this.mask1Name,
    required this.mask2Emoji,
    required this.mask2Name,
  });
}

class _GameOverScreen extends StatelessWidget {
  final List<_RoundResult> roundResults;
  final Map<String, int> scores;
  final List<String> players;
  final Future<void> Function() onVolver;

  const _GameOverScreen({
    required this.roundResults,
    required this.scores,
    required this.players,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = players.toList()
      ..sort((a, b) => (scores[b] ?? 0).compareTo((scores[a] ?? 0)));
    final winner = sorted.first;
    final winnerScore = scores[winner] ?? 0;
    final isTie = sorted.length > 1 && (scores[sorted[1]] ?? 0) == winnerScore;

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'RESULTADOS',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: PartyColors.text),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                isTie ? '¡EMPATE!' : winner.toUpperCase(),
                style: TextStyle(
                  fontSize: isTie ? 24 : 28,
                  fontWeight: FontWeight.w900,
                  color: isTie ? PartyColors.primary : PartyColors.text,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isTie
                    ? 'Varios jugadores empatan con $winnerScore puntos'
                    : '$winnerScore punto${winnerScore == 1 ? '' : 's'}',
                style:
                    const TextStyle(fontSize: 15, color: PartyColors.primary),
              ),
              const SizedBox(height: 28),
              ...List.generate(roundResults.length, (i) {
                final r = roundResults[i];
                final groupWon =
                    r.groupCorrect && !r.infiltratorGuessedCorrect;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: groupWon
                          ? PartyColors.primary.withValues(alpha: 0.3)
                          : PartyColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'RONDA ${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: PartyColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            groupWon
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 18,
                            color: groupWon
                                ? PartyColors.primary
                                : PartyColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            groupWon ? 'GRUPO GANA' : 'INFILTRADO GANA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: groupWon
                                  ? PartyColors.primary
                                  : PartyColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _infoChip('Infiltrado', r.infiltrator),
                          const SizedBox(width: 8),
                          _infoChip('Votaron a', r.votedPlayer),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${r.commonMaskEmoji} Real: ${r.commonMaskName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PartyColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${r.infiltratorMaskEmoji} Infiltrado: ${GameData.mascaras.firstWhere((m) => m.emoji == r.infiltratorMaskEmoji).name}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PartyColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text(
                'MARCADOR FINAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: PartyColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...sorted.map((p) => Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: p == winner && !isTie
                            ? Colors.amber.withValues(alpha: 0.5)
                            : PartyColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (p == winner && !isTie)
                          const Icon(Icons.emoji_events,
                              size: 22, color: Colors.amber),
                        if (p == winner && !isTie) const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: p == winner && !isTie
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: PartyColors.text,
                            ),
                          ),
                        ),
                        Text(
                          '${scores[p] ?? 0}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: p == winner && !isTie
                                ? Colors.amber
                                : PartyColors.primary,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await onVolver();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'VOLVER',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PartyColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style:
                    TextStyle(fontSize: 11, color: PartyColors.textMuted),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PartyColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}