import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../route_observer.dart';
import '../services/avatar_service.dart';
import '../services/player_storage.dart';
import '../services/sound_service.dart';
import '../widgets/bottom_navigation.dart';
import 'extras_screen.dart';
import 'games_screen.dart';
import 'home_screen.dart';
import 'players_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialPlayers});

  final List<String>? initialPlayers;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with RouteAware, WidgetsBindingObserver {
  int selectedIndex = 0;
  List<String> players = [];
  bool _playersLoaded = false;
  late final PlayerStorage _storage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService.instance.init();
    // Intento inmediato + reintento tras primer frame (para web autoplay)
    SoundService.instance.playMenuLoop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && SoundService.instance.currentTrack != 'menu') {
          SoundService.instance.playMenuLoop();
        }
      });
    });
    _initStorage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La app no debe seguir sonando en segundo plano.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        SoundService.instance.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        SoundService.instance.onAppResumed();
        break;
    }
  }

  @override
  void didPopNext() {
    // Al volver de un juego reanuda la música del menú (si no suena ya).
    // Pequeño delay para dejar que el dispose del juego pare su pista primero
    // y evitar carrera donde stopAmbient del juego mate la del menú.
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (SoundService.instance.currentTrack != 'menu') {
        SoundService.instance.playMenuLoop();
      }
    });
  }

  Future<void> _initStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _storage = PlayerStorage(prefs);
    await _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final loaded = await _storage.loadPlayers();
    if (!mounted) return;
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      players = List<String>.from(widget.initialPlayers!);
    } else if (loaded.isNotEmpty) {
      players = loaded;
    } else {
      players = ['Alex', 'Pablo', 'Laura', 'Mario', 'Sara'];
      await _storage.savePlayers(players);
      if (!mounted) return;
    }
    if (players.isEmpty) players = ['Alex'];
    _playersLoaded = true;
    if (mounted) setState(() {});
    // Fire-and-forget intencionado: crea avatares por defecto en segundo plano.
    unawaited(_ensureAvatars());
  }

  Future<void> _ensureAvatars() async {
    if (players.isEmpty) {
      players = ['Alex'];
      if (mounted) setState(() {});
    }
    for (final p in players) {
      final existing = await AvatarService.instance.getAvatar(p);
      if (existing == null) {
        final def = AvatarService.instance.defaultAvatarFor(p);
        await AvatarService.instance.saveAvatar(p, def);
      }
    }
  }

  Future<void> _savePlayers() async {
    if (!_playersLoaded) return;
    try {
      await _storage.savePlayers(players);
    } catch (_) {}
  }

  void _changeScreen(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _addPlayer(String name) {
    if (players.length >= 10) return;
    setState(() {
      players.add(name);
    });
    _savePlayers();
  }

  void _removePlayer(int index) {
    setState(() {
      players.removeAt(index);
    });
    _savePlayers();
  }

  @override
  Widget build(BuildContext context) {
    if (!_playersLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          RepaintBoundary(
            key: const ValueKey('tab-home'),
            child: HomeScreen(
              onPlayPressed: () => _changeScreen(1),
              onGroupPressed: () => _changeScreen(2),
              onExtrasPressed: () => _changeScreen(3),
              players: players,
            ),
          ),
          RepaintBoundary(
            key: const ValueKey('tab-games'),
            child: GamesScreen(players: players),
          ),
          RepaintBoundary(
            key: const ValueKey('tab-players'),
            child: PlayersScreen(
              players: players,
              onAddPlayer: _addPlayer,
              onRemovePlayer: _removePlayer,
            ),
          ),
          RepaintBoundary(
            key: const ValueKey('tab-extras'),
            child: ExtrasScreen(players: players),
          ),
          RepaintBoundary(
            key: const ValueKey('tab-settings'),
            child: const SettingsScreen(),
          ),
        ],
      ),
      bottomNavigationBar: PartyBottomNavigation(
        selectedIndex: selectedIndex,
        onItemSelected: _changeScreen,
      ),
    );
  }
}
