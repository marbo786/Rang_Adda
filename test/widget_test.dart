
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/main.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/features/rang/ui/rang_table_screen.dart';
import 'package:rang_adda/features/rang/state/rang_provider.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';

class MockAuthService implements AuthService {
  @override
  Future<User?> signInAnonymously(String displayName) async => null;

  @override
  Future<void> signOut() async {}
}

class MockRangNotifier extends RangNotifier {
  final RangGameState? _mockState;
  MockRangNotifier(this._mockState);

  @override
  RangGameState? build() => _mockState;

  @override
  void startGame(List<String> playerNames) {}
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

  testWidgets('RangTableScreen renders suit picker in trumpSelection phase',
      (WidgetTester tester) async {
    final mockState = RangGameState(
      gameId: 'test_game',
      players: [
        Player(id: 'Alice', name: 'Alice', hand: const []),
        Player(id: 'Bob', name: 'Bob', hand: const []),
        Player(id: 'Charlie', name: 'Charlie', hand: const []),
        Player(id: 'Diana', name: 'Diana', hand: const []),
      ],
      status: GameStatus.playing,
      currentPlayerId: 'Bob',
      dealerId: 'Alice',
      trumpCallerId: 'Bob',
      phase: RangPhase.trumpSelection,
      passToPlayerId: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rangProvider.overrideWith(() => MockRangNotifier(mockState)),
        ],
        child: const MaterialApp(
          home: RangTableScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify key UI elements render
    expect(find.text('RANG'), findsOneWidget);
    expect(find.text('CHOOSE TRUMP SUIT'), findsOneWidget);
    expect(find.text('♥'), findsOneWidget);
    expect(find.text('♦'), findsOneWidget);
    expect(find.text('♣'), findsOneWidget);
    expect(find.text('♠'), findsOneWidget);
  });
}
