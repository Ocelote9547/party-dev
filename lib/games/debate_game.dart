// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';
import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';

enum _DebatePhase { setup, playing, voting, gameOver }

class DebateGame extends StatefulWidget {
  final List<String> players;
  final String? initialMode;
  const DebateGame({super.key, required this.players, this.initialMode});
  @override
  State<DebateGame> createState() => _DebateGameState();
}

class _DebateGameState extends State<DebateGame> {
  bool _showInstructions = true;
  bool _showVariationSelector = false;
  _DebatePhase _phase = _DebatePhase.setup;
  String _selectedDebateMode = 'Normal';
  int _selectedPlanIndex = 0;
  late String _currentTopic;
  String? _voteResult;
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;
  late final PageController _variationController;
  int _variationIndex = 0;
  static const _debateVariations = [
    _DebateVariation(emoji: '💬', title: 'NORMAL', description: 'Temas para discutir y reír'),
    _DebateVariation(emoji: '🌶️', title: 'PICANTE', description: 'Sin filtros'),
    _DebateVariation(emoji: '🧠', title: 'PROFUNDAS', description: 'Para pensar'),
    _DebateVariation(emoji: '📋', title: 'PLANES', description: 'Qué hacer juntos'),
  ];

  bool get _isPlanes => _selectedDebateMode == 'Planes';
  DebatePlan get _selectedPlan => GameData.debatePlanes[_selectedPlanIndex];

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  @override
  void initState() {
    super.initState();
    _variationController = PageController(viewportFraction: 0.88);
    _variationIndex = ['Normal', 'Picante', 'Profundas', 'Planes'].indexOf(_selectedDebateMode);
    if (_variationIndex < 0) _variationIndex = 0;
    try { SoundService.instance.playAmbientLoop(category: 'OPINIÓN'); } catch (_) {}
    for (final p in widget.players) {
      _scores[p] = 0;
    }
    if (widget.initialMode != null &&
        ['Normal', 'Picante', 'Profundas', 'Planes']
            .contains(widget.initialMode)) {
      _selectedDebateMode = widget.initialMode!;
      _variationIndex = ['Normal', 'Picante', 'Profundas', 'Planes'].indexOf(_selectedDebateMode);
    }
    _currentTopic = _pickRandomTopic();
  }

  @override
  void dispose() {
    _variationController.dispose();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.dispose();
  }

