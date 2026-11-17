import 'package:flutter/material.dart';

import '../services/economy_service.dart';
import '../theme/party_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int price;
  final String type; // 'pack' or 'game'
  const _ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.price,
    required this.type,
  });
}

class _ShopScreenState extends State<ShopScreen> {
  int _coins = 0;
  Set<String> _unlockedPacks = {};
  Set<String> _unlockedGames = {};
  bool _loading = true;
  final Set<String> _buying = {};

  static const List<_ShopItem> _items = [
    // Cosméticos (único comprable con monedas además de los 5 juegos extra)
    _ShopItem(id: 'pack_hats', title: 'Pack Sombreros', description: '6 sombreros extra', emoji: '🎩', price: 50, type: 'pack'),
    _ShopItem(id: 'pack_glasses', title: 'Pack Gafas', description: '4 gafas extra', emoji: '🕶️', price: 50, type: 'pack'),
    _ShopItem(id: 'pack_masks', title: 'Pack Máscaras', description: '4 máscaras extra', emoji: '🎭', price: 60, type: 'pack'),
    _ShopItem(id: 'pack_faces', title: 'Pack Caras', description: '4 caras extra', emoji: '🤖', price: 50, type: 'pack'),
    _ShopItem(id: 'pack_hats_premium', title: 'Pack Sombreros Premium', description: 'Sombreros legendarios', emoji: '👑', price: 70, type: 'pack'),
    _ShopItem(id: 'pack_colors', title: 'Pack Colores', description: '6 degradados extra', emoji: '🎨', price: 30, type: 'pack'),
    _ShopItem(id: 'pack_golden', title: 'Pack Dorado', description: '2 avatares dorados exclusivos', emoji: '🏆', price: 150, type: 'pack'),
    _ShopItem(id: 'pack_extras', title: 'Pack Extras', description: '4 sombreros + 4 gafas + 2 máscaras + 2 caras', emoji: '✨', price: 90, type: 'pack'),
    // Juegos extra no esenciales (solo por compra)
    _ShopItem(id: 'BOMBA', title: 'Juego: BOMBA', description: 'Di una palabra antes de que explote', emoji: '💣', price: 80, type: 'game'),
    _ShopItem(id: 'ALIENIGENA', title: 'Juego: ALIENÍGENA', description: 'Encuentra al alien entre preguntas', emoji: '👽', price: 100, type: 'game'),
    _ShopItem(id: 'SECRETOS', title: 'Juego: SECRETOS', description: '¿Quién es el culpable?', emoji: '🤫', price: 90, type: 'game'),
    _ShopItem(id: 'LA_MASCARA_INFILTRADA', title: 'Juego: LA MÁSCARA', description: 'La máscara infiltrada', emoji: '🎭', price: 120, type: 'game'),
    _ShopItem(id: 'QUIEN_ES_MAS', title: 'Juego: QUIÉN ES MÁS', description: 'Votad entre vosotros', emoji: '👀', price: 90, type: 'game'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coins = await EconomyService.instance.getCoins();
    final packs = await EconomyService.instance.getUnlockedPacks();
    final games = await EconomyService.instance.getUnlockedGames();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _unlockedPacks = packs;
      _unlockedGames = games;
      _loading = false;
    });
  }

  bool _isUnlocked(_ShopItem item) {
    if (item.type == 'pack') return _unlockedPacks.contains(item.id);
    return _unlockedGames.contains(EconomyService.normalizeGameId(item.id));
  }

  Future<void> _buy(_ShopItem item) async {
    if (_buying.contains(item.id)) return;
    if (_isUnlocked(item)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} ya está desbloqueado'), backgroundColor: PartyColors.surface),
      );
      return;
    }
    _buying.add(item.id);
    bool success = false;
    try {
      if (item.type == 'pack') {
        success = await EconomyService.instance.purchasePack(item.id, item.price);
      } else {
        success = await EconomyService.instance.purchaseGame(item.id);
      }
    } finally {
      _buying.remove(item.id);
    }
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡${item.title} desbloqueado!'), backgroundColor: PartyColors.success),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Te faltan monedas (${item.price} necesarias)'), backgroundColor: PartyColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TIENDA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PartyColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PartyColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('$_coins', style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.text)),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final unlocked = _isUnlocked(item);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PartyColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: unlocked ? PartyColors.success.withValues(alpha: 0.4) : PartyColors.border,
                    ),
                  ),
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
                              color: PartyColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
                          ),
                          if (unlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: PartyColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('DESBLOQUEADO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: PartyColors.success)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: PartyColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('🪙 ${item.price}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PartyColors.text)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(item.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.text)),
                      const SizedBox(height: 4),
                      Text(item.description, maxLines: 2, style: TextStyle(fontSize: 10, color: PartyColors.textSecondary)),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: unlocked ? null : () => _buy(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: unlocked ? PartyColors.surface : PartyColors.primary,
                            foregroundColor: unlocked ? PartyColors.textMuted : PartyColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(unlocked ? 'OBTENIDO' : 'COMPRAR', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
