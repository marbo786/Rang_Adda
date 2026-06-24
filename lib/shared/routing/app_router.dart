import 'package:go_router/go_router.dart';
import 'package:rang_adda/features/lobby/ui/lobby_screen.dart';
import 'package:rang_adda/shared/ui/table_screen.dart';
import 'package:rang_adda/features/thulla/ui/thulla_table_screen.dart';
import 'package:rang_adda/features/lobby/ui/waiting_room_screen.dart';
import 'package:rang_adda/features/bluff/ui/bluff_table_screen.dart';
import 'package:rang_adda/features/lobby/ui/add_players_screen.dart';
import 'package:rang_adda/features/rang/ui/rang_table_screen.dart';
import 'package:rang_adda/features/profile/ui/profile_screen.dart';
import 'package:rang_adda/features/profile/ui/leaderboard_screen.dart';
import 'package:rang_adda/shared/models/player.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LobbyScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/thulla',
      builder: (context, state) {
        final extra = state.extra;
        final players = extra is List ? List<Player>.from(extra) : null;
        return ThullaTableScreen(players: players);
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
        final players = extra is List ? List<Player>.from(extra) : null;
        return BluffTableScreen(players: players);
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
        final players = extra is List ? List<Player>.from(extra) : null;
        return RangTableScreen(players: players);
      },
    ),
  ],
);
