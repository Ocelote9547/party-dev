import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/party_theme.dart';

/// Resultado que la ruleta elige. Reutilizado por [RouletteScreen].
class RouletteResult {
  final String title;
  final String emoji;
  final String category;
  final String mode;
  final String duration;
  final String? difficulty;
  final int minPlayers;

  const RouletteResult({
    required this.title,
    required this.emoji,
    required this.category,
    required this.mode,
    required this.duration,
    this.difficulty,
    this.minPlayers = 2,
  });
}

/// Widget de ruleta/slot con 3 columnas que giran.
/// Usa [AnimationController] + [Tween] por columna con easing y tick sonoro.
class RouletteWidget extends StatefulWidget {
  final bool isSpinning;
  final RouletteResult? result;
  final VoidCallback? onFinished;

  /// Opciones visibles mientras gira (fallback si no hay resultado aún).
  final List<String> gameOptions;
  final List<String> modeOptions;
  final List<String> durationOptions;

  const RouletteWidget({
    super.key,
    required this.isSpinning,
    this.result,
    this.onFinished,
    this.gameOptions = const ['IMPOSTOR', 'TABÚ', 'MÍMICA', 'ADIVINA'],
    this.modeOptions = const ['Normal', 'Picante', 'Planes', 'Profundas'],
    this.durationOptions = const ['3 rondas', '5 rondas', '7 rondas'],
  });

  @override
  State<RouletteWidget> createState() => _RouletteWidgetState();
}

class _RouletteWidgetState extends State<RouletteWidget>
    with TickerProviderStateMixin {
  late final AnimationController _c1;
  late final AnimationController _c2;
  late final AnimationController _c3;

  late Animation<double> _a1;
  late Animation<double> _a2;
  late Animation<double> _a3;

  // Para tick por cambio de índice.
  int _lastIdx1 = -1;
  int _lastIdx2 = -1;
  int _lastIdx3 = -1;

  // Offsets objetivo (índice + vueltas).
  double _target1 = 0;
  double _target2 = 0;
  double _target3 = 0;

  bool _wasSpinning = false;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _c2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2650),
    );
    _c3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3100),
    );

    // Tweens iniciales vacíos (0->0) hasta que haya result.
    _a1 = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _c1, curve: Curves.easeOutCubic),
    );
    _a2 = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _c2, curve: Curves.easeOutCubic),
    );
    _a3 = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _c3, curve: Curves.easeOutCubic),
    );

    _c1.addListener(_onTick1);
    _c2.addListener(_onTick2);
    _c3.addListener(_onTick3);
    _c3.addStatusListener(_onC3Status);
  }

  @override
  void didUpdateWidget(covariant RouletteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !_wasSpinning) {
      _startSpin();
    }
    if (!widget.isSpinning && _wasSpinning) {
      // cancel si se resetea
      _c1.stop();
      _c2.stop();
      _c3.stop();
    }
    _wasSpinning = widget.isSpinning;
  }

  @override
  void dispose() {
    _c1.removeListener(_onTick1);
    _c2.removeListener(_onTick2);
    _c3.removeListener(_onTick3);
    _c3.removeStatusListener(_onC3Status);
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  void _onC3Status(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onFinished?.call();
    }
  }

  void _onTick1() {
    final items = _gameItems;
    if (items.isEmpty) return;
    final cur = (_a1.value % items.length).floor();
    if (cur != _lastIdx1) {
      _lastIdx1 = cur;
      // Tick sonoro por cambio de casilla.
      SoundService.instance.playTick();
    }
  }

  void _onTick2() {
    final items = _modeItems;
    if (items.isEmpty) return;
    final cur = (_a2.value % items.length).floor();
    if (cur != _lastIdx2) {
      _lastIdx2 = cur;
      SoundService.instance.playTick();
    }
  }

  void _onTick3() {
    final items = _durationItems;
    if (items.isEmpty) return;
    final cur = (_a3.value % items.length).floor();
    if (cur != _lastIdx3) {
      _lastIdx3 = cur;
      SoundService.instance.playTick();
    }
  }

  List<String> get _gameItems {
    if (widget.gameOptions.isNotEmpty) return widget.gameOptions;
    return const ['IMPOSTOR', 'TABÚ', 'MÍMICA'];
  }

  List<String> get _modeItems => widget.modeOptions;
  List<String> get _durationItems => widget.durationOptions;

  int _indexForGame(String title) {
    final items = _gameItems;
    final idx = items.indexWhere((e) => e.toUpperCase() == title.toUpperCase());
    return idx >= 0 ? idx : 0;
  }

  int _indexForMode(String mode) {
    final items = _modeItems;
    final idx = items.indexWhere((e) => e.toLowerCase() == mode.toLowerCase());
    if (idx >= 0) return idx;
    // fallback fuzzy: buscar contains
    for (int i = 0; i < items.length; i++) {
      if (mode.toLowerCase().contains(items[i].toLowerCase()) ||
          items[i].toLowerCase().contains(mode.toLowerCase())) {
        return i;
      }
    }
    return 0;
  }

  int _indexForDuration(String dur) {
    final items = _durationItems;
    final idx = items.indexWhere((e) => e.toLowerCase() == dur.toLowerCase());
    if (idx >= 0) return idx;
    for (int i = 0; i < items.length; i++) {
      if (dur.toLowerCase().contains(items[i].toLowerCase())) return i;
    }
    return 0;
  }

  void _startSpin() {
    final res = widget.result;
    // Si no hay resultado aún, usar índices aleatorios pero animar igual.
    final gIdx = res != null ? _indexForGame(res.title) : 0;
    final mIdx = res != null ? _indexForMode(res.mode) : 1;
    final dIdx = res != null ? _indexForDuration(res.duration) : 2;

    const spins1 = 18;
    const spins2 = 22;
    const spins3 = 26;

    _target1 = (spins1 * _gameItems.length + gIdx).toDouble();
    _target2 = (spins2 * _modeItems.length + mIdx).toDouble();
    _target3 = (spins3 * _durationItems.length + dIdx).toDouble();

    _lastIdx1 = -1;
    _lastIdx2 = -1;
    _lastIdx3 = -1;

    _a1 = Tween<double>(begin: 0, end: _target1).animate(
      CurvedAnimation(parent: _c1, curve: Curves.easeOutCubic),
    );
    _a2 = Tween<double>(begin: 0, end: _target2).animate(
      CurvedAnimation(parent: _c2, curve: Curves.easeOutCubic),
    );
    _a3 = Tween<double>(begin: 0, end: _target3).animate(
      CurvedAnimation(parent: _c3, curve: Curves.easeOutCubic),
    );

    _c1
      ..reset()
      ..forward();
    _c2
      ..reset()
      ..forward();
    _c3
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ReelColumn(controller: _c1, animation: _a1, items: _gameItems, label: 'JUEGO', isSpinning: widget.isSpinning, resultLabel: widget.result?.title)),
        const SizedBox(width: 10),
        Expanded(child: _ReelColumn(controller: _c2, animation: _a2, items: _modeItems, label: 'MODO', isSpinning: widget.isSpinning, resultLabel: widget.result?.mode)),
        const SizedBox(width: 10),
        Expanded(child: _ReelColumn(controller: _c3, animation: _a3, items: _durationItems, label: 'DURACIÓN', isSpinning: widget.isSpinning, resultLabel: widget.result?.duration)),
      ],
    );
  }
}

