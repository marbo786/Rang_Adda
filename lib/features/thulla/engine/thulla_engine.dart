import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/deck.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';

class ThullaEngine {
  static ThullaGameState initializeGame(List<String> playerNames) {
    final deck = Deck.standard().cards..shuffle(Random());

    List<Player> players = playerNames
        .map((name) => Player(id: name, name: name, hand: const []))
        .toList();

    // Deal all cards
    int pIndex = 0;
    for (var card in deck) {
      players[pIndex] = players[pIndex].copyWith(
        hand: [...players[pIndex].hand, card],
      );
      pIndex = (pIndex + 1) % players.length;
    }

    // Sort hands (group by suit, then rank)
    players = players.map((p) {
      final sortedHand = List<PlayingCard>.from(p.hand)
        ..sort((a, b) {
          int suitCompare = a.suit.index.compareTo(b.suit.index);
          if (suitCompare != 0) return suitCompare;
          return _rankValue(
            b.rank,
          ).compareTo(_rankValue(a.rank)); // Highest first
        });
      return p.copyWith(hand: sortedHand, cardCount: sortedHand.length);
    }).toList();

    // Find Ace of Spades
    String startPlayerId = players.first.id;
    for (var p in players) {
      if (p.hand.contains(
        const PlayingCard(suit: Suit.spades, rank: Rank.ace),
      )) {
        startPlayerId = p.id;
        break;
      }
    }

    return ThullaGameState(
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
      players: players,
      status: GameStatus.playing,
      currentPlayerId: startPlayerId,
      passToPlayerId: null,
      powerPlayerId: startPlayerId,
    );
  }

  static ThullaGameState startGameFromWaitingRoom(ThullaGameState state) {
    final deck = Deck.standard().cards..shuffle(Random());
    var players = List<Player>.from(state.players);

    int pIndex = 0;
    for (var card in deck) {
      players[pIndex] = players[pIndex].copyWith(
        hand: [...players[pIndex].hand, card],
      );
      pIndex = (pIndex + 1) % players.length;
    }

    players = players.map((p) {
      final sortedHand = List<PlayingCard>.from(p.hand)
        ..sort((a, b) {
          int suitCompare = a.suit.index.compareTo(b.suit.index);
          if (suitCompare != 0) return suitCompare;
          return _rankValue(b.rank).compareTo(_rankValue(a.rank));
        });
      return p.copyWith(hand: sortedHand, cardCount: sortedHand.length);
    }).toList();

    String startPlayerId = players.first.id;
    for (var p in players) {
      if (p.hand.contains(
        const PlayingCard(suit: Suit.spades, rank: Rank.ace),
      )) {
        startPlayerId = p.id;
        break;
      }
    }

    return state.copyWith(
      players: players,
      status: GameStatus.playing,
      currentPlayerId: startPlayerId,
      passToPlayerId: null, // Online games do not need pass device screens!
      powerPlayerId: startPlayerId,
      trickResolving: false,
      isOnline: true,
    );
  }

  static String? getMoveError(
    ThullaGameState state,
    String playerId,
    PlayingCard card,
  ) {
    if (state.status != GameStatus.playing) return "Game is over.";
    if (state.currentPlayerId != playerId) return "Not your turn.";
    if (state.passToPlayerId != null) return "Waiting for next player.";

    final player = state.players.firstWhere((p) => p.id == playerId);
    if (!player.hand.contains(card)) return "You do not have this card.";

    if (state.isFirstTrick && state.currentTrick.isEmpty) {
      if (card != const PlayingCard(suit: Suit.spades, rank: Rank.ace)) {
        return "First trick MUST start with the Ace of Spades!";
      }
    }

    if (state.leadSuit != null && card.suit != state.leadSuit) {
      bool hasSuit = player.hand.any((c) => c.suit == state.leadSuit);
      if (hasSuit) {
        return "You must follow suit! Play a ${state.leadSuit!.name}.";
      }
    }

    return null; // Valid
  }

