import 'package:rang_adda/shared/models/card_model.dart';

/// Tracks what cards are played and which players are known to be void in certain suits.
class CardTracker {
  // All 52 cards initially.
  final Set<PlayingCard> _unseenCards = {
    for (var s in Suit.values)
      for (var r in Rank.values) PlayingCard(suit: s, rank: r),
  };

  // Maps opponentId to a set of suits they are known to NOT have.
  final Map<String, Set<Suit>> _voidSuits = {};

  CardTracker();

  /// Call this when the bot is initialized with its own hand.
  void initializeMyHand(List<PlayingCard> myHand) {
    _unseenCards.removeAll(myHand);
  }

  /// Call this whenever ANY card is played face-up on the table.
  void markCardSeen(PlayingCard card) {
    _unseenCards.remove(card);
  }

  /// Mark that a player is void in a suit.
  /// (e.g. they played an off-suit card when a lead suit was requested).
  void markVoidSuit(String playerId, Suit suit) {
    _voidSuits.putIfAbsent(playerId, () => {}).add(suit);
  }

  /// Returns true if the player is definitely void in the given suit.
  bool isPlayerVoid(String playerId, Suit suit) {
    return _voidSuits[playerId]?.contains(suit) ?? false;
  }

  /// Returns all cards that haven't been seen yet.
  List<PlayingCard> get unseenCards => _unseenCards.toList();

  /// Estimates the probability that an opponent has a specific card.
  /// 0.0 if the card has already been seen or the opponent is void in its suit.
  double probabilityOfHavingCard(String opponentId, PlayingCard card) {
    if (!_unseenCards.contains(card)) return 0.0;
    if (isPlayerVoid(opponentId, card.suit)) return 0.0;

    // A rough estimation:
    // How many unseen cards can this opponent hold?
    // We don't track exact hand sizes perfectly here, but we assume equal distribution
    // among non-void opponents.
    int eligibleOpponents = 0;
    for (final id in _voidSuits.keys) {
      if (!isPlayerVoid(id, card.suit)) {
        eligibleOpponents++;
      }
    }

    if (eligibleOpponents == 0) return 0.0; // Should not happen ideally
    return 1.0 / eligibleOpponents;
  }
}
