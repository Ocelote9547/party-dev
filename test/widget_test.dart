import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:party/main.dart';
import 'package:party/widgets/bottom_navigation.dart';

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const PartyApp());
  // Splash: timer de 2s + transición de 600ms (pumps explícitos porque
  // hay animaciones en loop y pumpAndSettle no terminaría nunca).
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
  });

  testWidgets('App renders and shows bottom navigation', (WidgetTester tester) async {
    await _pumpPastSplash(tester);

    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('JUEGOS'), findsOneWidget);
    expect(find.text('GRUPO'), findsOneWidget);
    expect(find.text('EXTRAS'), findsOneWidget);
    expect(find.text('AJUSTES'), findsOneWidget);
  });

  Finder navItem(String label) => find.descendant(
        of: find.byType(PartyBottomNavigation),
        matching: find.text(label),
      );

  testWidgets('Can navigate between screens', (WidgetTester tester) async {
    await _pumpPastSplash(tester);

    await tester.tap(navItem('JUEGOS'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('JUEGOS'), findsWidgets);

    await tester.tap(navItem('GRUPO'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('JUGADORES'), findsOneWidget);

    await tester.tap(navItem('AJUSTES'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('AJUSTES'), findsWidgets);

    await tester.tap(navItem('EXTRAS'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('EXTRAS'), findsWidgets);
    expect(find.text('PLANES'), findsOneWidget);
  });
}
