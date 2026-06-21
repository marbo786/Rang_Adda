import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String displayName;
  final int wins;
  final int losses;
  final int gamesPlayed;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.wins = 0,
    this.losses = 0,
    this.gamesPlayed = 0,
    required this.createdAt,
  });

  double get winRate => gamesPlayed == 0 ? 0.0 : (wins / gamesPlayed) * 100;

  UserModel copyWith({
    String? uid,
    String? displayName,
    int? wins,
    int? losses,
    int? gamesPlayed,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'wins': wins,
        'losses': losses,
        'gamesPlayed': gamesPlayed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [uid, displayName, wins, losses, gamesPlayed, createdAt];
}
