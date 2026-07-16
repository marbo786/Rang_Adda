import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';

class BluffEngine {
  static BluffGameState initializeGame(List<Player> playersInput) {
    final deck = _createDeck();
    deck.shuffle();

    List<Player> players = playersInput
        .map((p) => p.copyWith(hand: []))
        .toList();

    // Deal cards
    int pIdx = 0;
    while (deck.isNotEmpty) {
      players[pIdx].hand.add(deck.removeLast());
      pIdx = (pIdx + 1) % players.length;
    }

    for (var i = 0; i < players.length; i++) {
      players[i].hand.sort((a, b) => a.rank.index.compareTo(b.rank.index));
      players[i] = players[i].copyWith(cardCount: players[i].hand.length);
    }

    return BluffGameState(
      gameId: 'local_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      status: GameStatus.playing,
      currentPlayerId: players[0].id,
    );
  }

  static List<PlayingCard> _createDeck() {
    List<PlayingCard> deck = [];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        deck.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }

  static String? getMoveError(
    BluffGameState state,
    String playerId,
    List<PlayingCard> cards, [
    Rank? claimedRank,
  ]) {
    if (state.status == GameStatus.finished) {
      return "Game is already finished.";
    }
    if (state.currentPlayerId != playerId) return "It's not your turn.";
    if (cards.isEmpty || cards.length > 4) {
      return "You must select between 1 and 4 cards.";
    }
    if (state.centerPile.isEmpty &&
        cards.length < 2 &&
        state.currentRoundRank == null) {
      return "You must play at least 2 cards to start a new pile.";
    }
    if (state.currentRoundRank != null &&
        claimedRank != null &&
        claimedRank != state.currentRoundRank) {
      return 'This round is locked to ${state.currentRoundRank!.name}s. '
          'You must play ${state.currentRoundRank!.name}s or call bluff.';
    }

    final player = state.players.firstWhere((p) => p.id == playerId);
    for (var card in cards) {
      if (!player.hand.contains(card)) {
        return "You don't have those cards.";
      }
    }
    return null;
  }

  static BluffGameState playCards(
    BluffGameState state,
    String playerId,
    List<PlayingCard> cards,
    Rank claimedRank,
  ) {
    final error = getMoveError(state, playerId, cards, claimedRank);
    if (error != null) throw Exception(error);

    // If this is the first play of a new round, lock in the rank
    final roundRank = state.currentRoundRank ?? claimedRank;

    List<Player> updatedPlayers = List.from(state.players);
    int pIdx = updatedPlayers.indexWhere((p) => p.id == playerId);
    Player player = updatedPlayers[pIdx];

    List<PlayingCard> newHand = List.from(player.hand);
    for (var card in cards) {
      newHand.remove(card);
    }
    updatedPlayers[pIdx] = player.copyWith(
      hand: newHand,
      cardCount: newHand.length,
    );

    List<PlayingCard> newCenterPile = List.from(state.centerPile)
      ..addAll(cards);

    // Check win condition
    GameStatus newStatus = state.status;
    if (newHand.isEmpty) {
      // In Bluff, you only win if no one calls your bluff on the final play.
      // So the game isn't finished YET. We just wait for a challenge.
    }

    int nextPIdx = pIdx;
    for (int i = 1; i <= updatedPlayers.length; i++) {
      nextPIdx = (pIdx + i) % updatedPlayers.length;
      if (updatedPlayers[nextPIdx].cardCount > 0 ||
          updatedPlayers[nextPIdx].id == state.lastPlayerId) {
        break;
      }
    }
    String nextPlayerId = updatedPlayers[nextPIdx].id;

    final newPlayersActed = Set<String>.from(state.playersActedThisRound)
      ..add(playerId);

    int activePlayerCount = updatedPlayers.where((p) => p.cardCount > 0).length;

    // A round ends when all players have either played or passed
    bool roundEnded = newPlayersActed.length >= activePlayerCount;

    return state.copyWith(
      players: updatedPlayers,
      currentPlayerId: roundEnded ? playerId : nextPlayerId,
      lastPlayerId: playerId,
      centerPile: roundEnded ? [] : newCenterPile,
      lastPlayedCards: roundEnded ? [] : cards,
      lastClaimedRank: roundEnded ? null : claimedRank,
      consecutivePasses: 0,
      passToPlayerId: roundEnded ? null : nextPlayerId,
      resolvingBluffMessage: null,
      status: newStatus,
      currentRoundRank: roundEnded ? null : roundRank,
      clearCurrentRoundRank: roundEnded,
      playersActedThisRound: roundEnded ? {} : newPlayersActed,
      lastCardPlayerId: playerId,
      clearLastCardPlayerId: roundEnded,
    );
  }

