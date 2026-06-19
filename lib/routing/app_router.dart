import 'package:go_router/go_router.dart';
import '../ui/screens/lobby_screen.dart';
import '../ui/screens/table_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/table/:gameType',
      builder: (context, state) {
        final gameType = state.pathParameters['gameType'] ?? 'unknown';
        return TableScreen(gameType: gameType);
      },
    ),
  ],
);
