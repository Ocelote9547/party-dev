import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/party_theme.dart';
import '../services/score_storage.dart';

class LeaderboardScreen extends StatefulWidget {
  final List<String> players;
  const LeaderboardScreen({super.key, required this.players});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  ScoreStorage? _scoreStorage;
  Map<String, int> _scores = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final storage = ScoreStorage(prefs);
    _scoreStorage = storage;
    setState(() {
      _scores = storage.loadScores();
      _loaded = true;
    });
  }

  void _showAddPointsDialog() {
    if (!_loaded || _scoreStorage == null) return;
    String? selectedPlayer;
    final controller = TextEditingController();
    final error = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        title: Text('Sumar Puntos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PartyColors.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (ctx, setInnerState) => Column(
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.players.map((p) {
                        final selected = selectedPlayer == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: selected,
                          onSelected: (_) => setInnerState(() => selectedPlayer = p),
                          selectedColor: PartyColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: selected ? PartyColors.primary : PartyColors.text, fontWeight: FontWeight.w700),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: error,
                      builder: (_, hasError, val) => Column(
                        children: [
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PartyColors.text),
                            decoration: InputDecoration(
                              hintText: 'Puntos',
                              hintStyle: TextStyle(color: PartyColors.textMuted),
                              filled: true,
                              fillColor: PartyColors.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? PartyColors.danger : PartyColors.textMuted)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? PartyColors.danger : PartyColors.textMuted)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? PartyColors.danger : PartyColors.primary, width: 2)),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (hasError) ...[
                            const SizedBox(height: 4),
                            Text('Selecciona jugador y puntos', style: TextStyle(fontSize: 11, color: PartyColors.danger)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR', style: TextStyle(color: PartyColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final points = int.tryParse(controller.text.trim());
              if (selectedPlayer == null || points == null || points <= 0) {
                error.value = true;
                return;
              }
              final player = selectedPlayer!;
              final storage = _scoreStorage;
              if (storage == null) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                return;
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              _scores[player] = (_scores[player] ?? 0) + points;
              await storage.saveScores(_scores);
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('SUMAR', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ).then((_) {
      controller.dispose();
      error.dispose();
    });
  }

  void _showResetDialog() {
    if (!_loaded || _scoreStorage == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: PartyColors.border)),
        title: Text('¿Borrar todo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PartyColors.text)),
        content: Text('Se borrarán todas las puntuaciones guardadas.', style: TextStyle(color: PartyColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR', style: TextStyle(color: PartyColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final storage = _scoreStorage;
              if (storage == null) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                return;
              }
              await storage.resetScores();
              if (!mounted) return;
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() => _scores = {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: PartyColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('BORRAR', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('RANKING', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('RANKING', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [
          if (_scores.isNotEmpty)
            IconButton(
              onPressed: _showResetDialog,
              icon: Icon(Icons.delete_outline, color: PartyColors.textMuted),
            ),
        ],
      ),
      body: sorted.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('Sin puntuaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PartyColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Juega y suma puntos aquí', style: TextStyle(fontSize: 13, color: PartyColors.textMuted)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (sorted.isNotEmpty) ...[
                  _buildPodium(sorted),
                  const SizedBox(height: 24),
                ],
                Text('CLASIFICACIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: PartyColors.textMuted)),
                const SizedBox(height: 12),
                ...List.generate(sorted.length, (i) {
                  final entry = sorted[i];
                  final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: i < 3 ? PartyColors.primary.withValues(alpha: 0.3) : PartyColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (medal != null) ...[
                          Text(medal, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                        ] else ...[
                          SizedBox(
                            width: 30,
                            child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: Text(entry.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PartyColors.text))),
                        Text('${entry.value}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: i < 3 ? PartyColors.primary : PartyColors.text)),
                        Text(' pts', style: TextStyle(fontSize: 12, color: PartyColors.textMuted)),
                      ],
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPointsDialog,
        backgroundColor: PartyColors.primary,
        foregroundColor: PartyColors.onPrimary,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('SUMAR PUNTOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildPodium(List<MapEntry<String, int>> sorted) {
    if (sorted.length < 2) return const SizedBox.shrink();

    final first = sorted[0];
    final second = sorted.length > 1 ? sorted[1] : null;
    final third = sorted.length > 2 ? sorted[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          _buildPodiumColumn(second.key, second.value, '🥈', 100, PartyColors.textSecondary),
        _buildPodiumColumn(first.key, first.value, '🥇', 130, PartyColors.primary),
        if (third != null)
          _buildPodiumColumn(third.key, third.value, '🥉', 80, PartyColors.warning),
      ],
    );
  }

  Widget _buildPodiumColumn(String name, int points, String medal, double height, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('$points pts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.textMuted)),
          const SizedBox(height: 6),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
