import 'dart:convert';

import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/utils/web_storage.dart';

const _keyGameType = 'last_game_type';
const _keyPlayerNames = 'last_player_names';
const _keyPlayersJson = 'last_players_json';

/// Persists lobby player configuration before navigating to a table screen.
void saveGameSession(String gameType, List<Player> players) {
  saveToStorage(_keyGameType, gameType);
  saveToStorage(_keyPlayerNames, players.map((p) => p.name).join(','));
  saveToStorage(
    _keyPlayersJson,
    jsonEncode(
      players
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'isBot': p.isBot,
              if (p.botDifficulty != null)
                'botDifficulty': p.botDifficulty!.name,
            },
          )
          .toList(),
    ),
  );
}

/// Resolves lobby players from navigation extras or web localStorage.
List<Player> resolvePlayers(List<Player>? passedPlayers, String gameType) {
  if (passedPlayers != null && passedPlayers.isNotEmpty) {
    return passedPlayers;
  }

  final storedType = readFromStorage(_keyGameType);
  if (storedType == gameType) {
    final storedJson = readFromStorage(_keyPlayersJson);
    if (storedJson != null && storedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedJson) as List<dynamic>;
        final players = decoded
            .map((entry) => Player.fromJson(entry as Map<String, dynamic>))
            .toList();
        if (players.isNotEmpty) return players;
      } catch (_) {
        // Fall through to name-only recovery.
      }
    }

    final storedNames = readFromStorage(_keyPlayerNames);
    if (storedNames != null && storedNames.isNotEmpty) {
      final names = storedNames
          .split(',')
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        return List.generate(
          names.length,
          (i) => Player(id: 'p${i + 1}', name: names[i]),
        );
      }
    }
  }

  return _defaultPlayers(gameType);
}

List<Player> _defaultPlayers(String gameType) {
  if (gameType == 'thulla') {
    return const [
      Player(id: 'p1', name: 'Alice'),
      Player(id: 'p2', name: 'Bob'),
      Player(id: 'p3', name: 'Charlie'),
    ];
  }
  return const [
    Player(id: 'p1', name: 'Alice'),
    Player(id: 'p2', name: 'Bob'),
    Player(id: 'p3', name: 'Charlie'),
    Player(id: 'p4', name: 'Diana'),
  ];
}