class _ReelColumn extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> animation;
  final List<String> items;
  final String label;
  final bool isSpinning;
  final String? resultLabel;

  const _ReelColumn({
    required this.controller,
    required this.animation,
    required this.items,
    required this.label,
    required this.isSpinning,
    this.resultLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: PartyColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 132,
          decoration: BoxDecoration(
            color: PartyColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PartyColors.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: PartyColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Fondo sutil volcán
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PartyColors.primary.withValues(alpha: 0.06),
                          Colors.transparent,
                          PartyColors.primary.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
                // Contenido animado
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final String display;
                    if (!isSpinning && resultLabel != null) {
                      display = resultLabel!;
                    } else if (isSpinning || controller.isAnimating) {
                      if (items.isEmpty) {
                        display = '—';
                      } else {
                        final idx = (animation.value % items.length).floor().clamp(0, items.length - 1);
                        display = items[idx];
                      }
                    } else {
                      display = resultLabel ?? (items.isNotEmpty ? items.first : '—');
                    }
                    final t = controller.value / (controller.upperBound == 0 ? 1 : controller.upperBound);
                    final scale = isSpinning ? 1.0 + 0.04 * (1 - t).clamp(0, 1) : 1.0;
                    return Center(
                      child: Transform.scale(
                        scale: scale,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            display,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: PartyColors.text,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Ventana central destacada
                Center(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PartyColors.primary.withValues(alpha: 0.22),
                      ),
                      color: PartyColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Degradados superior/inferior para efecto slot
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PartyColors.surface.withValues(alpha: 0.95),
                          PartyColors.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          PartyColors.surface.withValues(alpha: 0.95),
                          PartyColors.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
