import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:party/games/adivina_game.dart';
import 'package:party/games/alienigena_game.dart';
import 'package:party/games/bomba_game.dart';
import 'package:party/games/debate_game.dart';
import 'package:party/games/dibuja_y_adivina_game.dart';
import 'package:party/games/es_un_10_game.dart';
import 'package:party/games/espia_game.dart';
import 'package:party/games/impostor_game.dart';
import 'package:party/games/mascara_infiltrada_game.dart';
import 'package:party/games/matar_casar_besar_game.dart';
import 'package:party/games/mimica_game.dart';
import 'package:party/games/pueblo_duerme_game.dart';
import 'package:party/games/quien_es_mas_game.dart';
import 'package:party/games/quien_soy_game.dart';
import 'package:party/games/secretos_game.dart';
import 'package:party/games/tabu_game.dart';
import 'package:party/games/verdad_o_reto_game.dart';
import 'package:party/games/yo_nunca_game.dart';
import 'package:party/models/avatar.dart';
import 'package:party/screens/avatar_editor_screen.dart';
import 'package:party/screens/leaderboard_screen.dart';
import 'package:party/screens/main_shell.dart';
import 'package:party/screens/players_screen.dart';
import 'package:party/screens/settings_screen.dart';
import 'package:party/screens/shop_screen.dart';
import 'package:party/services/avatar_service.dart';
import 'package:party/widgets/avatar_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('settings builds without exceptions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('AJUSTES'), findsOneWidget);
  });

  testWidgets('players builds without exceptions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PlayersScreen(
        players: ['Alex', 'Sara'],
        onAddPlayer: (_) {},
        onRemovePlayer: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('avatar editor builds without exceptions', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: AvatarEditorScreen(playerName: 'Alex')));
    await tester.pumpAndSettle();
    expect(find.text('AVATAR: Alex'), findsOneWidget);
  });

  testWidgets('avatar editor interactions do not throw', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: AvatarEditorScreen(playerName: 'Alex')));
    await tester.pumpAndSettle();
    // Mueve todos los sliders al máximo y al mínimo.
    final sliders = find.byType(Slider);
    expect(sliders, findsWidgets);
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(Slider).at(i), const Offset(200, 0));
      await tester.pump();
      await tester.drag(find.byType(Slider).at(i), const Offset(-400, 0));
      await tester.pump();
    }
    // Pulsa "Centrar" de cada fila.
    final centrarCount = find.text('Centrar').evaluate().length;
    for (var i = 0; i < centrarCount; i++) {
      await tester.tap(find.text('Centrar').first);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

  testWidgets('settings toggles do not throw', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    final switchCount = find.byType(Switch).evaluate().length;
    for (var i = 0; i < switchCount; i++) {
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

  testWidgets('players with saved avatars (json round-trip)', (tester) async {
    // Guarda avatares con foto+escala+offsets y vuelve a leerlos (round-trip).
    final original = AvatarData(
      baseFace: 'custom_01',
      assetPath: 'assets/avatars/custom_01.png',
      hat: '🎩',
      faceScale: 1.2,
      faceOffsetX: 0.1,
      faceOffsetY: -0.1,
      hatScale: 1.4,
    );
    await AvatarService.instance.saveAvatar('Alex', original);
    final reloaded = await AvatarService.instance.getAvatar('Alex');
    expect(reloaded, isNotNull);
    expect(reloaded!.faceScale, 1.2);
    await tester.pumpWidget(MaterialApp(
      home: PlayersScreen(
        players: ['Alex', 'Sara'],
        onAddPlayer: (_) {},
        onRemovePlayer: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('main shell all tabs without exceptions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();
    // Cambia por las 4 pestañas tocando la bottom nav.
    final nav = find.byType(NavigationBar);
    if (nav.evaluate().isNotEmpty) {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byType(NavigationDestination).at(i));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('shop and leaderboard render', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(
      home: LeaderboardScreen(players: ['Alex', 'Sara']),
    ));
    await tester.pumpAndSettle();
  });

  group('games boot without exceptions', () {
    const players = ['Alex', 'Sara', 'Pablo'];
    testWidgets('yo nunca', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: YoNuncaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('mimica', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: MimicaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('dibuja', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: DibujaYadivinaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('debate', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: DebateGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('bomba', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: BombaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('adivina', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdivinaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('tabu', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: TabuGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('quien soy', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: QuienSoyGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('es un 10', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: EsUn10Game(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('alienigena', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AlienigenaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('impostor', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: ImpostorGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('mascara', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: MascaraInfiltradaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('espia', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: EspiaGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('secretos', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SecretosGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('verdad o reto', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: VerdadORetoGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('quien es mas', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: QuienEsMasGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('matar casar besar', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: MatarCasarBesarGame(players: players)));
      await tester.pumpAndSettle();
    });
    testWidgets('pueblo duerme', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: PuebloDuermeGame(players: players)));
      await tester.pumpAndSettle();
    });
  });

  Future<void> crawlPhases(WidgetTester tester) async {
    // Avanza hasta 14 pantallas pulsando el primer botón disponible.
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final buttons = find.byWidgetPredicate(
        (w) => w is ElevatedButton || w is FilledButton || w is TextButton,
      );
      if (buttons.evaluate().isEmpty) break;
      await tester.tap(buttons.first);
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 2));
  }

  group('games crawl phases', () {
    const players = ['Alex', 'Sara', 'Pablo'];
    testWidgets('mimica crawl', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: MimicaGame(players: players)));
      await tester.pumpAndSettle();
      await crawlPhases(tester);
    });
    testWidgets('dibuja crawl', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: DibujaYadivinaGame(players: players)));
      await tester.pumpAndSettle();
      await crawlPhases(tester);
    });
    testWidgets('adivina crawl', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdivinaGame(players: players)));
      await tester.pumpAndSettle();
      await crawlPhases(tester);
    });
    testWidgets('yo nunca crawl', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: YoNuncaGame(players: players)));
      await tester.pumpAndSettle();
      await crawlPhases(tester);
    });
    testWidgets('quien es mas crawl', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: QuienEsMasGame(players: players)));
      await tester.pumpAndSettle();
      await crawlPhases(tester);
    });
  });

  group('dialog flows', () {
    testWidgets('shop buy taps', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
      await tester.pumpAndSettle();
      // Toca el primer botón de comprar.
      final buyButtons =
          find.byWidgetPredicate((w) => w is ElevatedButton || w is FilledButton || w is OutlinedButton);
      if (buyButtons.evaluate().isNotEmpty) {
        await tester.tap(buyButtons.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('leaderboard reset dialog', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LeaderboardScreen(players: const ['Alex', 'Sara']),
      ));
      await tester.pumpAndSettle();
      final resetBtn = find.byIcon(Icons.delete_outline);
      if (resetBtn.evaluate().isNotEmpty) {
        await tester.tap(resetBtn.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('players add and remove dialogs', (tester) async {
      var players = ['Alex'];
      await tester.pumpWidget(MaterialApp(
        home: PlayersScreen(
          players: players,
          onAddPlayer: (n) => players.add(n),
          onRemovePlayer: (i) => players.removeAt(i),
        ),
      ));
      await tester.pumpAndSettle();
      // Abrir diálogo añadir jugador.
      final addBtn = find.text('AÑADIR JUGADOR');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Sara');
        await tester.pump();
        final okBtn = find.text('AÑADIR');
        if (okBtn.evaluate().isNotEmpty) {
          await tester.tap(okBtn);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('settings about and reset dialogs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();
      // About.
      final about = find.text('Sobre PARTY');
      if (about.evaluate().isNotEmpty) {
        await tester.tap(about);
        await tester.pumpAndSettle();
        final close = find.text('Cerrar');
        if (close.evaluate().isNotEmpty) {
          await tester.tap(close);
          await tester.pumpAndSettle();
        }
      }
      // Factory reset: abre y cancela los dos diálogos.
      final reset = find.textContaining('REINICIAR APP');
      if (reset.evaluate().isNotEmpty) {
        await tester.tap(reset);
        await tester.pumpAndSettle();
        final cancel = find.text('Cancelar');
        if (cancel.evaluate().isNotEmpty) {
          await tester.tap(cancel.first);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  testWidgets('editor photo drag and face slider', (tester) async {
    await AvatarService.instance.saveAvatar(
      'Alex',
      AvatarData(
        baseFace: 'custom_01',
        assetPath: 'assets/avatars/custom_01.png',
        hat: '🎩',
      ),
    );
    await tester.pumpWidget(
        const MaterialApp(home: AvatarEditorScreen(playerName: 'Alex')));
    await tester.pumpAndSettle();
    // Arrastra sobre el preview (mueve la cara).
    await tester.drag(find.byType(DraggableAvatarPreview), const Offset(30, -20));
    await tester.pump();
    // Mueve el slider de Cara al máximo y al mínimo.
    await tester.drag(find.byType(Slider).first, const Offset(200, 0));
    await tester.pump();
    await tester.drag(find.byType(Slider).first, const Offset(-400, 0));
    await tester.pumpAndSettle();
  });

  testWidgets('editor golden locked photo', (tester) async {
    await AvatarService.instance.saveAvatar(
      'Alex',
      AvatarData(baseFace: 'custom_13', assetPath: 'assets/avatars/custom_13.png'),
    );
    await tester.pumpWidget(
        const MaterialApp(home: AvatarEditorScreen(playerName: 'Alex')));
    await tester.pumpAndSettle();
  });

  Future<void> tapAllButtons(WidgetTester tester, {int rounds = 8}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.pump(const Duration(seconds: 4));
      final buttons = find.byWidgetPredicate(
        (w) => w is ElevatedButton || w is FilledButton || w is TextButton || w is OutlinedButton,
      );
      if (buttons.evaluate().isEmpty) break;
      await tester.tap(buttons.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('games deep flows with timeouts', () {
    const players = ['Alex', 'Sara'];
    testWidgets('dibuja full turn with timeout', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: DibujaYadivinaGame(players: players)));
      await tester.pumpAndSettle();
      await tapAllButtons(tester, rounds: 6);
      // Deja correr el timer de dibujo hasta el timeout.
      await tester.pump(const Duration(seconds: 65));
      await tester.pumpAndSettle();
      await tapAllButtons(tester, rounds: 8);
    });
    testWidgets('adivina playing and timeout', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdivinaGame(players: players)));
      await tester.pumpAndSettle();
      await tapAllButtons(tester, rounds: 6);
      await tester.pump(const Duration(seconds: 65));
      await tester.pumpAndSettle();
      await tapAllButtons(tester, rounds: 8);
    });
    testWidgets('mimica deep flow', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: MimicaGame(players: players)));
      await tester.pumpAndSettle();
      await tapAllButtons(tester, rounds: 10);
      await tester.pump(const Duration(seconds: 65));
      await tester.pumpAndSettle();
      await tapAllButtons(tester, rounds: 10);
    });
  });

  testWidgets('leaderboard with scores renders podium', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'player_scores', '{"Alex": 12, "Sara": 8, "Pablo": 5}');
    await tester.pumpWidget(MaterialApp(
      home: LeaderboardScreen(players: const ['Alex', 'Sara', 'Pablo']),
    ));
    await tester.pumpAndSettle();
    expect(find.text('CLASIFICACIÓN'), findsOneWidget);
  });

  testWidgets('avatar display with photo scale renders', (tester) async {
    final avatar = AvatarData(
      baseFace: 'custom_01',
      assetPath: 'assets/avatars/custom_01.png',
      hat: '🎩',
      faceScale: 1.2,
      faceOffsetX: 0.1,
      faceOffsetY: -0.1,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AvatarDisplay(avatar: avatar, size: 120)),
    ));
    await tester.pumpAndSettle();
  });
}
