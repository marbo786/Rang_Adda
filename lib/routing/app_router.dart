import 'package:go_router/go_router.dart';
import '../ui/screens/lobby_screen.dart';
import '../ui/screens/table_screen.dart';
import '../ui/screens/thulla_table_screen.dart';
import '../ui/screens/waiting_room_screen.dart';
import '../ui/screens/bluff_table_screen.dart';
import '../ui/screens/add_players_screen.dart';
import '../ui/screens/rang_table_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LobbyScreen()),
    GoRoute(
      path: '/thulla',
      builder: (context, state) {
        final extra = state.extra;
        final names = extra is List ? List<String>.from(extra) : null;
        return ThullaTableScreen(playerNames: names);
      },
    ),
    GoRoute(
      path: '/online_thulla',
      builder: (context, state) => const ThullaTableScreen(isOnline: true),
    ),
    GoRoute(
      path: '/online_bluff',
      builder: (context, state) => const BluffTableScreen(isOnline: true),
    ),
    GoRoute(
      path: '/waiting_room/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        return WaitingRoomScreen(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/table/bluff',
      builder: (context, state) {
        final extra = state.extra;
        final names = extra is List ? List<String>.from(extra) : null;
        return BluffTableScreen(playerNames: names);
      },
    ),
    GoRoute(
      path: '/table/:gameType',
      redirect: (context, state) {
        final gameType = state.pathParameters['gameType'];
        if (gameType == 'rang') {
          return '/rang_table';
        }
        return null;
      },
      builder: (context, state) {
        final gameType = state.pathParameters['gameType'] ?? 'unknown';
        return TableScreen(gameType: gameType);
      },
    ),
    // ── Pre-game player-name entry ─────────────────────────────────────────
    // /setup/:gameType is the canonical route used by the lobby.
    // /add_players/:gameType is kept for backwards compatibility.
    GoRoute(
      path: '/setup/:gameType',
      builder: (context, state) {
        final gameType = state.pathParameters['gameType']!;
        return AddPlayersScreen(gameType: gameType);
      },
    ),
    GoRoute(
      path: '/add_players/:gameType',
      builder: (context, state) {
        final gameType = state.pathParameters['gameType']!;
        return AddPlayersScreen(gameType: gameType);
      },
    ),
    GoRoute(
      path: '/rang_table',
      builder: (context, state) {
        final extra = state.extra;
        final names = extra is List ? List<String>.from(extra) : null;
        return RangTableScreen(playerNames: names);
      },
    ),
  ],
);
