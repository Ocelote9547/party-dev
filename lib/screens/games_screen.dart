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
import '../games/historia_game.dart';
import '../games/impostor_game.dart';
import '../games/mascara_infiltrada_game.dart';
import '../games/matar_casar_besar_game.dart';
import '../games/mimica_game.dart';
import '../games/pueblo_duerme_game.dart';
import '../games/quien_es_mas_game.dart';
import '../games/quien_soy_game.dart';
import '../games/secretos_game.dart';
import '../games/tabu_game.dart';
import '../games/dos_palabras_game.dart';
import '../games/verdad_o_reto_game.dart';
import '../games/yo_nunca_game.dart';
import '../games/yo_tengo_un_amigo_game.dart';
import '../services/economy_service.dart';
import '../theme/party_theme.dart';
import 'leaderboard_screen.dart';
import 'shop_screen.dart';

class _BaseGame {
  final String emoji;
  final String title;
  final String description;
  final String category;
  final int minPlayers;
  const _BaseGame({
    required this.emoji,
    required this.title,
    required this.description,
    required this.category,
    this.minPlayers = 2,
  });
}

class GamesScreen extends StatefulWidget {
  final List<String> players;
  const GamesScreen({super.key, required this.players});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  static const _categoryColors = {
    'MENTIRA': PartyColors.purple,
    'GRUPO': Color(0xFF46B8E8),
    'PALABRAS': Color(0xFF25E6D0),
    'RETO': Color(0xFF2ED9B4),
    'OPINIÓN': Color(0xFFFFD93D),
  };

  static const _categories = [
    'TODOS',
    'GRUPO',
    'PALABRAS',
    'RETO',
    'OPINIÓN',
    'MENTIRA',
  ];

  // Lista plana de juegos base (sin pager). Variaciones ahora dentro del juego.
  static const List<_BaseGame> _allGames = [
    // MENTIRA
    _BaseGame(emoji: '🕵️', title: 'IMPOSTOR', description: 'Descubre quién está mintiendo', category: 'MENTIRA', minPlayers: 4),
    _BaseGame(emoji: '🕵️', title: '¿QUIÉN ES EL ESPIA?', description: 'Encuentra al espía entre vosotros', category: 'MENTIRA', minPlayers: 4),
    _BaseGame(emoji: '🕵️', title: 'SECRETOS', description: '¿Quién es el culpable?', category: 'MENTIRA', minPlayers: 4),
    _BaseGame(emoji: '🎭', title: 'LA MÁSCARA INFILTRADA', description: 'Todos ven una máscara... uno la tiene distinta sin saberlo', category: 'MENTIRA', minPlayers: 4),
    _BaseGame(emoji: '👽', title: 'ALIENÍGENA', description: 'Encuentra al alien entre preguntas y engaños', category: 'MENTIRA', minPlayers: 4),
    _BaseGame(emoji: '👼', title: 'ANGELES Y DEMONIOS', description: 'Adivina quién es tu ángel y tu demonio', category: 'MENTIRA', minPlayers: 4),
    // GRUPO
    _BaseGame(emoji: '🌙', title: 'PUEBLO DUERME', description: 'Sobrevive a la noche', category: 'GRUPO', minPlayers: 4),
    _BaseGame(emoji: '🤫', title: 'YO NUNCA', description: 'Descubre los secretos del grupo', category: 'GRUPO', minPlayers: 3),
    _BaseGame(emoji: '👀', title: 'QUIÉN ES MÁS', description: 'Votad entre vosotros', category: 'GRUPO', minPlayers: 4),
    _BaseGame(emoji: '🎭', title: '¿QUIÉN SOY?', description: 'Adivina el personaje de tu frente', category: 'GRUPO', minPlayers: 3),
    _BaseGame(emoji: '💋', title: 'MATAR, CASAR, BESAR', description: 'Elige a quién matar, casar o besar', category: 'GRUPO', minPlayers: 3),
    _BaseGame(emoji: '👥', title: 'YO TENGO UN AMIGO', description: 'Un equipo piensa anécdota, el otro adivina de quién es', category: 'GRUPO', minPlayers: 6),
    // PALABRAS
    _BaseGame(emoji: '🧠', title: 'ADIVINA', description: 'Móvil en la frente, adivina la palabra', category: 'PALABRAS', minPlayers: 3),
    _BaseGame(emoji: '🥗', title: 'LA ENSALADA', description: '4 rondas con las mismas palabras', category: 'PALABRAS', minPlayers: 4),
    _BaseGame(emoji: '💬', title: 'DOS PALABRAS', description: 'Explica la palabra con solo 2 palabras', category: 'PALABRAS', minPlayers: 3),
    _BaseGame(emoji: '💣', title: 'BOMBA', description: 'Di una palabra con la sílaba antes de que explote', category: 'PALABRAS', minPlayers: 3),
    _BaseGame(emoji: '🎨', title: 'DIBUJA Y ADIVINA', description: 'Dibuja la palabra y que el grupo la adivine', category: 'PALABRAS', minPlayers: 3),
    _BaseGame(emoji: '🚫', title: 'TABÚ', description: 'Explica sin decir ciertas palabras', category: 'PALABRAS', minPlayers: 4),
    _BaseGame(emoji: '📖', title: 'HISTORIA COLECTIVA', description: 'Cada jugador añade una frase a una historia', category: 'PALABRAS', minPlayers: 3),
    // RETO
    _BaseGame(emoji: '🎭', title: 'MÍMICA', description: 'Haz gestos y que el grupo acierte', category: 'RETO', minPlayers: 4),
    _BaseGame(emoji: '🔟', title: 'ES UN 10 PERO...', description: 'Carta oculta, número secreto y pistas del grupo', category: 'RETO', minPlayers: 3),
    _BaseGame(emoji: '🎲', title: 'VERDAD O RETO', description: '¿Te atreves a decir la verdad?', category: 'RETO', minPlayers: 2),
    _BaseGame(emoji: '🖐️', title: 'APT COREANO', description: 'Ritmo con palmas, el que falla recibe bofetada suave', category: 'RETO', minPlayers: 4),
    // OPINIÓN
    _BaseGame(emoji: '💬', title: 'DEBATE', description: 'Temas para discutir y reír', category: 'OPINIÓN', minPlayers: 4),
  ];

