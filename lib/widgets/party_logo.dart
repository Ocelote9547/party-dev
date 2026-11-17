import 'package:flutter/material.dart';

import '../theme/party_theme.dart';

class PartyLogo extends StatelessWidget {
  const PartyLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
  children: [
    Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            PartyColors.primary.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PartyColors.primary.withValues(alpha: 0.7),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: [
                PartyColors.primary.withValues(alpha: 0.18),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'P',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: PartyColors.primary,
              ),
            ),
          ),
        ),
      ),
    ),

        const SizedBox(height: 12),

        Text(
          'PARTY',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
            color: PartyColors.text,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 2,
              color: PartyColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'JUEGOS PARA TODOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
                color: PartyColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 2,
              color: PartyColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}