import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../services/avatar_service.dart';
import '../theme/party_theme.dart';
import 'avatar_display.dart';

class GroupSection extends StatelessWidget {
  final List<String> players;

  const GroupSection({
    super.key,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final displayPlayers = players.length > 10 ? players.sublist(0, 10) : players;

    if (players.isEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 35, height: 1, color: PartyColors.border),
              const SizedBox(width: 12),
              const Icon(Icons.people_alt_outlined, color: PartyColors.primary, size: 18),
              const SizedBox(width: 7),
              const Text('TU GRUPO', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.5, color: PartyColors.primary)),
              const SizedBox(width: 12),
              Container(width: 35, height: 1, color: PartyColors.border),
            ],
          ),
          const SizedBox(height: 18),
          Text('Añade jugadores', style: TextStyle(fontSize: 14, color: PartyColors.textSecondary)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: PartyColors.border), color: PartyColors.surface.withValues(alpha: 0.65)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people_alt_outlined, size: 17, color: PartyColors.primary),
              const SizedBox(width: 8),
              Flexible(child: Text('0 JUGADORES', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: PartyColors.textSecondary))),
            ]),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 35,
              height: 1,
              color: PartyColors.border,
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.people_alt_outlined,
              color: PartyColors.primary,
              size: 18,
            ),
            const SizedBox(width: 7),
            const Text(
              'TU GRUPO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
                color: PartyColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 35,
              height: 1,
              color: PartyColors.border,
            ),
          ],
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: displayPlayers.map((player) {
            // player may be a single letter (legacy from HomeScreen) or full name.
            // If it's a single letter, treat as initial.
            if (player.length == 1) {
              return _PlayerAvatar(letter: player);
            }
            return _AvatarOrLetter(playerName: player);
          }).toList(),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: PartyColors.border,
            ),
            color: PartyColors.surface.withValues(alpha: 0.65),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 17,
                color: PartyColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${players.length} JUGADOR${players.length == 1 ? '' : 'ES'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: PartyColors.textSecondary,
                  ),
                ),
              ),
              if (players.length > 10) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '(se muestran 10)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: PartyColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarOrLetter extends StatelessWidget {
  final String playerName;
  const _AvatarOrLetter({required this.playerName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AvatarData?>(
      future: AvatarService.instance.getAvatar(playerName),
      builder: (context, snapshot) {
        final avatar = snapshot.data;
        if (avatar != null) {
          return _AvatarDisplay(avatar: avatar);
        }
        // fallback to initial while loading or if no avatar
        final letter = playerName.isNotEmpty ? playerName[0].toUpperCase() : '?';
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show letter meanwhile
          return _PlayerAvatar(letter: letter);
        }
        return _PlayerAvatar(letter: letter);
      },
    );
  }
}

class _AvatarDisplay extends StatelessWidget {
  final AvatarData avatar;
  const _AvatarDisplay({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return AvatarDisplay(avatar: avatar, size: 48);
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String letter;

  const _PlayerAvatar({
    required this.letter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PartyColors.surface,
        border: Border.all(
          color: PartyColors.primary.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PartyColors.text,
          ),
        ),
      ),
    );
  }
}