  // Tarjeta "EN CONSTRUCCIÓN" al final de PALABRAS (no es un juego real).
  static const _comingSoon = _BaseGame(
    emoji: '🚧',
    title: 'EN CONSTRUCCIÓN',
    description: 'Nuevo juego en camino',
    category: 'PALABRAS',
    minPlayers: 2,
  );

  static bool _isComingSoon(_BaseGame game) => game.title == _comingSoon.title;

  String _selectedCategory = 'TODOS';
  List<_BaseGame> _filteredGames = [];
  Set<String> _unlocked = {};
  int _coins = 0;
  bool _economyLoaded = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _favorites = {};
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _filteredGames = _allGames;
    _updateFilteredGames();
    _searchController.addListener(_onSearchChanged);
    _loadEconomy();
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
      _updateFilteredGames();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text;
    if (q == _searchQuery) return;
    setState(() {
      _searchQuery = q;
      _updateFilteredGames();
    });
  }

  Future<void> _loadEconomy() async {
    final unlocked = await EconomyService.instance.getUnlockedGames();
    final coins = await EconomyService.instance.getCoins();
    await EconomyService.instance.checkAutoUnlocks();
    final unlocked2 = await EconomyService.instance.getUnlockedGames();
    final favorites = await EconomyService.instance.getFavoriteGames();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked2.isNotEmpty ? unlocked2 : unlocked;
      _coins = coins;
      _favorites = favorites;
      _economyLoaded = true;
      _updateFilteredGames();
    });
  }

  bool _isUnlocked(_BaseGame game) {
    if (_isComingSoon(game)) return false;
    if (!_economyLoaded) return true;
    final id = EconomyService.normalizeGameId(game.title);
    return _unlocked.contains(id);
  }

  bool _isFavorite(_BaseGame game) {
    final id = EconomyService.normalizeGameId(game.title);
    return _favorites.contains(id);
  }

  Future<void> _toggleFavorite(_BaseGame game) async {
    final newVal = await EconomyService.instance.toggleFavorite(game.title);
    final id = EconomyService.normalizeGameId(game.title);
    if (!mounted) return;
    setState(() {
      if (newVal) {
        _favorites.add(id);
      } else {
        _favorites.remove(id);
      }
      _updateFilteredGames();
    });
  }

  void _updateFilteredGames() {
    final q = _searchQuery.trim().toLowerCase();
    List<_BaseGame> base = _allGames.where((g) {
      if (_selectedCategory != 'TODOS' && g.category != _selectedCategory) return false;
      final matchesSearch = q.isEmpty || g.title.toLowerCase().contains(q) || g.description.toLowerCase().contains(q);
      final matchesFav = !_showFavoritesOnly || _favorites.contains(EconomyService.normalizeGameId(g.title));
      return matchesSearch && matchesFav;
    }).toList();

    if (_selectedCategory == 'TODOS') {
      base.sort((a, b) {
        final ai = _categories.indexOf(a.category);
        final bi = _categories.indexOf(b.category);
        if (ai != bi) return ai.compareTo(bi);
        return a.title.compareTo(b.title);
      });
    } else {
      base.sort((a, b) {
        final favA = _isFavorite(a);
        final favB = _isFavorite(b);
        if (favA != favB) return favA ? -1 : 1;
        final unlockA = _isUnlocked(a);
        final unlockB = _isUnlocked(b);
        if (unlockA != unlockB) return unlockA ? -1 : 1;
        return a.title.compareTo(b.title);
      });
    }
    // Añade "EN CONSTRUCCIÓN" al final de PALABRAS respetando filtros/búsqueda.
    final passesCategory = _selectedCategory == 'TODOS' || _selectedCategory == _comingSoon.category;
    final passesSearch = q.isEmpty ||
        _comingSoon.title.toLowerCase().contains(q) ||
        _comingSoon.description.toLowerCase().contains(q);
    final passesFav = !_showFavoritesOnly ||
        _favorites.contains(EconomyService.normalizeGameId(_comingSoon.title));
    if (passesCategory && passesSearch && passesFav) {
      base.removeWhere((g) => _isComingSoon(g));
      if (_selectedCategory == 'TODOS') {
        final lastPalabras = base.lastIndexWhere((g) => g.category == _comingSoon.category);
        if (lastPalabras != -1) {
          base.insert(lastPalabras + 1, _comingSoon);
        } else {
          final palabrasOrder = _categories.indexOf(_comingSoon.category);
          var insertAt = base.length;
          for (var i = 0; i < base.length; i++) {
            if (_categories.indexOf(base[i].category) > palabrasOrder) {
              insertAt = i;
              break;
            }
          }
          base.insert(insertAt, _comingSoon);
        }
      } else {
        base.add(_comingSoon);
      }
    }
    _filteredGames = base;
  }

  List<Widget> _buildGameSlivers({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    if (_filteredGames.isEmpty) {
      return [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 130),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Text('Sin resultados', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ),
      ];
    }

    if (_selectedCategory == 'TODOS') {
      final catsInOrder = _categories.where((c) => c != 'TODOS').toList();
      final availableCats = catsInOrder.where((c) => _filteredGames.any((g) => g.category == c)).toList();
      final slivers = <Widget>[];
      bool isFirstCat = true;
      for (int ci = 0; ci < availableCats.length; ci++) {
        final cat = availableCats[ci];
        final gamesInCat = _filteredGames.where((g) => g.category == cat).toList();
        if (gamesInCat.isEmpty) continue;
        final isLastCat = ci == availableCats.length - 1;
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, isFirstCat ? 4 : 18, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _categoryColors[cat],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: _categoryColors[cat],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: (_categoryColors[cat] ?? PartyColors.primary).withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${gamesInCat.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PartyColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, isLastCat ? 130 : 0),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: gamesInCat.length,
              itemBuilder: (context, index) {
                final g = gamesInCat[index];
                return _GameCard(
                  game: g,
                  locked: !_isUnlocked(g),
                  isFavorite: _isFavorite(g),
                  price: EconomyService.instance.priceForGame(g.title),
                  onToggleFavorite: () => _toggleFavorite(g),
                  onPlay: () => _openGame(g),
                );
              },
            ),
          ),
        );
        isFirstCat = false;
      }
      return slivers;
    } else {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _filteredGames.length,
            itemBuilder: (context, index) {
              final g = _filteredGames[index];
              return _GameCard(
                game: g,
                locked: !_isUnlocked(g),
                isFavorite: _isFavorite(g),
                price: EconomyService.instance.priceForGame(g.title),
                onToggleFavorite: () => _toggleFavorite(g),
                onPlay: () => _openGame(g),
              );
            },
          ),
        ),
      ];
    }
  }

  Future<void> _openGame(_BaseGame game) async {
    if (_isComingSoon(game)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Próximamente 🔧')),
      );
      return;
    }
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
      final stillLocked = !(await EconomyService.instance.isGameUnlocked(game.title));
      if (stillLocked) return;
    }

    final config = GameConfig.getConfig(game.title);
    final minPlayers = config?.minPlayers ?? game.minPlayers;
    final maxPlayers = config?.maxPlayers ?? 10;

    if (!mounted) return;
    if (widget.players.length < minPlayers) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: PartyColors.surface,
          title: Text('Jugadores insuficientes', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
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
        SnackBar(content: Text('Máximo $maxPlayers jugadores para ${game.title}'), backgroundColor: PartyColors.surface),
      );
      return;
    }
    final screen = _getGameScreen(game);
    if (screen != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      await _loadEconomy();
    }
  }

  Future<bool?> _showUnlockDialog(_BaseGame game, int price) async {
    final coins = await EconomyService.instance.getCoins();
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            Icon(Icons.lock, size: 20, color: PartyColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(game.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.text))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Este juego está bloqueado.', style: TextStyle(color: PartyColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PartyColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('$price monedas', style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.text)),
                  const SizedBox(width: 8),
                  Text('• Tienes $coins', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                ],
              ),
            ),
            if (coins < price) ...[
              const SizedBox(height: 12),
              Text('Te faltan ${price - coins} monedas. Juega partidas para ganar más.', style: TextStyle(fontSize: 12, color: PartyColors.danger)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: coins < price
                ? null
                : () async {
                    final ok = await EconomyService.instance.purchaseGame(game.title);
                    if (!ctx.mounted) return;
                    if (ok) {
                      Navigator.pop(ctx, true);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: const Text('No tienes suficientes monedas'), backgroundColor: PartyColors.surface),
                      );
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary),
            child: Text('Desbloquear por $price 🪙'),
          ),
        ],
      ),
    ).then((result) async {
      if (result == false && coins < price && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te faltan monedas para ${game.title} ($price necesarias, tienes $coins)'), backgroundColor: PartyColors.surface),
        );
      }
      return result;
    });
  }

  Widget? _getGameScreen(_BaseGame game) {
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
      case 'ALIENIGENA':
        return AlienigenaGame(players: widget.players);
      case 'YO TENGO UN AMIGO':
        return YoTengoUnAmigoGame(players: widget.players);
      case 'APT COREANO':
        return AptCoreanoGame(players: widget.players);
      case 'ANGELES Y DEMONIOS':
        return AngelesDemoniosGame(players: widget.players);
      case 'DOS PALABRAS':
        return DosPalabrasGame(players: widget.players);
      case 'HISTORIA COLECTIVA':
        return HistoriaGame(players: widget.players);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: PartyColors.scaffoldGradient.take(3).toList(),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final crossAxisCount = isTablet ? 3 : 2;
            // childAspectRatio dinámico para no overflow en pantallas pequeñas
            double childAspectRatio;
            if (constraints.maxWidth < 360) {
              childAspectRatio = 0.78;
            } else if (constraints.maxWidth < 400) {
              childAspectRatio = 0.82;
            } else if (isTablet) {
              childAspectRatio = 0.92;
            } else {
              childAspectRatio = 0.88;
            }
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('JUEGOS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3, color: PartyColors.text)),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                                await _loadEconomy();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: PartyColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: PartyColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🪙', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text('$_coins', style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.text)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.storefront_outlined, size: 16, color: PartyColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text('Elige cómo queréis jugar.', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          style: TextStyle(color: PartyColors.text),
                          decoration: InputDecoration(
                            hintText: 'Buscar juego...',
                            hintStyle: TextStyle(color: PartyColors.textMuted),
                            prefixIcon: Icon(Icons.search_rounded, color: PartyColors.textMuted),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(Icons.clear_rounded, color: PartyColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  ),
                            filled: true,
                            fillColor: PartyColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: PartyColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: PartyColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: PartyColors.primary, width: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(players: widget.players))),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: PartyColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              children: [
                                Text('🏆', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 10),
                                Text('RANKING', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: PartyColors.primary)),
                                Spacer(),
                                Icon(Icons.chevron_right_rounded, color: PartyColors.primary, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length + 1,
                            itemBuilder: (context, index) {
                              if (index < _categories.length) {
                                final cat = _categories[index];
                                final catColor = _categoryColors[cat];
                                return _CategoryChip(
                                  label: cat,
                                  selected: cat == _selectedCategory && !_showFavoritesOnly,
                                  color: catColor,
                                  onTap: () => _onCategorySelected(cat),
                                );
                              } else {
                                final favSelected = _showFavoritesOnly;
                                return _CategoryChip(
                                  label: '⭐ FAVORITOS',
                                  selected: favSelected,
                                  color: const Color(0xFFFF3D00),
                                  onTap: () => setState(() {
                                    _showFavoritesOnly = !_showFavoritesOnly;
                                    _updateFilteredGames();
                                  }),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._buildGameSlivers(crossAxisCount: crossAxisCount, childAspectRatio: childAspectRatio),
              ],
            );
          },
        ),
      ),
    );
  }
}

