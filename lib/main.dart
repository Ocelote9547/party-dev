import 'package:flutter/material.dart';

import 'route_observer.dart';
import 'services/sound_service.dart';
import 'services/tilt_service.dart';
import 'theme/party_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  await SoundService.instance.init();
  await TiltService.instance.init();
  runApp(const PartyApp());
}

class PartyApp extends StatelessWidget {
  const PartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PARTY',
          theme: PartyTheme.light,
          darkTheme: PartyTheme.dark,
          themeMode: mode,
          navigatorObservers: [routeObserver],
          home: const SplashScreen(),
        );
      },
    );
  }
}
