import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

/// A reusable opponent chip widget showing player avatar, card count badge,
/// and animated glow ring when active (player's turn).
/// 
/// Features:
/// - Circular avatar with player initials
/// - Card-count badge anchored to the avatar
/// - Animated glow ring on active turn (accentPrimary)
/// - Optional power highlight for game-specific logic
class OpponentChip extends StatelessWidget {
  final String playerName;
  final int cardCount;
  final bool isActive;
  final bool hasPower;
  final String? latestEmoji;

  const OpponentChip({
    super.key,
    required this.playerName,
    required this.cardCount,
    required this.isActive,
    this.hasPower = false,
    this.latestEmoji,
  });

  /// Extract initials from player name (up to 2 characters).
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(playerName);
    const avatarSize = 56.0;
    const glowWidth = 4.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with animated glow ring
          SizedBox(
            width: avatarSize + (glowWidth * 2) + 8,
            height: avatarSize + (glowWidth * 2) + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated glow ring (only when active)
                AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: avatarSize + (glowWidth * 2) + 4,
                    height: avatarSize + (glowWidth * 2) + 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentPrimary,
                        width: glowWidth,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),

                // Avatar circle with initials
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasPower
                            ? Theme.of(context).colorScheme.secondary
                            : AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Card count badge (bottom-right)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      border: Border.all(
                        color: isActive
                            ? AppTheme.accentPrimary
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.style,
                          size: 12,
                          color: hasPower
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cardCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasPower
                                ? Theme.of(context).colorScheme.secondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Emoji (top-right)
                if (latestEmoji != null && latestEmoji!.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      latestEmoji!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Player name
          Text(
            playerName.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: hasPower
                  ? Theme.of(context).colorScheme.secondary
                  : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
