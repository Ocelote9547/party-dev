import 'package:flutter/material.dart';

import '../theme/party_theme.dart';

class PartyBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const PartyBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const items = [
    (Icons.home_rounded, 'INICIO'),
    (Icons.sports_esports_rounded, 'JUEGOS'),
    (Icons.people_alt_rounded, 'GRUPO'),
    (Icons.extension_rounded, 'EXTRAS'),
    (Icons.settings_rounded, 'AJUSTES'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        decoration: BoxDecoration(
          color: PartyColors.navBar,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: PartyColors.border.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: PartyColors.primary.withValues(alpha: 0.03),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            items.length,
            (index) {
              final selected = selectedIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected
                          ? PartyColors.primary.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.08 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            item.$1,
                            size: 22,
                            color: selected
                                ? PartyColors.primary
                                : PartyColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            letterSpacing: 1,
                            color: selected
                                ? PartyColors.primary
                                : PartyColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: selected ? 18 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: PartyColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
