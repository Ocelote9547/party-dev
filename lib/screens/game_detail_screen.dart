import 'package:flutter/material.dart';

import '../data/game_config.dart';
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
import '../games/dos_palabras_game.dart';
import '../games/yo_nunca_equipos_game.dart';
import '../games/yo_nunca_game.dart';
import '../games/yo_nunca_lobo_game.dart';
import '../games/yo_tengo_un_amigo_game.dart';
import '../services/economy_service.dart';
import '../theme/party_theme.dart';
import '../widgets/game_family_pager.dart';

/// Pantalla detalle TikTok para familias de juegos.
///
/// Muestra un [PageView] vertical (estilo TikTok) con cada variación de
/// la familia ocupando casi toda la pantalla. Cada página tiene emoji
/// grande, título, descripción, minPlayers y precio si está bloqueado.
/// Abajo hay un botón fijo "COMENZAR" que navega al juego correcto.
/// Arriba hay indicador de puntos.
class GameDetailScreen extends StatefulWidget {
  final String familyName;
  final String category;
  final List<PagerGameData> variations;
  final List<String> players;
  final int initialIndex;

  const GameDetailScreen({
    super.key,
    required this.familyName,
    required this.category,
    required this.variations,
    required this.players,
    this.initialIndex = 0,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late final PageController _pageController;
  late int _current;
  Set<String> _unlocked = {};
  Set<String> _favorites = {};
  int _coins = 0;
  bool _economyLoaded = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.variations.length - 1);
    _pageController = PageController(initialPage: _current);
    _loadEconomy();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEconomy() async {
    final unlocked = await EconomyService.instance.getUnlockedGames();
    final coins = await EconomyService.instance.getCoins();
    final fav = await EconomyService.instance.getFavoriteGames();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked;
      _coins = coins;
      _favorites = fav;
      _economyLoaded = true;
    });
  }

  bool _isUnlocked(PagerGameData g) {
    if (!_economyLoaded) return true;
    final id = EconomyService.normalizeGameId(g.title);
    return _unlocked.contains(id);
  }

  bool _isFavorite(PagerGameData g) {
    final id = EconomyService.normalizeGameId(g.title);
    return _favorites.contains(id);
  }

  Future<void> _toggleFavorite(PagerGameData g) async {
    final newVal = await EconomyService.instance.toggleFavorite(g.title);
    final id = EconomyService.normalizeGameId(g.title);
    if (!mounted) return;
    setState(() {
      if (newVal) {
        _favorites.add(id);
      } else {
        _favorites.remove(id);
      }
    });
  }

  PagerGameData get _currentGame => widget.variations[_current];

  Future<void> _handleComenzar() async {
    final game = _currentGame;
    final unlocked = await EconomyService.instance.isGameUnlocked(game.title);
    if (!unlocked) {
      final price = EconomyService.instance.priceForGame(game.title);
      if (!mounted) return;
      final didUnlock = await _showUnlockDialog(game, price);
      if (didUnlock == true) {
        await _loadEconomy();
      } else {
        return;
      }
      final stillLocked =
          !(await EconomyService.instance.isGameUnlocked(game.title));
      if (stillLocked) return;
    }

    final config = GameConfig.getConfig(game.title);
    final minPlayers = config?.minPlayers ?? game.minPlayers;
    final maxPlayers = config?.maxPlayers ?? 10;

    if (!mounted) return;
    if (widget.players.length < minPlayers) {
      await showDialog<void>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PartyColors.surface,
          title: Text('Jugadores insuficientes',
              style: TextStyle(
                  color: PartyColors.text, fontWeight: FontWeight.w800)),
          content: Text(
            'Se necesitan $minPlayers jugadores (tienes ${widget.players.length}) — añade jugadores en JUGADORES',
            style: TextStyle(color: PartyColors.textSecondary),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: PartyColors.primary),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }
    if (widget.players.length > maxPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Máximo $maxPlayers jugadores para ${game.title}'),
            backgroundColor: PartyColors.surface),
      );
      return;
    }
    final screen = _getGameScreen(game);
    if (screen != null && mounted) {
      await Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => screen));
      await _loadEconomy();
    }
  }

  Future<bool?> _showUnlockDialog(PagerGameData game, int price) async {
    final coins = await EconomyService.instance.getCoins();
    if (!mounted) return false;
    return showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            Icon(Icons.lock, size: 20, color: PartyColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(game.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PartyColors.text))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Este juego está bloqueado.',
                style: TextStyle(color: PartyColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PartyColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: PartyColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('$price monedas',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: PartyColors.text)),
                  const SizedBox(width: 8),
                  Text('• Tienes $coins',
                      style:
                          TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                ],
              ),
            ),
            if (coins < price) ...[
              const SizedBox(height: 12),
              Text('Te faltan ${price - coins} monedas. Juega partidas para ganar más.',
                  style: TextStyle(fontSize: 12, color: PartyColors.danger)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: coins < price
                ? null
                : () async {
                    final ok =
                        await EconomyService.instance.purchaseGame(game.title);
                    if (!ctx.mounted) return;
                    if (ok) {
                      Navigator.pop(ctx, true);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                            content: const Text('No tienes suficientes monedas'),
                            backgroundColor: PartyColors.surface),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
                backgroundColor: PartyColors.primary,
                foregroundColor: PartyColors.onPrimary),
            child: Text('Desbloquear por $price 🪙'),
          ),
        ],
      ),
    );
  }

  Widget? _getGameScreen(PagerGameData game) {
    // Reusa mapeo de games_screen.dart (títulos exactos)
    switch (game.title) {
      case 'IMPOSTOR':
        return ImpostorGame(players: widget.players);
      case 'PUEBLO DUERME':
        return PuebloDuermeGame(players: widget.players);
      case 'ADIVINA':
        return AdivinaGame(players: widget.players);
      case 'ES UN 10 PERO...':
        return EsUn10Game(players: widget.players);
      case 'DEBATE':
        return DebateGame(
            players: widget.players, initialMode: game.debateMode);
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
      case 'ALIENIGENA':
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
      case 'DOS PALABRAS':
        return DosPalabrasGame(players: widget.players);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool multi = widget.variations.length > 1;
    final accent = widget.variations.first.accent;

    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PartyColors.scaffoldGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con cerrar, familia y puntos
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded,
                              color: PartyColors.text),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                PartyColors.surface.withValues(alpha: 0.9),
                            side: BorderSide(color: PartyColors.border),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.familyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.6,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                multi
                                    ? '${_current + 1} / ${widget.variations.length} · Desliza para ver más'
                                    : '1 variación',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: PartyColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: PartyColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: PartyColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text('$_coins',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: PartyColors.text)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Indicador de puntos arriba (centrado)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.variations.length, (i) {
                        final selected = i == _current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: selected ? PartyColors.primary : PartyColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              // PageView vertical tipo TikTok
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.variations.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, index) {
                    final g = widget.variations[index];
                    final locked = !_isUnlocked(g);
                    final fav = _isFavorite(g);
                    final price = EconomyService.instance.priceForGame(g.title);
                    final config = GameConfig.getConfig(g.title);
                    final maxPlayers = config?.maxPlayers ?? 10;
                    return _DetailPage(
                      game: g,
                      accent: g.accent,
                      locked: locked,
                      isFavorite: fav,
                      price: price,
                      maxPlayers: maxPlayers,
                      onToggleFavorite: () => _toggleFavorite(g),
                    );
                  },
                ),
              ),
              // Hint swipe solo si multi
              if (multi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_vertical_rounded,
                          size: 14, color: PartyColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Desliza vertical',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: PartyColors.textMuted)),
                    ],
                  ),
                ),
              // Botón fijo COMENZAR
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Builder(builder: (context) {
                  final game = _currentGame;
                  final locked = !_isUnlocked(game);
                  final price =
                      EconomyService.instance.priceForGame(game.title);
                  final canAfford = _coins >= price;
                  return SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: _handleComenzar,
                      style: FilledButton.styleFrom(
                        backgroundColor: locked
                            ? (canAfford
                                ? PartyColors.primary
                                : PartyColors.textMuted)
                            : PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 6,
                        shadowColor:
                            PartyColors.primary.withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              locked ? Icons.lock_open_rounded : Icons.play_arrow_rounded,
                              size: 22),
                          const SizedBox(width: 8),
                          Text(
                            locked ? 'DESBLOQUEAR · 🪙 $price' : 'COMENZAR',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  final PagerGameData game;
  final Color accent;
  final bool locked;
  final bool isFavorite;
  final int price;
  final int maxPlayers;
  final VoidCallback onToggleFavorite;

  const _DetailPage({
    required this.game,
    required this.accent,
    required this.locked,
    required this.isFavorite,
    required this.price,
    required this.maxPlayers,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: PartyColors.surface.withValues(alpha: 0.96),
          border: Border.all(
              color: locked
                  ? PartyColors.border
                  : accent.withValues(alpha: 0.28),
              width: 1.2),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.06), blurRadius: 14),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          children: [
            // Top row fav + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    game.category,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: accent),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFavorite
                            ? PartyColors.primary
                            : PartyColors.textMuted),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          PartyColors.background.withValues(alpha: 0.9),
                      side: BorderSide(
                          color: isFavorite
                              ? PartyColors.primary.withValues(alpha: 0.3)
                              : PartyColors.border),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Emoji grande
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: locked ? 0.06 : 0.10),
                border: Border.all(
                    color: accent.withValues(alpha: locked ? 0.12 : 0.22)),
              ),
              child: Center(
                child: Text(
                  game.emoji,
                  style: TextStyle(
                      fontSize: 62,
                      color: locked ? Colors.grey : null),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (game.badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: PartyColors.primary.withValues(alpha: 0.22)),
                ),
                child: Text(
                  game.badge!,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: PartyColors.primary),
                ),
              ),
            Text(
              game.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: locked ? PartyColors.textMuted : PartyColors.text),
            ),
            const SizedBox(height: 10),
            Text(
              game.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, height: 1.4, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: PartyColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PartyColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_rounded,
                          size: 14, color: PartyColors.textMuted),
                      const SizedBox(width: 6),
                      Text('${game.minPlayers}-$maxPlayers jugadores',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PartyColors.text)),
                    ],
                  ),
                ),
                if (locked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: PartyColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: PartyColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text('🪙 $price monedas',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: PartyColors.text)),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: PartyColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: PartyColors.success.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: PartyColors.success),
                        const SizedBox(width: 4),
                        Text('Desbloqueado',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: PartyColors.success)),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (locked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 13, color: PartyColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Bloqueado · toca COMENZAR para desbloquear',
                      style: TextStyle(
                          fontSize: 11, color: PartyColors.textMuted)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