  static BluffGameState passTurn(BluffGameState state, String playerId) {
    if (state.status == GameStatus.finished) {
      throw Exception("Game is already finished.");
    }
    if (state.currentPlayerId != playerId) {
      throw Exception("It's not your turn.");
    }

    List<Player> updatedPlayers = List.from(state.players);
    int pIdx = updatedPlayers.indexWhere((p) => p.id == playerId);

    int nextPIdx = pIdx;
    for (int i = 1; i <= updatedPlayers.length; i++) {
      nextPIdx = (pIdx + i) % updatedPlayers.length;
      if (updatedPlayers[nextPIdx].cardCount > 0 ||
          updatedPlayers[nextPIdx].id == state.lastPlayerId) {
        break;
      }
    }
    String nextPlayerId = updatedPlayers[nextPIdx].id;

    int newConsecutivePasses = state.consecutivePasses + 1;
    List<PlayingCard> newCenterPile = List.from(state.centerPile);
    List<PlayingCard> newLastPlayed = List.from(state.lastPlayedCards);
    Rank? newLastClaimed = state.lastClaimedRank;
    String? newLastPlayerId = state.lastPlayerId;

    final newPlayersActed = Set<String>.from(state.playersActedThisRound)
      ..add(playerId);
    int activePlayerCount = updatedPlayers.where((p) => p.cardCount > 0).length;

    bool roundEnded =
        newPlayersActed.length >= activePlayerCount ||
        newConsecutivePasses >= activePlayerCount;

    if (roundEnded) {
      // Everyone passed or acted. Center pile is discarded.
      newCenterPile = [];
      newLastPlayed = [];
      newLastClaimed = null;
      newLastPlayerId = null;
      newConsecutivePasses = 0;

      // If the player who made the last play has 0 cards, they win the game!
      if (state.lastPlayerId != null) {
        int prevIdx = updatedPlayers.indexWhere(
          (p) => p.id == state.lastPlayerId!,
        );
        if (prevIdx != -1 && updatedPlayers[prevIdx].cardCount == 0) {
          return state.copyWith(
            status: GameStatus.finished,
            resolvingBluffMessage: "${updatedPlayers[prevIdx].name} WINS!",
          );
        }
      }
    }

    return state.copyWith(
      currentPlayerId: roundEnded
          ? (state.lastCardPlayerId ?? nextPlayerId)
          : nextPlayerId,
      consecutivePasses: newConsecutivePasses,
      centerPile: newCenterPile,
      lastPlayedCards: newLastPlayed,
      lastClaimedRank: newLastClaimed,
      lastPlayerId: newLastPlayerId,
      passToPlayerId: roundEnded ? null : nextPlayerId,
      resolvingBluffMessage: null,
      currentRoundRank: roundEnded ? null : state.currentRoundRank,
      clearCurrentRoundRank: roundEnded,
      playersActedThisRound: roundEnded ? {} : newPlayersActed,
      lastCardPlayerId: roundEnded ? null : state.lastCardPlayerId,
      clearLastCardPlayerId: roundEnded,
    );
  }

  static BluffGameState callBluff(BluffGameState state, String callerId) {
    if (state.status == GameStatus.finished) {
      throw Exception("Game is finished.");
    }
    if (state.lastPlayerId == null ||
        state.lastPlayedCards.isEmpty ||
        state.lastClaimedRank == null) {
      throw Exception("No cards to call bluff on.");
    }
    if (callerId == state.lastPlayerId) {
      throw Exception("You can't call bluff on yourself.");
    }

    return state.copyWith(pendingBluffCallerId: callerId);
  }

  static BluffGameState resolveBluffCall(BluffGameState state) {
    if (state.status == GameStatus.finished) return state;
    if (state.pendingBluffCallerId == null) return state;

    String callerId = state.pendingBluffCallerId!;
    bool isBluff = false;
    for (var card in state.lastPlayedCards) {
      if (card.rank != state.lastClaimedRank) {
        isBluff = true;
        break;
      }
    }

    String loserId = isBluff ? state.lastPlayerId! : callerId;

    List<Player> updatedPlayers = List.from(state.players);
    int loserIdx = updatedPlayers.indexWhere((p) => p.id == loserId);
    Player loser = updatedPlayers[loserIdx];

    // centerPile already contains lastPlayedCards (added in playCards()),
    // so only add centerPile to avoid duplicating cards.
    List<PlayingCard> newHand = List.from(loser.hand)..addAll(state.centerPile);
    newHand.sort((a, b) => a.rank.index.compareTo(b.rank.index));
    updatedPlayers[loserIdx] = loser.copyWith(
      hand: newHand,
      cardCount: loser.cardCount + state.centerPile.length,
    );

    final blufferName = updatedPlayers
        .firstWhere((p) => p.id == state.lastPlayerId!)
        .name;
    final callerName = updatedPlayers.firstWhere((p) => p.id == callerId).name;
    String message = isBluff
        ? "$blufferName WAS BLUFFING! They pick up the pile."
        : "$blufferName told the TRUTH! $callerName picks up the pile.";

    GameStatus newStatus = state.status;
    if (!isBluff) {
      int prevIdx = updatedPlayers.indexWhere(
        (p) => p.id == state.lastPlayerId!,
      );
      if (updatedPlayers[prevIdx].cardCount == 0) {
        newStatus = GameStatus.finished;
        message +=
            " And they have no cards left! ${updatedPlayers[prevIdx].name} WINS!";
      }
    }

    return state.copyWith(
      players: updatedPlayers,
      centerPile: [],
      lastPlayedCards: [],
      lastClaimedRank: null,
      lastPlayerId: null,
      consecutivePasses: 0,
      resolvingBluffMessage: message,
      status: newStatus,
      clearPendingBluffCallerId: true,
      clearCurrentRoundRank: true,
      playersActedThisRound: {},
      clearLastCardPlayerId: true,
      currentPlayerId: loserId,
    );
  }
}
