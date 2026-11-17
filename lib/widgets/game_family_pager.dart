import 'package:flutter/material.dart';

import '../data/game_config.dart';
import '../theme/party_theme.dart';

/// Datos públicos para una variación dentro de una familia.
class PagerGameData {
  final String emoji;
  final String title;
  final String description;
  final String category;
  final int minPlayers;
  final String? badge;
  final String? debateMode;

  const PagerGameData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.category,
    this.minPlayers = 2,
    this.badge,
    this.debateMode,
  });

  Color get accent {
    const categoryColors = {
      'MENTIRA': PartyColors.purple,
      'GRUPO': Color(0xFF46B8E8),
      'PALABRAS': Color(0xFF25E6D0),
      'RETO': Color(0xFF2ED9B4),
      'OPINIÓN': Color(0xFFFFD93D),
    };
    return categoryColors[category] ?? PartyColors.primary;
  }
}

class GameFamilyPager extends StatefulWidget {
  final String familyName;
  final String category;
  final List<PagerGameData> variations;
  final Future<void> Function(PagerGameData game) onPlay;
  final bool Function(PagerGameData game) isUnlocked;
  final bool Function(PagerGameData game) isFavorite;
  final Future<void> Function(PagerGameData game) onToggleFavorite;
  final int Function(PagerGameData game) priceFor;
  final void Function(PagerGameData game, int index)? onCardTap;

  const GameFamilyPager({
    super.key,
    required this.familyName,
    required this.category,
    required this.variations,
    required this.onPlay,
    required this.isUnlocked,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.priceFor,
    this.onCardTap,
  });

  @override
  State<GameFamilyPager> createState() => _GameFamilyPagerState();
}

class _GameFamilyPagerState extends State<GameFamilyPager> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variations.isEmpty) return const SizedBox.shrink();
    final bool multi = widget.variations.length > 1;
    final Color accent = widget.variations.first.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header familia (reusa estilo de categorías)
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              widget.familyName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: accent.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.variations.length}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: PartyColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 236,
          child: PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.variations.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final g = widget.variations[index];
              final locked = !widget.isUnlocked(g);
              final fav = widget.isFavorite(g);
              final price = widget.priceFor(g);
              return Padding(
                padding: EdgeInsets.only(
                  right: index == widget.variations.length - 1 ? 0 : 10,
                  left: 2,
                ),
                child: _PagerGameCard(
                  game: g,
                  locked: locked,
                  isFavorite: fav,
                  price: price,
                  onPlay: () {
                    if (widget.onCardTap != null) {
                      widget.onCardTap!(g, index);
                    } else {
                      widget.onPlay(g);
                    }
                  },
                  onToggleFavorite: () => widget.onToggleFavorite(g),
                  onCardTap: widget.onCardTap == null
                      ? null
                      : () => widget.onCardTap!(g, index),
                ),
              );
            },
          ),
        ),
        if (multi) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.variations.length, (i) {
              final selected = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? accent : PartyColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Desliza para ver más',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: PartyColors.textMuted.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PagerGameCard extends StatelessWidget {
  final PagerGameData game;
  final bool locked;
  final bool isFavorite;
  final int price;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onCardTap;

  const _PagerGameCard({
    required this.game,
    required this.onPlay,
    this.locked = false,
    this.isFavorite = false,
    required this.onToggleFavorite,
    this.price = 80,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = GameConfig.getConfig(game.title);
    final maxPlayers = config?.maxPlayers ?? 10;
    final accent = game.accent;
    final Widget background = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: locked
            ? PartyColors.surface.withValues(alpha: 0.75)
            : PartyColors.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: isFavorite
              ? PartyColors.primary.withValues(alpha: 0.45)
              : locked
                  ? PartyColors.border
                  : accent.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: locked ? 0.05 : 0.09),
                  border: Border.all(
                    color: accent.withValues(alpha: locked ? 0.12 : 0.22),
                  ),
                ),
                child: Center(
                  child: Text(
                    game.emoji,
                    style: TextStyle(
                      fontSize: 23,
                      color: locked ? Colors.grey : null,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock : Icons.arrow_outward_rounded,
                    size: 19,
                    color: locked ? PartyColors.textMuted : accent,
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (game.badge != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                game.badge!,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: accent,
                ),
              ),
            ),
          if (isFavorite && game.badge == null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: PartyColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PartyColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite,
                      size: 10, color: PartyColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'FAVORITO',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: PartyColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            game.category,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: locked ? PartyColors.textMuted : accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: locked ? PartyColors.textMuted : PartyColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            game.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 10.5, height: 1.3, color: PartyColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${game.minPlayers}-$maxPlayers jugadores',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: PartyColors.textMuted,
                ),
              ),
              if (locked) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: PartyColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🪙 $price',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: PartyColors.text,
                    ),
                  ),
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
                backgroundColor: locked
                    ? PartyColors.textMuted
                    : PartyColors.primary,
                foregroundColor: PartyColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                locked ? 'DESBLOQUEAR' : 'JUGAR',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        if (onCardTap != null)
          GestureDetector(
            onTap: onCardTap,
            behavior: HitTestBehavior.opaque,
            child: background,
          )
        else
          background,
        if (locked)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: PartyColors.surface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFavorite ? PartyColors.primary : PartyColors.textMuted,
              ),
              style: IconButton.styleFrom(
                backgroundColor: PartyColors.surface.withValues(alpha: 0.92),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: isFavorite
                      ? PartyColors.primary.withValues(alpha: 0.3)
                      : PartyColors.border,
                ),
              ),
              onPressed: onToggleFavorite,
              tooltip:
                  isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
            ),
          ),
        ),
      ],
    );
  }
}
