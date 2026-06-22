import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/features/rang/ui/rang_table_screen.dart';
import 'package:rang_adda/shared/ui/deal_animation_overlay.dart';
import 'package:rang_adda/shared/ui/pass_device_overlay.dart';

void main() {
  testWidgets('RangTableScreen flow test (deal -> pass -> trump declaration -> trick play)',
      (WidgetTester tester) async {
    // 1. Mount RangTableScreen with specific player names
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RangTableScreen(
            playerNames: ['Alice', 'Bob', 'Charlie', 'Diana'],
          ),
        ),
      ),
    );

    // Initial state: starts loading, starts deal animation
    await tester.pump();

    // Verify RangTableScreen is rendered
    expect(find.text('RANG'), findsWidgets);

    // DealAnimationOverlay should be on screen blocking interaction
    expect(find.byType(DealAnimationOverlay), findsOneWidget);

    // Wait for the deal animation duration to finish (800ms + delays, let's pump 3 seconds)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    // After deal animation finishes, the DealAnimationOverlay is removed,
    // and the first PassDeviceOverlay appears (for Bob, since Bob is the dealer's partner / trump caller)
    expect(find.byType(DealAnimationOverlay), findsNothing);
    expect(find.byType(PassDeviceOverlay), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget); // Bob is players[1], dealer is players[0] (Alice)

    // Tap READY on PassDeviceOverlay to acknowledge
    await tester.tap(find.text('READY'));
    await tester.pump(const Duration(seconds: 1));

    // PassDeviceOverlay is gone, and Bob is active and sees the trump suit picker
    expect(find.byType(PassDeviceOverlay), findsNothing);
    expect(find.text('CHOOSE TRUMP SUIT'), findsOneWidget);

    // 4 suit buttons: Hearts, Diamonds, Clubs, Spades
    expect(find.text('♥'), findsOneWidget);
    expect(find.text('♦'), findsOneWidget);
    expect(find.text('♣'), findsOneWidget);
    expect(find.text('♠'), findsOneWidget);

    // Tap '♥' (Hearts) to declare trump
    await tester.tap(find.text('♥'));
    await tester.pump(const Duration(seconds: 1));

    // Trump selection phase is complete. Now the game is in trickPlay phase.
    // Bob is still active to lead the first trick.
    expect(find.text('CHOOSE TRUMP SUIT'), findsNothing);
    expect(find.text('TRUMP: '), findsOneWidget);
    expect(find.text('YOUR TURN! LEAD THE TRICK.'), findsOneWidget);
  });
}
