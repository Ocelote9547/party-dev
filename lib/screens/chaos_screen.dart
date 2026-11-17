import 'dart:async';

import 'package:flutter/material.dart';

import '../games/adivina_game.dart';
import '../games/alienigena_game.dart';
import '../games/angeles_demonios_game.dart';
import '../games/apt_coreano_game.dart';
import '../games/bomba_game.dart';
import '../games/debate_game.dart';
import '../games/dibuja_y_adivina_game.dart';
import '../games/ensalada_game.dart';
import '../games/es_un_10_game.dart';
import '../games/espia_game.dart';
import '../games/impostor_game.dart';
import '../games/mascara_infiltrada_game.dart';
import '../games/matar_casar_besar_game.dart';
import '../games/mimica_game.dart';
import '../games/pueblo_duerme_game.dart';
import '../games/quien_es_mas_game.dart';
import '../games/quien_soy_game.dart';
import '../games/secretos_game.dart';
import '../games/tabu_game.dart';
import '../games/verdad_o_reto_game.dart';
import '../games/yo_nunca_equipos_game.dart';
import '../games/yo_nunca_game.dart';
import '../games/yo_nunca_lobo_game.dart';
import '../games/yo_tengo_un_amigo_game.dart';
import '../services/chaos_service.dart';
import '../theme/party_theme.dart';
import 'leaderboard_screen.dart';

class ChaosScreen extends StatefulWidget {
  final List<String> players;
  const ChaosScreen({super.key, required this.players});

  @override
  State<ChaosScreen> createState() => _ChaosScreenState();
}

