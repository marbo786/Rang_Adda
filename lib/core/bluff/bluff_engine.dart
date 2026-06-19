import '../models/card_model.dart';
import '../models/player.dart';
import 'bluff_game_state.dart';

class BluffEngine {
  static BluffGameState initializeGame(List<String> playerIds, [List<String>? playerNames]) {
    final deck = _createDeck();
    deck.shuffle();

    List<Player> players = [];
    for (int i = 0; i < playerIds.length; i++) {
      players.add(Player(
        id: playerIds[i],
        name: playerNames != null && playerNames.length > i ? playerNames[i] : 'Player ${i + 1}',
        hand: [],
      ));
    }

    // Deal cards
    int pIdx = 0;
    while (deck.isNotEmpty) {
      players[pIdx].hand.add(deck.removeLast());
      pIdx = (pIdx + 1) % players.length;
    }
    
    // Sort hands
    for (var player in players) {
      player.hand.sort((a, b) => a.rank.index.compareTo(b.rank.index));
    }

    return BluffGameState(
      gameId: 'local_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      status: BluffGameStatus.playing,
      currentPlayerId: players[0].id,
      currentRequiredRank: Rank.ace,
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

  static Rank _getNextRank(Rank current) {
    int nextIndex = (current.index + 1) % Rank.values.length;
    return Rank.values[nextIndex];
  }

  static String? getMoveError(BluffGameState state, String playerId, List<PlayingCard> cards) {
    if (state.status == BluffGameStatus.finished) return "Game is already finished.";
    if (state.currentPlayerId != playerId) return "It's not your turn.";
    if (cards.isEmpty || cards.length > 4) return "You must play between 1 and 4 cards.";
    
    final player = state.players.firstWhere((p) => p.id == playerId);
    for (var card in cards) {
      if (!player.hand.contains(card)) {
        return "You don't have those cards.";
      }
    }
    return null;
  }

  static BluffGameState playCards(BluffGameState state, String playerId, List<PlayingCard> cards) {
    final error = getMoveError(state, playerId, cards);
    if (error != null) throw Exception(error);

    List<Player> updatedPlayers = List.from(state.players);
    int pIdx = updatedPlayers.indexWhere((p) => p.id == playerId);
    Player player = updatedPlayers[pIdx];

    List<PlayingCard> newHand = List.from(player.hand);
    for (var card in cards) {
      newHand.remove(card);
    }
    updatedPlayers[pIdx] = player.copyWith(hand: newHand);

    List<PlayingCard> newCenterPile = List.from(state.centerPile)..addAll(cards);
    
    // Check win condition
    BluffGameStatus newStatus = state.status;
    if (newHand.isEmpty) {
      // In Bluff, you only win if no one calls your bluff on the final play.
      // So the game isn't finished YET. We just wait for a challenge.
    }

    int nextPIdx = (pIdx + 1) % updatedPlayers.length;
    String nextPlayerId = updatedPlayers[nextPIdx].id;

    return state.copyWith(
      players: updatedPlayers,
      currentPlayerId: nextPlayerId,
      lastPlayerId: playerId,
      centerPile: newCenterPile,
      lastPlayedCards: cards,
      lastClaimedRank: state.currentRequiredRank,
      currentRequiredRank: _getNextRank(state.currentRequiredRank),
      consecutivePasses: 0,
      passToPlayerId: nextPlayerId,
      resolvingBluffMessage: null,
      status: newStatus,
    );
  }

  static BluffGameState passTurn(BluffGameState state, String playerId) {
    if (state.status == BluffGameStatus.finished) throw Exception("Game is already finished.");
    if (state.currentPlayerId != playerId) throw Exception("It's not your turn.");

    List<Player> updatedPlayers = List.from(state.players);
    int pIdx = updatedPlayers.indexWhere((p) => p.id == playerId);
    
    int nextPIdx = (pIdx + 1) % updatedPlayers.length;
    String nextPlayerId = updatedPlayers[nextPIdx].id;

    int newConsecutivePasses = state.consecutivePasses + 1;
    List<PlayingCard> newCenterPile = List.from(state.centerPile);
    List<PlayingCard> newLastPlayed = List.from(state.lastPlayedCards);
    Rank? newLastClaimed = state.lastClaimedRank;
    String? newLastPlayerId = state.lastPlayerId;

    if (newConsecutivePasses >= state.players.length) {
      // Everyone passed. Center pile is discarded.
      newCenterPile = [];
      newLastPlayed = [];
      newLastClaimed = null;
      newLastPlayerId = null;
      newConsecutivePasses = 0;
    }

    return state.copyWith(
      currentPlayerId: nextPlayerId,
      currentRequiredRank: _getNextRank(state.currentRequiredRank),
      consecutivePasses: newConsecutivePasses,
      centerPile: newCenterPile,
      lastPlayedCards: newLastPlayed,
      lastClaimedRank: newLastClaimed,
      lastPlayerId: newLastPlayerId,
      passToPlayerId: nextPlayerId,
      resolvingBluffMessage: null,
    );
  }

  static BluffGameState callBluff(BluffGameState state, String callerId) {
    if (state.status == BluffGameStatus.finished) throw Exception("Game is finished.");
    if (state.lastPlayerId == null || state.lastPlayedCards.isEmpty || state.lastClaimedRank == null) {
      throw Exception("No cards to call bluff on.");
    }
    if (callerId == state.lastPlayerId) {
      throw Exception("You can't call bluff on yourself.");
    }

    bool isBluff = false;
    for (var card in state.lastPlayedCards) {
      if (card.rank != state.lastClaimedRank) {
        isBluff = true;
        break;
      }
    }

    String loserId = isBluff ? state.lastPlayerId! : callerId;
    String winnerId = isBluff ? callerId : state.lastPlayerId!;
    
    List<Player> updatedPlayers = List.from(state.players);
    int loserIdx = updatedPlayers.indexWhere((p) => p.id == loserId);
    Player loser = updatedPlayers[loserIdx];
    
    List<PlayingCard> newHand = List.from(loser.hand)..addAll(state.centerPile);
    newHand.sort((a, b) => a.rank.index.compareTo(b.rank.index));
    updatedPlayers[loserIdx] = loser.copyWith(hand: newHand);

    String message = isBluff 
      ? "\${updatedPlayers.firstWhere((p)=>p.id==state.lastPlayerId!).name} WAS BLUFFING! They pick up the pile."
      : "\${updatedPlayers.firstWhere((p)=>p.id==state.lastPlayerId!).name} told the TRUTH! \${updatedPlayers.firstWhere((p)=>p.id==callerId).name} picks up the pile.";

    // Check if the previous player told the truth AND emptied their hand -> They win!
    BluffGameStatus newStatus = state.status;
    if (!isBluff) {
      int prevIdx = updatedPlayers.indexWhere((p) => p.id == state.lastPlayerId!);
      if (updatedPlayers[prevIdx].hand.isEmpty) {
        newStatus = BluffGameStatus.finished;
        message += " And they have no cards left! \${updatedPlayers[prevIdx].name} WINS!";
      }
    }

    // Play continues with the next player in normal order (which is already state.currentPlayerId)
    // Wait, the rules say "Play then continues with Player C." - Yes, normal order.
    // Except if the game is finished.
    return state.copyWith(
      players: updatedPlayers,
      centerPile: [],
      lastPlayedCards: [],
      lastClaimedRank: null,
      lastPlayerId: null,
      consecutivePasses: 0,
      resolvingBluffMessage: message,
      status: newStatus,
    );
  }
}
