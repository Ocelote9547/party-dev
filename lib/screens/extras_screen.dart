import 'package:flutter/material.dart';

import '../plans/plan_creator_v2_screen.dart';
import '../theme/party_theme.dart';
import 'chaos_screen.dart';
import 'retro_camera_screen.dart';
import 'roulette_screen.dart';

class ExtrasScreen extends StatelessWidget {
  final List<String> players;
  const ExtrasScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: PartyColors.scaffoldGradient,
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        // SafeArea con bottom padding 16 para evitar overflow con gesture/navigation bar
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXTRAS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: PartyColors.text,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Herramientas rápidas para la fiesta',
                      style: TextStyle(fontSize: 14, color: PartyColors.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.92,
                      children: [
                        _ExtrasCard(
                          emoji: '🎲',
                          title: 'RULETA',
                          subtitle: 'Sorpréndeme con juego/modo/duración',
                          badge: 'SORPRESA',
                          icon: Icons.casino_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RouletteScreen(players: players)),
                            );
                          },
                        ),
                        _ExtrasCard(
                          emoji: '🔥',
                          title: 'MODO CAOS',
                          subtitle: '5 juegos sorpresa',
                          badge: 'ALEATORIO',
                          icon: Icons.local_fire_department_rounded,
                          isPrimary: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChaosScreen(players: players)),
                            );
                          },
                        ),
                        _ExtrasCard(
                          emoji: '📸',
                          title: 'FOTO RETRO',
                          subtitle: 'Cámara KODAK',
                          badge: 'GRUPAL',
                          icon: Icons.photo_camera_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RetroCameraScreen()),
                            );
                          },
                        ),
                        _ExtrasCard(
                          emoji: '🧪',
                          title: 'PLANES',
                          subtitle: 'Creador de planes',
                          badge: 'CREADOR',
                          icon: Icons.science_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PlanCreatorV2Screen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PartyColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PartyColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PartyColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: PartyColors.primary.withValues(alpha: 0.22)),
                            ),
                            child: const Icon(Icons.info_outline_rounded, size: 20, color: PartyColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Cómo usar Extras?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PartyColors.text),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Accesos rápidos. No afectan al progreso de juegos.',
                                  style: TextStyle(fontSize: 11, color: PartyColors.textMuted, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// _ExtrasCard: altura reducida 96->88, padding 16->12 para evitar overflow 6.1px
class _ExtrasCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ExtrasCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isPrimary ? PartyColors.primary : PartyColors.surface,
          border: Border.all(
            color: isPrimary ? PartyColors.primary : PartyColors.border,
            width: isPrimary ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary ? PartyColors.primary.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isPrimary ? Colors.white.withValues(alpha: 0.18) : PartyColors.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: isPrimary ? Colors.white.withValues(alpha: 0.35) : PartyColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
                Icon(icon, size: 18, color: isPrimary ? Colors.white.withValues(alpha: 0.92) : PartyColors.primary.withValues(alpha: 0.85)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.18) : PartyColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isPrimary ? Colors.white.withValues(alpha: 0.28) : PartyColors.primary.withValues(alpha: 0.22)),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isPrimary ? Colors.white : PartyColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: isPrimary ? Colors.white : PartyColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white.withValues(alpha: 0.88) : PartyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'ABRIR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isPrimary ? Colors.white : PartyColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: isPrimary ? Colors.white : PartyColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
