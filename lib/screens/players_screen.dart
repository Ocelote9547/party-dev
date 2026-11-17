import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../services/avatar_service.dart';
import '../theme/party_theme.dart';
import '../widgets/avatar_display.dart';
import 'avatar_editor_screen.dart';

class PlayersScreen extends StatefulWidget {
  final List<String> players;
  final ValueChanged<String> onAddPlayer;
  final ValueChanged<int> onRemovePlayer;

  const PlayersScreen({
    super.key,
    required this.players,
    required this.onAddPlayer,
    required this.onRemovePlayer,
  });

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  int _avatarVersion = 0;

  void _showAddPlayerDialog(BuildContext context) {
    if (widget.players.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Máximo 10 jugadores'),
          backgroundColor: PartyColors.surface,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: PartyColors.surface,
          scrollable: true,
          title: const Text('Añadir jugador'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Nombre'),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    ).then((rawName) async {
      final name = (rawName ?? '').trim();
      controller.dispose();
      if (name.isEmpty) return;
      if (!mounted) return;
      // Evitar duplicados (insensible a mayúsculas) para no colisionar claves de avatar.
      final exists = widget.players.any((p) => p.trim().toLowerCase() == name.toLowerCase());
      if (exists) {
        messenger.showSnackBar(
          SnackBar(content: Text('"$name" ya existe'), backgroundColor: PartyColors.surface),
        );
        return;
      }
      widget.onAddPlayer(name);
      final existing = await AvatarService.instance.getAvatar(name);
      if (existing == null) {
        final def = AvatarService.instance.defaultAvatarFor(name);
        await AvatarService.instance.saveAvatar(name, def);
      }
      if (mounted) setState(() => _avatarVersion++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'JUGADORES',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      body: widget.players.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: PartyColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No hay jugadores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: PartyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añade jugadores para empezar',
                    style: TextStyle(fontSize: 13, color: PartyColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 220, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddPlayerDialog(context),
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      label: const Text('AÑADIR JUGADOR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PartyColors.primary,
                        foregroundColor: PartyColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: widget.players.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.players.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: widget.players.length >= 10
                            ? null
                            : () => _showAddPlayerDialog(context),
                        icon: const Icon(Icons.person_add_alt_1, size: 20),
                        label: Text(
                          widget.players.length >= 10 ? 'MÁXIMO 10 JUGADORES' : 'AÑADIR JUGADOR',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.players.length >= 10 ? PartyColors.surface : PartyColors.primary,
                          foregroundColor: widget.players.length >= 10 ? PartyColors.textMuted : PartyColors.background,
                          disabledBackgroundColor: PartyColors.surface,
                          disabledForegroundColor: PartyColors.textMuted,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  );
                }
                final player = widget.players[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PartyColors.border),
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: FutureBuilder<AvatarData?>(
                        key: ValueKey('avatar_${player}_$_avatarVersion'),
                        future: AvatarService.instance.getAvatar(player),
                        builder: (context, snapshot) {
                          final avatar = snapshot.data;
                          if (avatar != null) {
                            return AvatarDisplay(avatar: avatar, size: 40);
                          }
                          return CircleAvatar(
                          backgroundColor: PartyColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            player.isNotEmpty ? player[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: PartyColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    ),
                    title: Text(
                      player,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PartyColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: PartyColors.primary, size: 20),
                          tooltip: 'Editar avatar',
                          onPressed: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => AvatarEditorScreen(playerName: player)),
                            );
                            if (updated == true && mounted) {
                              setState(() => _avatarVersion++);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: PartyColors.textMuted, size: 20),
                          onPressed: () => widget.onRemovePlayer(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
