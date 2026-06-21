import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/chat_message.dart';
import 'package:rang_adda/features/rang/engine/rang_trick_play.dart';

/// The two phases a Rang game moves through.
///
/// [trumpSelection] — the round begins; the dealer's partner must declare a
///   trump suit (Rang) before any trick is played.
/// [trickPlay]     — trump has been declared; 13 tricks are played out.
enum RangPhase { trumpSelection, trickPlay }

/// Full immutable snapshot of a Rang game at any point in time.
///
/// Team composition (fixed partnerships):
///   • Team A: players[0] & players[2]
///   • Team B: players[1] & players[3]
///
/// Sars scoring: each trick won counts as one sar.  The first team to reach
/// 7 sars wins the hand.  Special bonuses:
///   • [kot]    — winning team reached 7 sars before the losing team scored any.
///   • [bavney] — winning team collected all 13 tricks.
class RangGameState extends GameState {
  /// The player currently dealing the hand.
  final String dealerId;

  /// The player who declared (or will declare) the trump suit.
  /// Always the dealer's partner (players[(dealerIndex + 2) % 4]).
  final String trumpCallerId;

  /// The declared trump suit.  Null during [RangPhase.trumpSelection].
  final Suit? trumpSuit;

  /// The current phase of the game.
  final RangPhase phase;

  /// The suit led by the first card of the current trick.
  /// Null when no trick is in progress (between tricks).
  final Suit? leadSuit;

  /// Cards played so far in the current trick (0–4 entries).
  final List<RangTrickPlay> currentTrick;

  /// Accumulated cards from all completed tricks that have not yet been
  /// awarded to a team (cleared when a sar is scored).
  final List<PlayingCard> heap;

  /// The player who won the most-recently completed trick.
  final String? lastTrickWinnerId;

  /// How many tricks in a row [lastTrickWinnerId]'s team has won.
  /// Used by the engine for future streak / bonus logic.
  final int consecutiveWinsByLastWinner;

  /// Number of sars (tricks) won by Team A (players[0] & players[2]).
  final int teamASars;

  /// Number of sars (tricks) won by Team B (players[1] & players[3]).
  final int teamBSars;

  /// When non-null, the UI shows the Pass-Device overlay asking this player
  /// to take the device before their turn is revealed.
  /// Mirrors the identical field in [ThullaGameState].
  final String? passToPlayerId;

  /// 'A' or 'B' once the game is finished; null while the hand is in play.
  final String? winningTeam;

  /// True when the winning team reached 7 sars before the other team
  /// scored a single sar (a "kot").
  final bool kot;

  /// True when the winning team collected every one of the 13 tricks
  /// (a "bavney" / grand slam).
  final bool bavney;

  const RangGameState({
    required super.gameId,
    super.gameType = 'rang',
    required super.players,
    required super.status,
    super.currentPlayerId,
    super.chatMessages = const [],
    required this.dealerId,
    required this.trumpCallerId,
    this.trumpSuit,
    this.phase = RangPhase.trumpSelection,
    this.leadSuit,
    this.currentTrick = const [],
    this.heap = const [],
    this.lastTrickWinnerId,
    this.consecutiveWinsByLastWinner = 0,
    this.teamASars = 0,
    this.teamBSars = 0,
    this.passToPlayerId,
    this.winningTeam,
    this.kot = false,
    this.bavney = false,
  });

  // ── Convenience getters ──────────────────────────────────────────────────

  /// Total sars scored so far (sanity-check helper).
  int get totalSarsScored => teamASars + teamBSars;

  // ── copyWith ─────────────────────────────────────────────────────────────

