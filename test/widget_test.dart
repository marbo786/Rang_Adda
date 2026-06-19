
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/main.dart';
import 'package:rang_adda/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthService implements AuthService {
  @override
  Future<User?> signInAnonymously(String displayName) async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('App loads and shows Lobby', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWithValue(MockAuthService())],
        child: const MyApp(),
      ),
    );

    // Wait for the GoRouter to settle on the initial route
    await tester.pumpAndSettle();

    // Verify that our lobby screen is displayed
    expect(find.text('RANG ADDA'), findsOneWidget);
    expect(find.text('Choose your game'), findsOneWidget);
  });
}
