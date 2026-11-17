// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';
import '../widgets/animated_party_background.dart';
import 'game_utils.dart';
import '../services/economy_service.dart';

enum NightActionType {
  ladronSwap,
  cupidoPair,
  loboKill,
  medicoProtect,
  brujaDecide,
  videnteInvestigate,
  aldeanoSleep,
}

class _NightAction {
  final String playerName;
  final String role;
  final NightActionType actionType;
  const _NightAction({
    required this.playerName,
    required this.role,
    required this.actionType,
  });
}

class _NightLogEntry {
  final String text;
  final IconData icon;
  const _NightLogEntry(this.text, this.icon);
}

class PuebloDuermeGame extends StatefulWidget {
  final List<String> players;
  const PuebloDuermeGame({super.key, required this.players});

  @override
  State<PuebloDuermeGame> createState() => _PuebloDuermeGameState();
}

class _PuebloDuermeGameState extends State<PuebloDuermeGame> {
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  bool _showInstructions = true;
  bool _showRoleSelection = false;
  late List<String> _shuffledPlayers;
  final Map<String, String> _assignedRoles = {};

  int _currentPlayerIndex = 0;
  bool _showingRole = false;
  bool _setupDone = false;

  bool _videnteEnabled = true;
  bool _cupidoEnabled = true;
  bool _medicoEnabled = true;
  bool _cazadorEnabled = true;
  bool _ladronEnabled = true;
  bool _brujaEnabled = true;

  int _dayCount = 0;
  bool _isNightPhase = false;
  List<_NightAction> _nightActionQueue = [];
  int _currentNightActionIndex = 0;
  bool _nightTapRevealed = false;

  bool _showDawnLog = false;
  bool _showVoteScreen = false;
  String? _voteResult;

  String? _cupidoLover1;
  String? _cupidoLover2;
  bool get _cupidoPaired => _cupidoLover1 != null && _cupidoLover2 != null;

  final Set<String> _deadPlayers = {};
  final List<_NightLogEntry> _nightLog = [];

  /// Cola de muertes pendientes de confirmar (revelar rol).
  /// Cada muerte muestra un diálogo "X ha muerto — era: ROL" con CONTINUAR.
  final List<String> _pendingReveals = [];

  String? _wolfKillTarget;
  String? _medicProtegeTarget;
  String? _videnteInvestigateTarget;

  bool _ladronUsed = false;

  bool _brujaReviveUsed = false;
  bool _brujaKillUsed = false;
  bool _brujasChoseToRevive = false;
  String? _brujasChoseKillTarget;

  bool _cazadorRevengeUsed = false;

  int get _wolfCount {
    final n = _shuffledPlayers.length;
    if (n >= 9) return 3;
    if (n >= 5) return 2;
    return 1;
  }

  List<String> get _activeOptionalRoles {
    final wc = _wolfCount;
    final n = _shuffledPlayers.length;
    final roles = <String>[];
    if (wc <= 2) {
      // Con 2 lobos (o 1) → solo 3 roles especiales: Vidente, Cupido y Ladrón
      if (n >= 5 && _videnteEnabled) roles.add('Vidente');
      if (_cupidoEnabled) roles.add('Cupido');
      if (_ladronEnabled) roles.add('Ladrón');
    } else {
      // Con 3 lobos → 6 roles especiales completos (Cazador reemplaza a Detective)
      if (n >= 5 && _videnteEnabled) roles.add('Vidente');
      if (_cupidoEnabled) roles.add('Cupido');
      if (_medicoEnabled) roles.add('Médico');
      if (_cazadorEnabled) roles.add('Cazador');
      if (_ladronEnabled) roles.add('Ladrón');
      if (_brujaEnabled) roles.add('Bruja');
    }
    return roles;
  }

  List<String> get _availableRoles {
    final n = _shuffledPlayers.length;
    final roles = <String>[];
    for (var i = 0; i < _wolfCount; i++) {
      roles.add('Lobo');
    }
    roles.addAll(_activeOptionalRoles);
    while (roles.length < n) {
      roles.add('Aldeano');
    }
    int villagerCount = roles.where((r) => r == 'Aldeano').length;
    int optionalCount = roles.length - _wolfCount - villagerCount;
    while (villagerCount < 2 && optionalCount > 0) {
      for (int i = roles.length - 1; i >= 0; i--) {
        if (roles[i] != 'Lobo' && roles[i] != 'Aldeano') {
          roles[i] = 'Aldeano';
          villagerCount++;
          optionalCount--;
          break;
        }
      }
    }
    return List<String>.from(roles)..shuffle();
  }