  static ThullaGameState playCard(
    ThullaGameState state,
    String playerId,
    PlayingCard card,
  ) {
    if (getMoveError(state, playerId, card) != null) return state;

    final players = state.players.map((p) {
      if (p.id == playerId) {
        final newHand = p.hand.where((c) => c != card).toList();
        return p.copyWith(hand: newHand, cardCount: newHand.length);
      }
      return p;
    }).toList();

    final currentTrick = [
      ...state.currentTrick,
      TrickPlay(playerId: playerId, card: card),
    ];

    // In the first trick, playing a different suit is NOT a Tochoo that ends the trick early.
    bool isTochoo =
        !state.isFirstTrick &&
        currentTrick.isNotEmpty &&
        card.suit != currentTrick.first.card.suit;

    bool trickEnded = false;
    int activePlayersCount = players
        .where(
          (p) =>
              p.cardCount > 0 || currentTrick.any((t) => t.playerId == p.id),
        )
        .length;
    bool roundCompletedNormal = currentTrick.length == activePlayersCount;

    if (isTochoo || roundCompletedNormal) trickEnded = true;

    if (!trickEnded) {
      String nextPlayerId = _getNextPlayerId(players, playerId);
      return state.copyWith(
        players: players,
        currentTrick: currentTrick,
        currentPlayerId: nextPlayerId,
        passToPlayerId: state.isOnline ? null : nextPlayerId,
      );
    }

    return state.copyWith(
      players: players,
      currentTrick: currentTrick,
      trickResolving: true,
      currentPlayerId: null,
    );
  }

  static ThullaGameState resolveTrick(ThullaGameState state) {
    if (!state.trickResolving || state.currentTrick.isEmpty) return state;

    final players = List<Player>.from(state.players);
    final currentTrick = state.currentTrick;
    Suit leadSuit = currentTrick.first.card.suit;

    bool isTochoo =
        !state.isFirstTrick && currentTrick.last.card.suit != leadSuit;

    if (isTochoo) {
      String highestPlayerId = _getHighestLeadSuitPlayer(
        currentTrick,
        leadSuit,
      );
      List<PlayingCard> trickCards = currentTrick.map((t) => t.card).toList();

      final updatedPlayers = players.map((p) {
        if (p.id == highestPlayerId) {
          final newHand = [...p.hand, ...trickCards];
          return p.copyWith(hand: newHand, cardCount: p.cardCount + trickCards.length);
        }
        return p;
      }).toList();

      return _checkWinCondition(
        state.copyWith(
          players: updatedPlayers,
          currentTrick: const [],
          powerPlayerId: highestPlayerId,
          currentPlayerId: highestPlayerId,
          passToPlayerId: state.isOnline ? null : highestPlayerId,
          trickResolving: false,
        ),
      );
    } else {
      String highestPlayerId = _getHighestLeadSuitPlayer(
        currentTrick,
        leadSuit,
      );
      List<PlayingCard> newWastePile = [
        ...state.wastePile,
        ...currentTrick.map((t) => t.card),
      ];

      var updatedPlayers = List<Player>.from(players);
      final highestPlayer = updatedPlayers.firstWhere(
        (p) => p.id == highestPlayerId,
      );

      if (highestPlayer.cardCount == 0) {
        final random = Random();
        if (newWastePile.isNotEmpty) {
          int drawIndex = random.nextInt(newWastePile.length);
          PlayingCard drawnCard = newWastePile.removeAt(drawIndex);
          updatedPlayers = updatedPlayers.map((p) {
            if (p.id == highestPlayerId) return p.copyWith(hand: [drawnCard], cardCount: 1);
            return p;
          }).toList();
        }
      }

      return _checkWinCondition(
        state.copyWith(
          players: updatedPlayers,
          currentTrick: const [],
          wastePile: newWastePile,
          powerPlayerId: highestPlayerId,
          currentPlayerId: highestPlayerId,
          passToPlayerId: state.isOnline ? null : highestPlayerId,
          trickResolving: false,
        ),
      );
    }
  }

  static ThullaGameState _checkWinCondition(ThullaGameState state) {
    var activePlayers = state.players.where((p) => p.cardCount > 0).toList();
    if (activePlayers.length <= 1) {
      return state.copyWith(
        status: GameStatus.finished,
        passToPlayerId: null,
        clearPassToPlayerId: true,
        currentPlayerId: null,
        clearCurrentPlayerId: true,
      );
    }
    return state;
  }

  static String _getNextPlayerId(List<Player> players, String currentPlayerId) {
    int idx = players.indexWhere((p) => p.id == currentPlayerId);
    for (int i = 1; i < players.length; i++) {
      int nextIdx = (idx + i) % players.length;
      if (players[nextIdx].cardCount > 0) return players[nextIdx].id;
    }
    return currentPlayerId;
  }

  static String _getHighestLeadSuitPlayer(
    List<TrickPlay> trick,
    Suit leadSuit,
  ) {
    TrickPlay highest = trick.firstWhere((t) => t.card.suit == leadSuit);
    for (var play in trick) {
      if (play.card.suit == leadSuit &&
          _rankValue(play.card.rank) > _rankValue(highest.card.rank)) {
        highest = play;
      }
    }
    return highest.playerId;
  }

  static int _rankValue(Rank rank) {
    if (rank == Rank.ace) return 14;
    return rank.index + 1;
  }
}
