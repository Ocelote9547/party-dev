import 'package:flutter/material.dart';

import '../theme/party_theme.dart';

class PlayCard extends StatelessWidget {
  final VoidCallback onTap;

  const PlayCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              PartyColors.surfaceLight,
              PartyColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: PartyColors.primary.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: PartyColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PartyColors.primary.withValues(alpha: 0.06),
                  border: Border.all(
                    color: PartyColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.sports_esports_outlined,
                  size: 54,
                  color: PartyColors.primary,
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JUGAR',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: PartyColors.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'ELIGE UN JUEGO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: PartyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PartyColors.border,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: PartyColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