class _ChaosScreenState extends State<ChaosScreen> with SingleTickerProviderStateMixin {
  List<ChaosQueueItem> _queue = [];
  int _index = 0;
  bool _loading = true;
  bool _revealing = false;
  late AnimationController _revealController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _revealController, curve: Curves.easeIn);
    _initQueue();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _initQueue() async {
    final loaded = await ChaosService.instance.loadQueue();
    if (!mounted) return;
    if (loaded.length == 5) {
      setState(() {
        _queue = loaded;
        _loading = false;
      });
    } else {
      final generated = await ChaosService.instance.generateQueue();
      if (!mounted) return;
      setState(() {
        _queue = generated;
        _loading = false;
      });
    }
  }

  Future<void> _regenerate() async {
    setState(() => _loading = true);
    final generated = await ChaosService.instance.generateQueue();
    if (!mounted) return;
    setState(() {
      _queue = generated;
      _index = 0;
      _loading = false;
      _revealing = false;
    });
    _revealController.reset();
  }

  Widget? _getGameWidget(ChaosQueueItem item) {
    final title = item.title;
    // Reusar la lógica de games_screen: mapear por título normalizado.
    switch (title) {
      case 'IMPOSTOR':
        return ImpostorGame(players: widget.players);
      case 'PUEBLO DUERME':
        return PuebloDuermeGame(players: widget.players);
      case 'ADIVINA':
        return AdivinaGame(players: widget.players);
      case 'ES UN 10 PERO...':
        return EsUn10Game(players: widget.players);
      case 'DEBATE':
        return DebateGame(players: widget.players);
      case 'QUIÉN ES MÁS':
        return QuienEsMasGame(players: widget.players);
      case 'TABÚ':
        return TabuGame(players: widget.players);
      case 'YO NUNCA':
        return YoNuncaGame(players: widget.players);
      case 'MÍMICA':
        return MimicaGame(players: widget.players);
      case '¿QUIÉN SOY?':
        return QuienSoyGame(players: widget.players);
      case '¿QUIÉN ES EL ESPIA?':
        return EspiaGame(players: widget.players);
      case 'VERDAD O RETO':
        return VerdadORetoGame(players: widget.players);
      case 'MATAR, CASAR, BESAR':
        return MatarCasarBesarGame(players: widget.players);
      case 'SECRETOS':
        return SecretosGame(players: widget.players);
      case 'LA MÁSCARA INFILTRADA':
        return MascaraInfiltradaGame(players: widget.players);
      case 'DIBUJA Y ADIVINA':
        return DibujaYadivinaGame(players: widget.players);
      case 'BOMBA':
        return BombaGame(players: widget.players);
      case 'LA ENSALADA':
        return EnsaladaGame(players: widget.players);
      case 'ALIENÍGENA':
        return AlienigenaGame(players: widget.players);
      case 'YO TENGO UN AMIGO':
        return YoTengoUnAmigoGame(players: widget.players);
      case 'YO NUNCA EQUIPOS':
        return YoNuncaEquiposGame(players: widget.players);
      case 'APT COREANO':
        return AptCoreanoGame(players: widget.players);
      case 'YO NUNCA LOBO':
        return YoNuncaLoboGame(players: widget.players);
      case 'ANGELES Y DEMONIOS':
        return AngelesDemoniosGame(players: widget.players);
      default:
        return null;
    }
  }

  Future<void> _onNextPressed() async {
    if (_queue.isEmpty) return;

    // Si estamos en el último juego, ir a ranking total.
    if (_index >= _queue.length - 1) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LeaderboardScreen(players: widget.players)),
      );
      return;
    }

    // Animación de revelado del siguiente juego.
    setState(() => _revealing = true);
    await _revealController.forward();

    if (!mounted) return;
    final nextItem = _queue[_index + 1];
    final nextGame = _getGameWidget(nextItem);

    // Pequeña pausa para que se vea la revelación.
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    if (nextGame != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => nextGame));
    }

    if (!mounted) return;
    // Avanzar índice tras volver del juego.
    setState(() {
      _index++;
      _revealing = false;
    });
    _revealController.reset();

    // Si acabamos de terminar el último (índice ahora es último y veníamos de penúltimo),
    // el siguiente tap llevará al ranking. No auto-navegar aquí;
    // el usuario pulsará de nuevo "VER RANKING".
  }

  Future<void> _onPlayCurrent() async {
    if (_queue.isEmpty) return;
    final current = _queue[_index];
    final game = _getGameWidget(current);
    if (game == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => game));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudo generar cola', style: TextStyle(color: PartyColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _regenerate, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final isFinished = _index >= _queue.length;
    final current = isFinished ? null : _queue[_index];
    final next = (_index + 1 < _queue.length) ? _queue[_index + 1] : null;
    final isLast = _index == _queue.length - 1;
    final progress = (_index + 1).clamp(1, _queue.length);

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('🔥 MODO CAOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            tooltip: 'Regenerar',
            onPressed: _regenerate,
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: PartyColors.scaffoldGradient.take(3).toList(),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtítulo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PartyColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No sabes qué juego viene después',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: PartyColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Progreso 1/5
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PROGRESO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: PartyColors.textMuted)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: PartyColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PartyColors.border),
                      ),
                      child: Text('$progress / ${_queue.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: PartyColors.text)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress / _queue.length,
                    minHeight: 8,
                    backgroundColor: PartyColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(PartyColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_queue.length, (i) {
                    final active = i <= _index;
                    final isCurrent = i == _index;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i == _queue.length - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: active ? (isCurrent ? PartyColors.primary : PartyColors.primary.withValues(alpha: 0.55)) : PartyColors.border,
                          border: isCurrent ? Border.all(color: PartyColors.primary, width: 1) : null,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),

                if (isFinished) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 10),
                        Text('¡CAOS COMPLETADO!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: PartyColors.text)),
                        const SizedBox(height: 8),
                        Text('Has jugado 5 juegos aleatorios', style: TextStyle(fontSize: 13, color: PartyColors.textSecondary)),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(players: widget.players)));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PartyColors.primary,
                            foregroundColor: PartyColors.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.emoji_events_rounded),
                          label: const Text('VER RANKING TOTAL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _regenerate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PartyColors.text,
                            side: BorderSide(color: PartyColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('🔥 JUGAR OTRO CAOS', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Juego actual grande
                  GestureDetector(
                    onTap: _onPlayCurrent,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: PartyColors.surface,
                        border: Border.all(color: PartyColors.primary.withValues(alpha: 0.35), width: 1.2),
                        boxShadow: [BoxShadow(color: PartyColors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PartyColors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: PartyColors.primary.withValues(alpha: 0.22)),
                                ),
                                child: Text('JUEGO $progress', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: PartyColors.primary)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: PartyColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: PartyColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14, color: PartyColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(current!.durationLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: PartyColors.primary.withValues(alpha: 0.06),
                              border: Border.all(color: PartyColors.primary.withValues(alpha: 0.18)),
                            ),
                            child: Center(child: Text(current.emoji, style: const TextStyle(fontSize: 56))),
                          ),
                          const SizedBox(height: 14),
                          Text(current.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: PartyColors.primary)),
                          const SizedBox(height: 6),
                          Text(
                            current.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1, color: PartyColors.text, height: 1.1),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: PartyColors.scaffoldGradient.last.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: PartyColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.style_outlined, size: 14, color: PartyColors.textMuted),
                                const SizedBox(width: 6),
                                Text(current.mode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.text)),
                                const SizedBox(width: 8),
                                Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: PartyColors.textMuted)),
                                const SizedBox(width: 8),
                                Text(current.durationLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('Toca para jugar este juego', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Siguiente juego (oculto / revelado)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _revealing && next != null
                        ? ScaleTransition(
                            key: ValueKey('reveal-${next.id}'),
                            scale: _scaleAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PartyColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: PartyColors.primary.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: PartyColors.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: PartyColors.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Center(child: Text(next.emoji, style: const TextStyle(fontSize: 28))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('SIGUIENTE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: PartyColors.primary)),
                                          const SizedBox(height: 2),
                                          Text(next.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.text)),
                                          Text('${next.mode} • ${next.durationLabel}', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.auto_awesome, color: PartyColors.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            key: const ValueKey('hidden'),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: PartyColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: PartyColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: PartyColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: PartyColors.border),
                                  ),
                                  child: const Center(child: Text('❓', style: TextStyle(fontSize: 26))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('SIGUIENTE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: PartyColors.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(next == null ? '¡Último juego!' : 'MISTERIO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PartyColors.text)),
                                      Text(next == null ? 'Pulsa para ver ranking' : 'Se revelará al pulsar', style: TextStyle(fontSize: 11, color: PartyColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.lock_outline, color: PartyColors.textMuted, size: 20),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 22),

                  // Botón SIGUIENTE
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _onNextPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'VER RANKING TOTAL  🏆' : 'SIGUIENTE  →',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mini lista de cola
                  Text('COLA CAOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: PartyColors.textMuted)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _queue.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final item = _queue[i];
                        final isActive = i == _index;
                        final isPast = i < _index;
                        return Container(
                          width: 72,
                          decoration: BoxDecoration(
                            color: isActive ? PartyColors.primary.withValues(alpha: 0.12) : PartyColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isActive ? PartyColors.primary.withValues(alpha: 0.5) : PartyColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isPast ? '✓' : item.emoji,
                                style: TextStyle(fontSize: isPast ? 18 : 22, color: isPast ? PartyColors.success : null),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${i + 1}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? PartyColors.primary : PartyColors.textMuted),
                              ),
                              Text(
                                isPast || isActive ? item.title.split(' ').first : '???',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: PartyColors.textMuted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