  RangGameState copyWith({
    String? gameId,
    List<Player>? players,
    GameStatus? status,
    String? currentPlayerId,
    bool clearCurrentPlayerId = false,
    String? dealerId,
    String? trumpCallerId,
    Suit? trumpSuit,
    bool clearTrumpSuit = false,
    RangPhase? phase,
    Suit? leadSuit,
    bool clearLeadSuit = false,
    List<RangTrickPlay>? currentTrick,
    List<PlayingCard>? heap,
    String? lastTrickWinnerId,
    bool clearLastTrickWinnerId = false,
    int? consecutiveWinsByLastWinner,
    int? teamASars,
    int? teamBSars,
    String? passToPlayerId,
    bool clearPassToPlayerId = false,
    String? winningTeam,
    bool clearWinningTeam = false,
    bool? kot,
    bool? bavney,
    List<ChatMessage>? chatMessages,
  }) {
    return RangGameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentPlayerId: clearCurrentPlayerId
          ? null
          : (currentPlayerId ?? this.currentPlayerId),
      chatMessages: chatMessages ?? this.chatMessages,
      dealerId: dealerId ?? this.dealerId,
      trumpCallerId: trumpCallerId ?? this.trumpCallerId,
      trumpSuit: clearTrumpSuit ? null : (trumpSuit ?? this.trumpSuit),
      phase: phase ?? this.phase,
      leadSuit: clearLeadSuit ? null : (leadSuit ?? this.leadSuit),
      currentTrick: currentTrick ?? this.currentTrick,
      heap: heap ?? this.heap,
      lastTrickWinnerId: clearLastTrickWinnerId
          ? null
          : (lastTrickWinnerId ?? this.lastTrickWinnerId),
      consecutiveWinsByLastWinner:
          consecutiveWinsByLastWinner ?? this.consecutiveWinsByLastWinner,
      teamASars: teamASars ?? this.teamASars,
      teamBSars: teamBSars ?? this.teamBSars,
      passToPlayerId: clearPassToPlayerId
          ? null
          : (passToPlayerId ?? this.passToPlayerId),
      winningTeam:
          clearWinningTeam ? null : (winningTeam ?? this.winningTeam),
      kot: kot ?? this.kot,
      bavney: bavney ?? this.bavney,
    );
  }

  // ── Equatable ────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        ...super.props,
        dealerId,
        trumpCallerId,
        trumpSuit,
        phase,
        leadSuit,
        currentTrick,
        heap,
        lastTrickWinnerId,
        consecutiveWinsByLastWinner,
        teamASars,
        teamBSars,
        passToPlayerId,
        winningTeam,
        kot,
        bavney,
      ];

  // ── Serialisation (Firestore-compatible) ─────────────────────────────────

  @override
  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'gameType': gameType,
        'players': players.map((p) => p.toJson()).toList(),
        'status': status.index,
        'currentPlayerId': currentPlayerId,
        'chatMessages': chatMessages.map((m) => m.toJson()).toList(),
        'dealerId': dealerId,
        'trumpCallerId': trumpCallerId,
        'trumpSuit': trumpSuit?.index,
        'phase': phase.index,
        'leadSuit': leadSuit?.index,
        'currentTrick': currentTrick.map((t) => t.toJson()).toList(),
        'heap': heap.map((c) => c.toJson()).toList(),
        'lastTrickWinnerId': lastTrickWinnerId,
        'consecutiveWinsByLastWinner': consecutiveWinsByLastWinner,
        'teamASars': teamASars,
        'teamBSars': teamBSars,
        'passToPlayerId': passToPlayerId,
        'winningTeam': winningTeam,
        'kot': kot,
        'bavney': bavney,
      };

  factory RangGameState.fromJson(Map<String, dynamic> json) {
    return RangGameState(
      gameId: json['gameId'] as String,
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: GameStatus.values[json['status'] as int],
      currentPlayerId: json['currentPlayerId'] as String?,
      chatMessages: (json['chatMessages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      dealerId: json['dealerId'] as String,
      trumpCallerId: json['trumpCallerId'] as String,
      trumpSuit: json['trumpSuit'] != null
          ? Suit.values[json['trumpSuit'] as int]
          : null,
      phase: RangPhase.values[json['phase'] as int? ?? 0],
      leadSuit: json['leadSuit'] != null
          ? Suit.values[json['leadSuit'] as int]
          : null,
      currentTrick: (json['currentTrick'] as List)
          .map((t) => RangTrickPlay.fromJson(t as Map<String, dynamic>))
          .toList(),
      heap: (json['heap'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      lastTrickWinnerId: json['lastTrickWinnerId'] as String?,
      consecutiveWinsByLastWinner:
          json['consecutiveWinsByLastWinner'] as int? ?? 0,
      teamASars: json['teamASars'] as int? ?? 0,
      teamBSars: json['teamBSars'] as int? ?? 0,
      passToPlayerId: json['passToPlayerId'] as String?,
      winningTeam: json['winningTeam'] as String?,
      kot: json['kot'] as bool? ?? false,
      bavney: json['bavney'] as bool? ?? false,
    );
  }
}