// _GameCard restaurado: padding 16, icono 48x48 fontSize 25, title fontSize 17, childAspectRatio: 0.88. Fix overflow (maxLines/ellipsis) intacto sin encoger.
class _GameCard extends StatelessWidget {
  final _BaseGame game;
  final bool locked;
  final bool isFavorite;
  final int price;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;

  const _GameCard({
    required this.game,
    required this.onPlay,
    this.locked = false,
    this.isFavorite = false,
    required this.onToggleFavorite,
    this.price = 80,
  });

  @override
  Widget build(BuildContext context) {
    final config = GameConfig.getConfig(game.title);
    final maxPlayers = config?.maxPlayers ?? 10;
    final accent = _categoryColors[game.category] ?? PartyColors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: locked ? PartyColors.surface.withValues(alpha: 0.75) : PartyColors.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: isFavorite ? PartyColors.primary.withValues(alpha: 0.45) : locked ? PartyColors.border : accent.withValues(alpha: 0.28),
        ),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withValues(alpha: locked ? 0.05 : 0.09),
                      border: Border.all(color: accent.withValues(alpha: locked ? 0.12 : 0.22)),
                    ),
                    child: Center(
                      child: Text(game.emoji, style: TextStyle(fontSize: 25, color: locked ? Colors.grey : null)),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(locked ? Icons.lock : Icons.arrow_outward_rounded, size: 19, color: locked ? PartyColors.textMuted : accent),
                      const SizedBox(width: 28),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                game.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: locked ? PartyColors.textMuted : PartyColors.text),
              ),
              const SizedBox(height: 4),
              Text(game.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, height: 1.3, color: PartyColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${game.minPlayers}-$maxPlayers jugadores', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
                  if (locked) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: PartyColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('🪙 $price', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: PartyColors.text)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton(
                  onPressed: onPlay,
                  style: FilledButton.styleFrom(
                    backgroundColor: locked ? PartyColors.textMuted : PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(locked ? 'DESBLOQUEAR' : 'JUGAR', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 20, color: isFavorite ? PartyColors.primary : PartyColors.textMuted),
                style: IconButton.styleFrom(
                  backgroundColor: PartyColors.surface.withValues(alpha: 0.92),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: isFavorite ? PartyColors.primary.withValues(alpha: 0.3) : PartyColors.border),
                ),
                onPressed: onToggleFavorite,
                tooltip: isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _categoryColors = {
    'MENTIRA': PartyColors.purple,
    'GRUPO': Color(0xFF46B8E8),
    'PALABRAS': Color(0xFF25E6D0),
    'RETO': Color(0xFF2ED9B4),
    'OPINIÓN': Color(0xFFFFD93D),
  };
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, this.selected = false, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? PartyColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? effectiveColor.withValues(alpha: 0.12) : PartyColors.surface,
          border: Border.all(color: selected ? effectiveColor.withValues(alpha: 0.55) : PartyColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: selected ? effectiveColor : PartyColors.textMuted),
          ),
        ),
      ),
    );
  }
}