  @override
  void deactivate() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.deactivate();
  }

  List<String> get _currentDebatePool {
    switch (_selectedDebateMode) {
      case 'Picante':
        return GameData.debatePicanteTopics;
      case 'Profundas':
        return GameData.debateProfundasTopics;
      default:
        return GameData.debateTopics;
    }
  }

  String _pickRandomTopic() {
    if (_isPlanes) {
      final plan = GameData.randomFrom(GameData.debatePlanes);
      // keep index in sync with displayed topic when randomizing via button
      _selectedPlanIndex = GameData.debatePlanes.indexOf(plan);
      return plan.title;
    }
    final pool = _currentDebatePool;
    if (pool.isEmpty) return 'Tema libre';
    return GameData.randomFrom(pool);
  }

  void _randomizeTopic() {
    setState(() {
      if (_isPlanes) {
        final plan = GameData.randomFrom(GameData.debatePlanes);
        _selectedPlanIndex = GameData.debatePlanes.indexOf(plan);
        _currentTopic = plan.title;
      } else {
        _currentTopic = _pickRandomTopic();
      }
    });
  }

  void _selectPlan(int index) {
    setState(() {
      _selectedPlanIndex = index;
      _currentTopic = GameData.debatePlanes[index].title;
    });
  }

  void _onModeChanged(String mode) {
    if (_selectedDebateMode == mode) return;
    setState(() {
      _selectedDebateMode = mode;
      if (_isPlanes) {
        // Keep current selection (default 0) and sync topic
        _currentTopic = _selectedPlan.title;
      } else {
        _currentTopic = _pickRandomTopic();
      }
    });
  }

  void _startGameFromInstructions() {
    if (!mounted) return;
    if (widget.initialMode != null) {
      setState(() => _showInstructions = false);
    } else {
      setState(() {
        _showInstructions = false;
        _showVariationSelector = true;
      });
    }
  }

  void _onVariationComenzar() {
    final mode = ['Normal', 'Picante', 'Profundas', 'Planes'][_variationIndex];
    setState(() {
      _selectedDebateMode = mode;
      _showVariationSelector = false;
      if (_isPlanes) {
        _currentTopic = _selectedPlan.title;
      } else {
        _currentTopic = _pickRandomTopic();
      }
    });
  }

  Widget _buildVariationSelector() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('DEBATE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
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
              itemCount: _debateVariations.length,
              onPageChanged: (i) => setState(() => _variationIndex = i),
              itemBuilder: (context, index) {
                final v = _debateVariations[index];
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
            children: List.generate(_debateVariations.length, (i) {
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

  void _startDebate() {
    if (_currentTopic.isEmpty) {
      _randomizeTopic();
    }
    if (!mounted) return;
    setState(() => _phase = _DebatePhase.playing);
    try { SoundService.instance.playAmbientLoop(category: 'OPINIÓN'); } catch (_) {}
  }

  void _goToVoting() {
    if (!mounted) return;
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    setState(() => _phase = _DebatePhase.voting);
  }

  void _vote(String result) {
    if (!mounted) return;
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    setState(() {
      _voteResult = result;
      // Opcional: si no es empate, dar +1 simb��lico al marcador para persistir ranking
      // Como el debate es por bandos y no por jugador, no asignamos a nadie.
      // Pero mantenemos _scores para saveGameScores (puede quedar a 0 si empate).
      _phase = _DebatePhase.gameOver;
    });
  }

  Future<void> _goHome() async {
    await _handleGameCompleted();
    await saveGameScores(_scores);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _entrance(Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(
              opacity: value.clamp(0.0, 1.0).toDouble(), child: child),
        ),
        child: child,
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
            title: Text('Seguro que quieres salir?',
                style: TextStyle(
                    color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderas el progreso',
                style: TextStyle(color: PartyColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                      backgroundColor: PartyColors.danger),
                  child: const Text('Salir')),
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
              emoji: '🎙️',
              title: 'DEBATE',
              subtitle:
                  'Elegid un tema y defended vuestras posturas. Votad quién argumentó mejor.',
              steps: const [
                'Elegid categoria Normal o Picante.',
                'Se muestra un tema aleatorio (puedes cambiarlo).',
                'Dos voluntarios debaten: uno A FAVOR y otro EN CONTRA.',
                'Sin cronometro, hablad libremente.',
                'Votad quien gano: A favor / En contra / Empate.',
              ],
              onStart: _startGameFromInstructions,
            );
          }
          if (_showVariationSelector) return _buildVariationSelector();
          if (_phase == _DebatePhase.setup) return _buildSetup();
          if (_phase == _DebatePhase.playing) return _buildPlaying();
          if (_phase == _DebatePhase.voting) return _buildVoting();
          return _buildGameOver();
        },
      ),
    );
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('DEBATE',
              style:
                  TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _entrance(Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎙️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(_isPlanes ? 'Elige el plan' : 'Elige el tema',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: PartyColors.text)),
              const SizedBox(height: 8),
              Text(
                  _isPlanes
                      ? 'Planes para hacer juntos'
                      : 'Categoria y tema aleatorio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: PartyColors.textSecondary)),
              const SizedBox(height: 28),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Normal'),
                    selected: _selectedDebateMode == 'Normal',
                    onSelected: (v) => _onModeChanged('Normal'),
                    selectedColor: PartyColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: PartyColors.primary,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _selectedDebateMode == 'Normal'
                            ? PartyColors.primary
                            : PartyColors.text),
                    side: BorderSide(
                        color: _selectedDebateMode == 'Normal'
                            ? PartyColors.primary
                            : PartyColors.border),
                  ),
                  FilterChip(
                    label: const Text('Picante'),
                    selected: _selectedDebateMode == 'Picante',
                    onSelected: (v) => _onModeChanged('Picante'),
                    selectedColor: PartyColors.danger.withValues(alpha: 0.2),
                    checkmarkColor: PartyColors.danger,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _selectedDebateMode == 'Picante'
                            ? PartyColors.danger
                            : PartyColors.danger),
                    side: BorderSide(
                        color: _selectedDebateMode == 'Picante'
                            ? PartyColors.danger
                            : PartyColors.danger.withValues(alpha: 0.4)),
                    backgroundColor:
                        PartyColors.danger.withValues(alpha: 0.08),
                  ),
                  FilterChip(
                    label: const Text('Profundas'),
                    selected: _selectedDebateMode == 'Profundas',
                    onSelected: (v) => _onModeChanged('Profundas'),
                    selectedColor: PartyColors.purple.withValues(alpha: 0.2),
                    checkmarkColor: PartyColors.purple,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _selectedDebateMode == 'Profundas'
                            ? PartyColors.purple
                            : PartyColors.purple),
                    side: BorderSide(
                        color: _selectedDebateMode == 'Profundas'
                            ? PartyColors.purple
                            : PartyColors.purple.withValues(alpha: 0.4)),
                    backgroundColor:
                        PartyColors.purple.withValues(alpha: 0.08),
                  ),
                  FilterChip(
                    label: const Text('📋 Planes'),
                    selected: _selectedDebateMode == 'Planes',
                    onSelected: (v) => _onModeChanged('Planes'),
                    selectedColor: PartyColors.success.withValues(alpha: 0.2),
                    checkmarkColor: PartyColors.success,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _selectedDebateMode == 'Planes'
                            ? PartyColors.success
                            : PartyColors.text),
                    side: BorderSide(
                        color: _selectedDebateMode == 'Planes'
                            ? PartyColors.success
                            : PartyColors.border),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (_isPlanes)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 380),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PartyColors.success.withValues(alpha: 0.25),
                        width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: GameData.debatePlanes.length,
                          itemBuilder: (context, index) {
                            final plan = GameData.debatePlanes[index];
                            final isSelected = index == _selectedPlanIndex;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _selectPlan(index),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? PartyColors.success
                                            .withValues(alpha: 0.12)
                                        : PartyColors.background
                                            .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? PartyColors.success
                                          : PartyColors.border
                                              .withValues(alpha: 0.6),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(plan.emoji,
                                          style:
                                              const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(plan.title,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: isSelected
                                                        ? PartyColors.success
                                                        : PartyColors.text,
                                                    height: 1.3)),
                                            const SizedBox(height: 4),
                                            Text(plan.description,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: PartyColors
                                                        .textSecondary,
                                                    height: 1.3)),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                              left: 8, top: 2),
                                          child: Icon(Icons.check_circle,
                                              size: 18,
                                              color: PartyColors.success),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _randomizeTopic,
                          icon: const Icon(Icons.casino, size: 18),
                          label: const Text('Plan aleatorio',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PartyColors.success,
                            side: BorderSide(
                                color: PartyColors.success
                                    .withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: PartyColors.primary.withValues(alpha: 0.25),
                        width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(_currentTopic,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: PartyColors.text,
                              height: 1.4)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _randomizeTopic,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Otro tema',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PartyColors.primary,
                            side: BorderSide(
                                color: PartyColors.primary
                                    .withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _startDebate,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlanes
                          ? PartyColors.success
                          : PartyColors.primary,
                      foregroundColor: PartyColors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: Text(_isPlanes ? 'EMPEZAR PLAN' : 'EMPEZAR DEBATE',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('DEBATE',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      ),
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                        color: PartyColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: _isPlanes
                                ? PartyColors.success.withValues(alpha: 0.3)
                                : PartyColors.primary.withValues(alpha: 0.3),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: (_isPlanes
                                      ? PartyColors.success
                                      : PartyColors.primary)
                                  .withValues(alpha: 0.06),
                              blurRadius: 20)
                        ]),
                    child: _isPlanes
                        ? Column(
                            children: [
                              Text(_selectedPlan.emoji,
                                  style: const TextStyle(fontSize: 52)),
                              const SizedBox(height: 12),
                              Text(_selectedPlan.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: PartyColors.text,
                                      height: 1.4)),
                              const SizedBox(height: 12),
                              Text(_selectedPlan.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: PartyColors.textSecondary,
                                      height: 1.4)),
                            ],
                          )
                        : Text(_currentTopic,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: PartyColors.text,
                                height: 1.4)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      _isPlanes
                          ? 'Organizad el plan y luego votad si os mola'
                          : 'Dos voluntarios: uno defiende cada postura',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: PartyColors.textSecondary)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 72,
                          child: ElevatedButton(
                            onPressed: _goToVoting,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: PartyColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18))),
                            child: const Text('A FAVOR',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 72,
                          child: ElevatedButton(
                            onPressed: _goToVoting,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: PartyColors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18))),
                            child: const Text('EN CONTRA',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _goToVoting,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: PartyColors.primary,
                          foregroundColor: PartyColors.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('IR A VOTACIÓN',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _goHome,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: PartyColors.textSecondary,
                          side: BorderSide(color: PartyColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('SALIR',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoting() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('VOTACIÓN',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗳️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('¿Quién ganó?',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: PartyColors.text)),
              const SizedBox(height: 8),
              Text(_currentTopic,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: PartyColors.textSecondary)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: () => _vote('A favor'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  child: const Text('A FAVOR',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: () => _vote('En contra'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  child: const Text('EN CONTRA',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: () => _vote('Empate'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.surface,
                      foregroundColor: PartyColors.text,
                      side: BorderSide(color: PartyColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  child: const Text('EMPATE',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final sorted = _scores.keys.toList()
      ..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    final hasScores = widget.players.isNotEmpty;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _entrance(Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 18),
                Text('RESULTADOS',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: PartyColors.text,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                if (_voteResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _voteResult == 'Empate'
                          ? PartyColors.surface
                          : PartyColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _voteResult == 'Empate'
                              ? PartyColors.border
                              : PartyColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _voteResult == 'Empate'
                          ? 'Empate'
                          : 'Gana: $_voteResult',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _voteResult == 'Empate'
                              ? PartyColors.textSecondary
                              : PartyColors.primary),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(_currentTopic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: PartyColors.textSecondary)),
                const SizedBox(height: 28),
                if (hasScores)
                  for (final p in sorted)
                    _buildRankingRow(p, sorted.indexOf(p))
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PartyColors.border),
                    ),
                    child: Text(
                      _voteResult == null
                          ? 'Debate finalizado'
                          : 'Resultado: $_voteResult',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PartyColors.text),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _goHome,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('VOLVER',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                  ),
                ),
              ],
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingRow(String player, int rank) {
    final isWinner = rank == 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isWinner
            ? PartyColors.primary.withValues(alpha: 0.08)
            : PartyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isWinner
                ? PartyColors.primary.withValues(alpha: 0.4)
                : PartyColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
                rank < 3 ? ['🥇', '🥈', '🥉'][rank] : '${rank + 1}.',
                style: TextStyle(
                    fontSize: rank < 3 ? 18 : 15,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.textSecondary)),
          ),
          Expanded(
            child: Text(player,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PartyColors.text),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${_scores[player] ?? 0}',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: PartyColors.primary)),
        ],
      ),
    );
  }
}

class _DebateVariation {
  final String emoji;
  final String title;
  final String description;
  const _DebateVariation({required this.emoji, required this.title, required this.description});
}
