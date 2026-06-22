import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/shared/ui/round_table_widget.dart';

void main() {
  testWidgets('RoundTableWidget renders with 3 and 4 players', (WidgetTester tester) async {
    // Test 3 players
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoundTableWidget(
            playerNames: ['Alice', 'Bob', 'Charlie'],
            playerIds: ['p1', 'p2', 'p3'],
            activePlayerIndex: 0,
            cardCounts: [3, 3, 3],
            currentTrickPlays: {},
          ),
        ),
      ),
    );

    // Wait for animations to settle
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);

    // Test 4 players
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoundTableWidget(
            playerNames: ['Alice', 'Bob', 'Charlie', 'Diana'],
            playerIds: ['p1', 'p2', 'p3', 'p4'],
            activePlayerIndex: 0,
            cardCounts: [3, 3, 3, 3],
            currentTrickPlays: {},
          ),
        ),
      ),
    );

    // Wait for animations to settle
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Diana'), findsOneWidget);
  });
}