  List<String> get _alivePlayers =>
      _shuffledPlayers.where((p) => !_deadPlayers.contains(p)).toList();

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'MISTERIO'); } catch (_) {}
    _shuffledPlayers = List.from(widget.players)..shuffle();
  }

  @override
  void dispose() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.dispose();
  }

  @override
  void deactivate() {
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.deactivate();
  }

  void _assignRoles() {
    final roles = _availableRoles;
    _assignedRoles.clear();
    for (var i = 0; i < _shuffledPlayers.length && i < roles.length; i++) {
      _assignedRoles[_shuffledPlayers[i]] = roles[i];
    }
  }

  String get _currentPlayer => _shuffledPlayers[_currentPlayerIndex];
  String get _currentRole => _assignedRoles[_currentPlayer] ?? 'Aldeano';

  void _startGame() => setState(() {
    _showInstructions = false;
    _showRoleSelection = true;
  });

  void _revealRole() => setState(() => _showingRole = true);

  void _nextPlayer() {
    setState(() {
      _showingRole = false;
      _currentPlayerIndex++;
      if (_currentPlayerIndex >= _shuffledPlayers.length) {
        _setupDone = true;
      }
    });
  }

  void _buildNightQueue() {
    _nightActionQueue = [];
    _currentNightActionIndex = 0;
    _nightTapRevealed = false;
    _wolfKillTarget = null;
    _medicProtegeTarget = null;
    _videnteInvestigateTarget = null;
    _brujasChoseToRevive = false;
    _brujasChoseKillTarget = null;
    _showDawnLog = false;
    _showVoteScreen = false;
    _voteResult = null;
    _nightLog.clear();

    final alive = _alivePlayers;
    final isFirstNight = _dayCount == 0;

    if (_ladronEnabled && !_ladronUsed && isFirstNight) {
      final ladron = alive
          .where((p) => _assignedRoles[p] == 'Ladrón')
          .toList();
      if (ladron.isNotEmpty) {
        _nightActionQueue.add(_NightAction(
          playerName: ladron.first,
          role: 'Ladrón',
          actionType: NightActionType.ladronSwap,
        ));
      }
    }

    if (isFirstNight && _cupidoEnabled) {
      final cupido = alive
          .where((p) => _assignedRoles[p] == 'Cupido')
          .toList();
      if (cupido.isNotEmpty) {
        _nightActionQueue.add(_NightAction(
          playerName: cupido.first,
          role: 'Cupido',
          actionType: NightActionType.cupidoPair,
        ));
      }
    }

    final wolves = alive
        .where((p) => _assignedRoles[p] == 'Lobo')
        .toList();
    if (wolves.isNotEmpty) {
      _nightActionQueue.add(_NightAction(
        playerName: wolves.first,
        role: 'Lobo',
        actionType: NightActionType.loboKill,
      ));
    }

    if (_medicoEnabled) {
      final medic = alive
          .where((p) => _assignedRoles[p] == 'Médico')
          .toList();
      if (medic.isNotEmpty) {
        _nightActionQueue.add(_NightAction(
          playerName: medic.first,
          role: 'Médico',
          actionType: NightActionType.medicoProtect,
        ));
      }
    }

    if (_brujaEnabled) {
      final bruja = alive
          .where((p) => _assignedRoles[p] == 'Bruja')
          .toList();
      if (bruja.isNotEmpty) {
        _nightActionQueue.add(_NightAction(
          playerName: bruja.first,
          role: 'Bruja',
          actionType: NightActionType.brujaDecide,
        ));
      }
    }

    if (_videnteEnabled) {
      final vidente = alive
          .where((p) => _assignedRoles[p] == 'Vidente')
          .toList();
      if (vidente.isNotEmpty) {
        _nightActionQueue.add(_NightAction(
          playerName: vidente.first,
          role: 'Vidente',
          actionType: NightActionType.videnteInvestigate,
        ));
      }
    }

    for (final p in alive) {
      final role = _assignedRoles[p] ?? 'Aldeano';
      if (role == 'Aldeano' ||
          role == 'Cazador' ||
          (role == 'Cupido' && !isFirstNight)) {
        _nightActionQueue.add(_NightAction(
          playerName: p,
          role: role,
          actionType: NightActionType.aldeanoSleep,
        ));
      }
    }
  }

  _NightAction? get _currentNightAction {
    if (_currentNightActionIndex >= _nightActionQueue.length) return null;
    return _nightActionQueue[_currentNightActionIndex];
  }

  void _advanceNightAction() {
    _currentNightActionIndex++;
    _nightTapRevealed = false;
  }

  void _checkNightQueueOrResolve() {
    if (_currentNightActionIndex >= _nightActionQueue.length) {
      _resolveNight();
      return;
    }
    final action = _currentNightAction;
    if (action == null) {
      _resolveNight();
      return;
    }
    if (action.actionType != NightActionType.aldeanoSleep) {
      final currentRole = _assignedRoles[action.playerName];
      if (currentRole != action.role) {
        _advanceNightAction();
        _checkNightQueueOrResolve();
        return;
      }
    }
    setState(() {});
  }

  void _killPlayer(String player, List<_NightLogEntry> log) {
    if (_deadPlayers.contains(player)) return;
    _deadPlayers.add(player);
    if (_cupidoPaired && _cupidoLover1 != null && _cupidoLover2 != null) {
      String? lover;
      if (player == _cupidoLover1) lover = _cupidoLover2;
      if (player == _cupidoLover2) lover = _cupidoLover1;
      if (lover != null && !_deadPlayers.contains(lover)) {
        _deadPlayers.add(lover);
        log.add(_NightLogEntry(
          '💘 El amor verdadero: $lover también muere',
          Icons.favorite,
        ));
      }
    }
  }

  void _resolveNight() {
    final log = <_NightLogEntry>[];
    final beforeDead = Set<String>.from(_deadPlayers);

    if (_cupidoPaired && _cupidoLover1 != null && _cupidoLover2 != null) {
      log.add(_NightLogEntry(
        '💘 Cupido unió a $_cupidoLover1 y $_cupidoLover2',
        Icons.favorite,
      ));
    }

    if (_medicProtegeTarget != null) {
      log.add(_NightLogEntry(
        '💊 El médico protegió a $_medicProtegeTarget',
        Icons.medical_services,
      ));
    }

    if (_wolfKillTarget != null) {
      if (_brujasChoseToRevive) {
        log.add(_NightLogEntry(
          '🧙 La bruja revivió a $_wolfKillTarget',
          Icons.auto_fix_high,
        ));
        _wolfKillTarget = null;
      } else if (_medicProtegeTarget == _wolfKillTarget) {
        log.add(_NightLogEntry(
          '🛡️ ¡El médico salvó a $_wolfKillTarget!',
          Icons.shield,
        ));
        _wolfKillTarget = null;
      } else {
        log.add(_NightLogEntry(
          '🐺 Los lobos devoraron a $_wolfKillTarget',
          Icons.pets,
        ));
        _killPlayer(_wolfKillTarget!, log);
      }
    }

    if (_brujasChoseKillTarget != null) {
      log.add(_NightLogEntry(
        '🧙 La bruja envenenó a $_brujasChoseKillTarget',
        Icons.auto_fix_high,
      ));
      _killPlayer(_brujasChoseKillTarget!, log);
    }

    if (_videnteInvestigateTarget != null) {
      log.add(_NightLogEntry(
        '👁️ La vidente investigó a un jugador',
        Icons.visibility,
      ));
    }

    // Muertes nuevas de esta noche: se confirman revelando sus roles.
    // La venganza del cazador (si murió) se encadena tras su revelación.
    final newlyDead = _deadPlayers.difference(beforeDead);
    _checkWinCondition();

    try { SoundService.instance.stopAmbient(); } catch (_) {}
    setState(() {
      _nightLog.clear();
      _nightLog.addAll(log);
      _isNightPhase = false;
      _showDawnLog = true;
    });

    _queueDeathReveals(newlyDead);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNextDeathReveal());
  }

  void _showHunterRevengeDialog(String hunterName) {
    if (_cazadorRevengeUsed) return;
    final alive = _alivePlayers;
    if (alive.isEmpty) return;
    _cazadorRevengeUsed = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Text('🏹 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                '$hunterName — Cazador',
                style: const TextStyle(fontSize: 18, color: Color(0xFFEA580C)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🏹 ¡El Cazador ha muerto! Antes de caer, puede llevarse a alguien con él.',
                style: TextStyle(fontSize: 13, color: Color(0xFFEA580C), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Elige a quién disparas:',
              style: TextStyle(fontSize: 14, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...alive.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final before = Set<String>.from(_deadPlayers);
                        final log = <_NightLogEntry>[];
                        _killPlayer(p, log);
                        setState(() {
                          if (log.isNotEmpty) _nightLog.addAll(log);
                          _nightLog.add(_NightLogEntry('🏹 El cazador $hunterName se llevó a $p consigo', Icons.gps_fixed));
                          _checkWinCondition();
                        });
                        // Confirmar también la muerte de la víctima.
                        _queueDeathReveals(_deadPlayers.difference(before));
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _showNextDeathReveal());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.text,
                        side: BorderSide(color: PartyColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(p, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
            // Si el grupo prefiere no disparar, no permitir: cazador siempre dispara si puede; pero ofrecemos pasar si no hay objetivos viables
          ],
        ),
      ),
    );
  }

  void _triggerHunterRevengeIfNeeded(String deadPlayer) {
    if (_cazadorRevengeUsed) return;
    if (_assignedRoles[deadPlayer] != 'Cazador') return;
    if (_voteResult != null) return;
    // Si el voto ya decidió la partida pero el cazador murió, aún muestra venganza antes del GameOver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_cazadorRevengeUsed) {
        _showHunterRevengeDialog(deadPlayer);
        // Re-evaluar victoria tras la venganza se hace dentro del diálogo
      }
    });
  }

  /// Encola revelados de rol para muertes recién producidas (sin duplicados).
  void _queueDeathReveals(Iterable<String> dead) {
    for (final p in dead) {
      if (!_pendingReveals.contains(p)) _pendingReveals.add(p);
    }
  }

  /// Muestra el siguiente diálogo de confirmación de muerte:
  /// "X ha muerto — era: ROL". Al confirmar encadena venganza/revelados.
  void _showNextDeathReveal() {
    if (!mounted || _pendingReveals.isEmpty) return;
    final player = _pendingReveals.removeAt(0);
    final role = _assignedRoles[player] ?? 'Aldeano';
    final color = _getRoleColor(role);
    final icon = _getRoleIcon(role);
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        title: const Text(
          '☠️ MUERTE CONFIRMADA',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              player,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: PartyColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'era:',
              style: TextStyle(fontSize: 13, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$icon $role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: PartyColors.primary,
                foregroundColor: PartyColors.onPrimary,
              ),
              child: const Text('CONTINUAR'),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (!mounted) return;
      _afterDeathReveal(player);
    });
  }

  /// Tras confirmar una muerte: venganza del cazador si aplica y
  /// encadena el siguiente revelado pendiente.
  void _afterDeathReveal(String player) {
    if (_assignedRoles[player] == 'Cazador' &&
        !_cazadorRevengeUsed &&
        _voteResult == null) {
      _triggerHunterRevengeIfNeeded(player);
    }
    _showNextDeathReveal();
  }

  void _checkWinCondition() {
    final wolvesAlive =
        _alivePlayers.where((p) => _assignedRoles[p] == 'Lobo').length;
    final villagersAlive = _alivePlayers.length - wolvesAlive;
    if (wolvesAlive == 0) {
      _voteResult = '¡Los aldeanos ganan! Todos los lobos han sido eliminados.';
      // ignore: discarded_futures
      _handleGameCompleted();
    } else if (wolvesAlive >= villagersAlive) {
      _voteResult =
          '¡Los lobos ganan! Han igualado o superado a los aldeanos.';
      // ignore: discarded_futures
      _handleGameCompleted();
    }
  }

  void _showWolfKillDialog() {
    final allWolves = _alivePlayers
        .where((p) => _assignedRoles[p] == 'Lobo')
        .toList();
    final wolfNames = allWolves.join(', ');
    final targets =
        _alivePlayers.where((p) => _assignedRoles[p] != 'Lobo').toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Text('🐺 ', style: TextStyle(fontSize: 24)),
            const Expanded(
              child: Text(
                'Los Lobos',
                style: TextStyle(
                    fontSize: 18, color: PartyColors.danger),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PartyColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🐺 $wolfNames',
                style: const TextStyle(
                  fontSize: 13,
                  color: PartyColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Los lobos eligen juntos a quién devorar.',
              style: TextStyle(
                  fontSize: 14, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...targets.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _wolfKillTarget = p;
                          _advanceNightAction();
                        });
                        _checkNightQueueOrResolve();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.text,
                        side: BorderSide(color: PartyColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(p,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showMedicProtectDialog(String medicName) {
    final targets =
        _alivePlayers.where((p) => p != medicName).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Text('💊 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                medicName,
                style: TextStyle(
                    fontSize: 18, color: PartyColors.success),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Protege a un jugador del lobo esta noche.',
              style: TextStyle(
                  fontSize: 14, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...targets.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _medicProtegeTarget = p;
                          _advanceNightAction();
                        });
                        _checkNightQueueOrResolve();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.text,
                        side: BorderSide(color: PartyColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(p,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showBrujaDecideDialog(String brujaName) {
    final wolfTarget = _wolfKillTarget;
    final canRevive =
        wolfTarget != null && !_brujaReviveUsed;
    final canKill = !_brujaKillUsed;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Text('🧙 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                brujaName,
                style: const TextStyle(
                    fontSize: 18, color: PartyColors.purple),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wolfTarget != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PartyColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🐺 Los lobos atacaron a $wolfTarget',
                  style: const TextStyle(
                    fontSize: 13,
                    color: PartyColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Los lobos no atacaron a nadie esta noche.',
                style: TextStyle(
                    fontSize: 14, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
            if (canRevive)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() {
                        _brujasChoseToRevive = true;
                        _brujaReviveUsed = true;
                        _advanceNightAction();
                      });
                      _checkNightQueueOrResolve();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      '🟢 REVIVIR A $wolfTarget',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            if (canKill)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _showBrujaKillSubDialog(brujaName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '🔴 MATAR A ALGUIEN',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() {
                    _advanceNightAction();
                  });
                  _checkNightQueueOrResolve();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: PartyColors.textSecondary,
                  side: BorderSide(color: PartyColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'NO HACER NADA',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrujaKillSubDialog(String brujaName) {
    final targets = _alivePlayers
        .where((p) =>
            p != brujaName &&
            p != _cupidoLover1 &&
            p != _cupidoLover2)
        .toList();

    if (targets.isEmpty) {
      setState(() {
        _advanceNightAction();
      });
      _checkNightQueueOrResolve();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: const Row(
          children: [
            Text('🧙 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                'Bruja - Envenenar',
                style: TextStyle(
                    fontSize: 18, color: PartyColors.purple),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige a quién envenenar.',
              style: TextStyle(
                  fontSize: 14, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...targets.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _brujasChoseKillTarget = p;
                          _brujaKillUsed = true;
                          _advanceNightAction();
                        });
                        _checkNightQueueOrResolve();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.text,
                        side: BorderSide(
                            color: PartyColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: Text(p,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showVidenteInvestigateDialog(String videnteName) {
    final targets = _alivePlayers
        .where((p) => p != videnteName)
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Text('👁️ ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                videnteName,
                style: TextStyle(
                    fontSize: 18,
                    color: PartyColors.primaryLight),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige a quién investigar para descubrir su rol.',
              style: TextStyle(
                  fontSize: 14, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...targets.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final role =
                            _assignedRoles[p] ?? 'Aldeano';
                        final roleData =
                            GameData.puebloDuermeRoles[role];
                        final roleColor = roleData != null
                            ? Color(roleData.color)
                            : PartyColors.text;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx2) => AlertDialog(
                            backgroundColor: PartyColors.surface,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  roleData?.icon ?? '👤',
                                  style: const TextStyle(
                                      fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: PartyColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: roleColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  roleData?.description ?? '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: PartyColors
                                        .textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx2);
                                    setState(() {
                                      _videnteInvestigateTarget =
                                          p;
                                      _advanceNightAction();
                                    });
                                    _checkNightQueueOrResolve();
                                  },
                                  style: ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                        PartyColors.primary,
                                    foregroundColor:
                                        PartyColors.background,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                14)),
                                  ),
                                  child: const Text(
                                    'CONTINUAR',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                        letterSpacing: 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.text,
                        side: BorderSide(
                            color: PartyColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: Text(p,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showCupidoPairDialog(String cupidoName) {
    final targets = _alivePlayers
        .where((p) => p != cupidoName)
        .toList();
    String? selected1;
    String? selected2;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: PartyColors.surface,
          title: Row(
            children: [
              const Text('💘 ', style: TextStyle(fontSize: 24)),
              Expanded(
                child: Text(
                  cupidoName,
                  style: const TextStyle(
                      fontSize: 18, color: PartyColors.love),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                selected1 == null
                    ? 'Elige al primer jugador:'
                    : 'Elige al segundo jugador:',
                style: TextStyle(
                    fontSize: 14,
                    color: PartyColors.textSecondary),
              ),
              if (selected1 != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PartyColors.love.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: PartyColors.love
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '💘 $selected1',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PartyColors.love,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...targets
                  .where((p) => p != selected1)
                  .map((p) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () async {
                              if (selected1 == null) {
                                setDialogState(
                                    () => selected1 = p);
                              } else {
                                selected2 = p;
                                Navigator.pop(ctx2);
                                setState(() {
                                  _cupidoLover1 = selected1;
                                  _cupidoLover2 = selected2;
                                  _advanceNightAction();
                                });
                                _checkNightQueueOrResolve();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  PartyColors.text,
                              side: BorderSide(
                                  color:
                                      PartyColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          14)),
                            ),
                            child: Text(p,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w600)),
                          ),
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }

  void _showLadronSwapDialog(String ladronName) {
    final targets = _alivePlayers
        .where((p) => p != ladronName)
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        title: Row(
          children: [
            const Text('🗡️ ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                ladronName,
                style: const TextStyle(
                    fontSize: 18, color: PartyColors.warning),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige a quién intercambiar tu rol. El otro pasará a ser Aldeano.',
              style: TextStyle(
                  fontSize: 14, color: PartyColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...targets.map((p) {
              final targetRole =
                  _assignedRoles[p] ?? 'Aldeano';
              final roleData =
                  GameData.puebloDuermeRoles[targetRole];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _confirmLadronSwap(
                          ladronName, p, targetRole);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PartyColors.text,
                      side: BorderSide(
                          color: PartyColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          roleData?.icon ?? '👤',
                          style:
                              const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$p ($targetRole)',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() {
                    _ladronUsed = true;
                    _advanceNightAction();
                  });
                  _checkNightQueueOrResolve();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: PartyColors.textSecondary,
                  side: BorderSide(
                      color: PartyColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                ),
                child: const Text(
                  'NO INTERCAMBIAR',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLadronSwap(
      String ladronName, String targetName, String targetRole) {
    final ladronRole = _assignedRoles[ladronName] ?? 'Ladrón';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗡️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '¿Intercambiar roles?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PartyColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$ladronRole ↔ $targetRole',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: PartyColors.warning,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$ladronName ←→ $targetName',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: PartyColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  _assignedRoles[ladronName] = targetRole;
                  _assignedRoles[targetName] = 'Aldeano';
                  _ladronUsed = true;
                  _advanceNightAction();
                });
                _checkNightQueueOrResolve();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PartyColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleActionDialog(_NightAction action) {
    switch (action.actionType) {
      case NightActionType.ladronSwap:
        _showLadronSwapDialog(action.playerName);
        break;
      case NightActionType.cupidoPair:
        _showCupidoPairDialog(action.playerName);
        break;
      case NightActionType.loboKill:
        _showWolfKillDialog();
        break;
      case NightActionType.medicoProtect:
        _showMedicProtectDialog(action.playerName);
        break;
      case NightActionType.brujaDecide:
        _showBrujaDecideDialog(action.playerName);
        break;
      case NightActionType.videnteInvestigate:
        _showVidenteInvestigateDialog(action.playerName);
        break;
      case NightActionType.aldeanoSleep:
        break;
    }
  }

    @override
  Widget build(BuildContext context) {
    if (widget.players.length < 4) return const NeedPlayersScreen(minPlayers: 4);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PartyColors.surface,
            title: Text('¿Seguro que quieres salir?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderás el progreso', style: TextStyle(color: PartyColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.danger), child: const Text('Salir')),
            ],
          ),
        );
        if (shouldPop == true) {
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    if (_showInstructions) {
      return GameInstructions(
        emoji: '🌙',
        title: 'PUEBLO DUERME',
        subtitle:
            'Un pueblo donde los lobos están entre vosotros. Descubrid quién miente.',
        steps: [
                'Mínimo 4 jugadores. Con 4 solo hay Lobos y Aldeanos; con 5 se desbloquea la Vidente y con 6 o más, todos los roles opcionales.',
          'Cada jugador recibe un rol secreto (solo él lo ve).',
          'Los roles especiales actúan por la noche en orden.',
          'Los Lobos eligen juntos a quién devorar (una sola víctima).',
          'Por la mañana, el pueblo debate y vota a quién eliminar.',
        ],
        onStart: _startGame,
      );
    }
    if (_showRoleSelection) return _buildRoleSelection();
    if (!_setupDone) return _buildRoleReveal();
    if (_isNightPhase) return _buildNightPhase();
    if (_showDawnLog) return _buildDawnLog();
    if (_voteResult != null) return _buildGameOver();
    if (_showVoteScreen) return _buildVoteScreen();
    return _buildDayTransition();
  
        },
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ROLES',
          style: TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              32,
              32,
              32 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text('🌙', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Selecciona roles opcionales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lobo y Aldeano siempre activos. ($_wolfCount lobo${_wolfCount > 1 ? 's' : ''} con ${_shuffledPlayers.length} jugadores)',
                style: TextStyle(
                    fontSize: 14,
                    color: PartyColors.textSecondary),
              ),
              if (_shuffledPlayers.length == 5) ...[
                const SizedBox(height: 8),
                Text(
                  '5 jugadores: solo Vidente disponible. Con más jugadores se desbloquean más roles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PartyColors.warning),
                ),
              ],
              const SizedBox(height: 32),
              if (_shuffledPlayers.length <= 4)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PartyColors.border),
                    ),
                    child: Text(
                      'Solo Lobo y Aldeano con 4 jugadores',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PartyColors.textSecondary),
                    ),
                  ),
                )
              else if (_wolfCount == 2) ...[
                _roleToggle(
                  '👁️ Vidente',
                  'Descubre el rol de un jugador cada noche.',
                  _videnteEnabled,
                  (v) => setState(() => _videnteEnabled = v),
                ),
                _roleToggle(
                  '💘 Cupido',
                  'Une a dos jugadores. Si uno muere, el otro también.',
                  _cupidoEnabled,
                  (v) => setState(() => _cupidoEnabled = v),
                ),
                _roleToggle(
                  '🗡️ Ladrón',
                  'Intercambia tu rol con otro jugador una vez.',
                  _ladronEnabled,
                  (v) => setState(() => _ladronEnabled = v),
                ),
              ] else ...[
                _roleToggle(
                  '👁️ Vidente',
                  'Descubre el rol de un jugador cada noche.',
                  _videnteEnabled,
                  (v) => setState(() => _videnteEnabled = v),
                ),
                _roleToggle(
                  '💘 Cupido',
                  'Une a dos jugadores. Si uno muere, el otro también.',
                  _cupidoEnabled,
                  (v) => setState(() => _cupidoEnabled = v),
                ),
                _roleToggle(
                  '💊 Médico',
                  'Protege a un jugador cada noche del lobo.',
                  _medicoEnabled,
                  (v) => setState(() => _medicoEnabled = v),
                ),
                _roleToggle(
                  '🏹 Cazador',
                  'Si mueres, puedes llevarte a alguien contigo al instante.',
                  _cazadorEnabled,
                  (v) => setState(() => _cazadorEnabled = v),
                ),
                _roleToggle(
                  '🗡️ Ladrón',
                  'Intercambia tu rol con otro jugador una vez.',
                  _ladronEnabled,
                  (v) => setState(() => _ladronEnabled = v),
                ),
                _roleToggle(
                  '🧙 Bruja',
                  'Revive a alguien o mata a otro. Cada habilidad una vez.',
                  _brujaEnabled,
                  (v) => setState(() => _brujaEnabled = v),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_shuffledPlayers.length < 4) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Mínimo 4 jugadores para jugar.',
                            style: TextStyle(
                                color: Colors.white),
                          ),
                          backgroundColor:
                              PartyColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _showRoleSelection = false;
                      _assignRoles();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _roleToggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: PartyColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PartyColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? PartyColors.text
                              : PartyColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              PartyColors.textSecondary)),
                ],
              ),
            ),
            Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: PartyColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleReveal() {
    final roleData =
        GameData.puebloDuermeRoles[_currentRole];
    final roleColor =
        Color(roleData?.color ?? 0xFF25E6D0);
    final isLastPlayer =
        _currentPlayerIndex >= _shuffledPlayers.length - 1;

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PUEBLO DUERME',
          style: TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentPlayer,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pasa el móvil para ver tu rol',
                style: TextStyle(
                    fontSize: 14,
                    color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 48),
              if (!_showingRole)
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _revealRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartyColors.primary,
                      foregroundColor:
                          PartyColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'TAP PARA VER TU ROL',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1),
                    ),
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    32,
                    32,
                    32,
                    32 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius:
                        BorderRadius.circular(24),
                    border: Border.all(
                        color: roleColor
                            .withValues(alpha: 0.5),
                        width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(roleData?.icon ?? '👤',
                          style: const TextStyle(
                              fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        _currentRole,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: roleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        roleData?.description ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: PartyColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          PartyColors.surface,
                      foregroundColor:
                          PartyColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                        side: BorderSide(
                            color:
                                PartyColors.border),
                      ),
                    ),
                    child: Text(
                      isLastPlayer
                          ? 'EMPEZAR NOCHE 1'
                          : 'SIGUIENTE JUGADOR',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayTransition() {
    final nightNumber = _dayCount + 1;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _dayCount == 0 ? '🌙' : '☀️',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 24),
              Text(
                _dayCount == 0
                    ? 'La noche cae...'
                    : 'Noche $nightNumber',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'El pueblo duerme. Los roles especiales despertarán uno a la vez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: PartyColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    try { SoundService.instance.playAmbientLoop(category: 'MISTERIO'); } catch (_) {}
                    setState(() {
                      _isNightPhase = true;
                      _buildNightQueue();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor:
                        PartyColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20)),
                  ),
                  child: Text(
                    _dayCount == 0
                        ? 'EMPEZAR NOCHE 1'
                        : 'PASAR A LA NOCHE',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildNightPhase() {
    final action = _currentNightAction;
    if (action == null) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        body: AnimatedPartyBackground(child: Center(
            child: CircularProgressIndicator(
                color: PartyColors.primary))),
      );
    }

    final nightNumber = _dayCount + 1;

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'NOCHE $nightNumber',
          style: const TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_nightTapRevealed) ...[
                const Text('🌙',
                    style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  'Pasa el móvil a',
                  style: TextStyle(
                      fontSize: 16,
                      color: PartyColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  action.actionType ==
                          NightActionType.loboKill
                      ? 'Los Lobos'
                      : action.playerName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRoleColor(action.role)
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                        color: _getRoleColor(action.role)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${_getRoleIcon(action.role)} ${action.role}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          _getRoleColor(action.role),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() =>
                          _nightTapRevealed = true);
                      if (action.actionType ==
                          NightActionType
                              .aldeanoSleep) {
                        Future.delayed(
                            const Duration(seconds: 3),
                            () {
                          if (mounted &&
                              _nightTapRevealed &&
                              _currentNightAction
                                      ?.actionType ==
                                  NightActionType
                                      .aldeanoSleep) {
                            setState(() =>
                                _advanceNightAction());
                            _checkNightQueueOrResolve();
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _getRoleColor(action.role),
                      foregroundColor:
                          PartyColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  20)),
                    ),
                    child: const Text(
                      'TAP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    32,
                    32,
                    32,
                    32 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: PartyColors.surface,
                    borderRadius:
                        BorderRadius.circular(24),
                    border: Border.all(
                      color: _getRoleColor(
                              action.role)
                          .withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        action.actionType ==
                                NightActionType
                                    .loboKill
                            ? '🐺'
                            : _getRoleIcon(
                                action.role),
                        style: const TextStyle(
                            fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        action.actionType ==
                                NightActionType
                                    .loboKill
                            ? 'Los Lobos'
                            : action.playerName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: PartyColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.role,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _getRoleColor(
                              action.role),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getRoleDescription(
                            action.actionType),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: PartyColors
                              .textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (action.actionType ==
                    NightActionType.aldeanoSleep)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() =>
                            _advanceNightAction());
                        _checkNightQueueOrResolve();
                      },
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                            PartyColors.surface,
                        foregroundColor:
                            PartyColors.text,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  20),
                          side: BorderSide(
                              color: PartyColors
                                  .border),
                        ),
                      ),
                      child: const Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        _showRoleActionDialog(
                            action);
                      },
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                            _getRoleColor(
                                action.role),
                        foregroundColor:
                            PartyColors.background,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    20)),
                      ),
                      child: Text(
                        _getActionButtonText(
                            action.actionType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              _buildNightProgress(),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildNightProgress() {
    final total = _nightActionQueue.length;
    final current =
        _currentNightActionIndex.clamp(0, total);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDone
                  ? PartyColors.primary
                  : isActive
                      ? PartyColors.primaryLight
                      : PartyColors.textMuted
                          .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Lobo':
        return PartyColors.danger;
      case 'Vidente':
        return PartyColors.primary;
      case 'Cupido':
        return PartyColors.love;
      case 'Médico':
        return PartyColors.success;
      case 'Cazador':
        return const Color(0xFFEA580C);
      case 'Ladrón':
        return PartyColors.warning;
      case 'Bruja':
        return PartyColors.purple;
      default:
        return PartyColors.primary;
    }
  }

  String _getRoleIcon(String role) {
    switch (role) {
      case 'Lobo':
        return '🐺';
      case 'Vidente':
        return '👁️';
      case 'Cupido':
        return '💘';
      case 'Médico':
        return '💊';
      case 'Cazador':
        return '🏹';
      case 'Ladrón':
        return '🗡️';
      case 'Bruja':
        return '🧙';
      default:
        return '👤';
    }
  }

  String _getRoleDescription(NightActionType type) {
    switch (type) {
      case NightActionType.ladronSwap:
        return 'Intercambia tu rol con otro jugador.\nEl otro pasará a ser Aldeano.';
      case NightActionType.cupidoPair:
        return 'Une a dos jugadores con el amor verdadero.\nSi uno muere, el otro también.';
      case NightActionType.medicoProtect:
        return 'Protege a un jugador del lobo esta noche.\nElige con sabiduría.';
      case NightActionType.loboKill:
        return 'Los lobos eligen a quién devorar.\nTodos los lobos acuerdan una sola víctima.';
      case NightActionType.brujaDecide:
        return 'Puedes revivir a alguien o matar a otro.\nCada habilidad solo se usa una vez.';
      case NightActionType.videnteInvestigate:
        return 'Elige a un jugador para descubrir su rol.';
      case NightActionType.aldeanoSleep:
        return 'Duermes tranquilo. Espera al amanecer.';
    }
  }

  String _getActionButtonText(NightActionType type) {
    switch (type) {
      case NightActionType.ladronSwap:
        return 'INTERCAMBIAR ROL';
      case NightActionType.cupidoPair:
        return 'UNIR A JUGADORES';
      case NightActionType.medicoProtect:
        return 'PROTEGER A ALGUIEN';
      case NightActionType.loboKill:
        return 'ELEGIR VÍCTIMA';
      case NightActionType.brujaDecide:
        return 'DECIDIR';
      case NightActionType.videnteInvestigate:
        return 'INVESTIGAR A ALGUIEN';
      case NightActionType.aldeanoSleep:
        return 'CONTINUAR';
    }
  }

  Widget _buildDawnLog() {
    final hasGameEnded = _voteResult != null;
    final dayNumber = _dayCount + 1;

    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AMANECER',
          style: TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('☀️',
                  style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Día $dayNumber',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 12),
              if (_nightLog.isEmpty)
                Text(
                  'No ha pasado nada esta noche.',
                  style: TextStyle(
                      fontSize: 16,
                      color:
                          PartyColors.textSecondary),
                )
              else
                ..._nightLog.map((entry) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PartyColors.surface,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  PartyColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(entry.icon,
                                size: 24,
                                color: PartyColors
                                    .primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: PartyColors
                                      .text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 12),
              if (_deadPlayers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PartyColors.danger
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                          color: PartyColors.danger
                              .withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '☠️ Jugadores eliminados:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PartyColors.danger,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._deadPlayers.map((p) =>
                            Text(
                              p,
                              style: const TextStyle(
                                fontSize: 16,
                                color: PartyColors.danger,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (!hasGameEnded)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _showDawnLog = false;
                        _showVoteScreen = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          PartyColors.primary,
                      foregroundColor:
                          PartyColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  20)),
                    ),
                    child: const Text(
                      'DEBATIR Y VOTAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              if (hasGameEnded)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _showDawnLog = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          PartyColors.primary,
                      foregroundColor:
                          PartyColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  20)),
                    ),
                    child: const Text(
                      'VER RESULTADO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildVoteScreen() {
    final alive = _alivePlayers;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'VOTACIÓN',
          style: TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      body: AnimatedPartyBackground(child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗳️',
                  style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Debatid y votad',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¿Quién es el lobo? Debated entre todos y votad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: PartyColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ...alive.map((player) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () async {
                          final beforeDead = Set<String>.from(_deadPlayers);
                          setState(() {
                            final log = <_NightLogEntry>[];
                            _killPlayer(player, log);
                            // _killPlayer handles lover chain
                            _checkWinCondition();
                            _showVoteScreen = false;
                            if (_voteResult == null) {
                              _dayCount++;
                            }
                          });
                          // Confirmar muerte revelando el rol; la venganza del
                          // cazador (si aplica) se encadena tras confirmar.
                          _queueDeathReveals(
                              _deadPlayers.difference(beforeDead));
                          _showNextDeathReveal();
                        },
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              PartyColors.text,
                          side: BorderSide(
                              color:
                                  PartyColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      16)),
                        ),
                        child: Text(
                          '🗳️ $player',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _showVoteScreen = false;
                      _dayCount++;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        PartyColors.surface,
                    foregroundColor:
                        PartyColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20),
                      side: BorderSide(
                          color: PartyColors.border),
                    ),
                  ),
                  child: const Text(
                    'NO ELIMINAR A NADIE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildGameOver() {
    final result = _voteResult ?? '¡Fin del juego!';
    final wolvesWin = result.contains('¡Los lobos ganan');
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(wolvesWin ? '🐺' : '🎉',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                result,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PartyColors.text,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PartyColors.surface,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                      color: PartyColors.border),
                ),
                child: Column(
                  children:
                      _shuffledPlayers.map((p) {
                    final role =
                        _assignedRoles[p] ?? 'Aldeano';
                    final roleData = GameData
                        .puebloDuermeRoles[role];
                    final isDead =
                        _deadPlayers.contains(p);
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            roleData?.icon ?? '👤',
                            style: TextStyle(
                              fontSize: 20,
                              decoration: isDead
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                                color: isDead
                                    ? PartyColors
                                        .textMuted
                                    : PartyColors
                                        .text,
                                decoration: isDead
                                    ? TextDecoration
                                        .lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            role,
                            style: TextStyle(
                              fontSize: 13,
                              color: roleData?.color !=
                                      null
                                  ? Color(roleData!
                                      .color)
                                  : PartyColors
                                      .textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_cupidoPaired &&
                  _cupidoLover1 != null &&
                  _cupidoLover2 != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PartyColors.love
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color: PartyColors.love
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '💘 $_cupidoLover1 y $_cupidoLover2 eran los amantes.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PartyColors.love,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async { await _handleGameCompleted(); if (context.mounted) Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        PartyColors.primary,
                    foregroundColor:
                        PartyColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'FINALIZAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}