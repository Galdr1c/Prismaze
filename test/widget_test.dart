// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/main.dart';
import 'package:prismaze/game/settings_manager.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final settingsManager = SettingsManager();
    // No need to init in smoke test for now if it requires SharedPreferences mock
    // Just verify the app builds and shows Splash
    await tester.pumpWidget(PrismazeApp(settingsManager: settingsManager));

    expect(find.byType(PrismazeApp), findsOneWidget);
  });
}
