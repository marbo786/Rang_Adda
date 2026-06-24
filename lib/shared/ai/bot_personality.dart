import 'dart:math';

class BotPersonality {
  /// Willingness to take risks (0.0 to 1.0).
  /// High = aggressive leading, more likely to call bluffs.
  final double riskTolerance;

  /// How often the bot bluffs when it has the opportunity (0.0 to 1.0).
  final double bluffFrequency;

  /// Tendency to play high cards early (0.0 to 1.0).
  final double aggressiveness;

  const BotPersonality({
    required this.riskTolerance,
    required this.bluffFrequency,
    required this.aggressiveness,
  });

  /// Deterministically generate a personality based on the bot's name hash.
  /// This ensures 'Bot Asad' always plays with the same style.
  factory BotPersonality.fromName(String name) {
    // Use a seeded random generator based on the name's hash code
    final random = Random(name.hashCode);

    return BotPersonality(
      riskTolerance: 0.3 + (random.nextDouble() * 0.6), // 0.3 to 0.9
      bluffFrequency: 0.2 + (random.nextDouble() * 0.6), // 0.2 to 0.8
      aggressiveness: 0.4 + (random.nextDouble() * 0.5), // 0.4 to 0.9
    );
  }

  /// Helper to check if the bot should take a risk, given a threshold.
  bool shouldTakeRisk(double threshold) {
    return riskTolerance > threshold;
  }
}
