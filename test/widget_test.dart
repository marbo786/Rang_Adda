import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/main.dart';

void main() {
  testWidgets('App loads and shows Lobby', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Wait for the GoRouter to settle on the initial route
    await tester.pumpAndSettle();

    // Verify that our lobby screen is displayed
    expect(find.text('Rang Adda Lobby'), findsOneWidget);
    expect(find.text('Select a Game'), findsOneWidget);
  });
}
