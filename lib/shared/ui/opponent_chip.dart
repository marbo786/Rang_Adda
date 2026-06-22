import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class OpponentChip extends StatefulWidget {
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

  @override
  State<OpponentChip> createState() => _OpponentChipState();
}

class _OpponentChipState extends State<OpponentChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowOpacity = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OpponentChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(widget.playerName);
    const avatarSize = 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatarSize + 16, // Extra space for glows and badges
            height: avatarSize + 16,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Active glow ring
                if (widget.isActive)
                  AnimatedBuilder(
                    animation: _glowOpacity,
                    builder: (context, child) {
                      return Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPrimary.withOpacity(_glowOpacity.value),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Avatar Container with gradient border
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppTheme.accentPrimary,
                        AppTheme.accentSecondary,
                        AppTheme.accentPrimary,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0), // Border thickness
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceElevated,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: widget.hasPower
                                ? AppTheme.accentSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Card count badge
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSecondary.withOpacity(0.15),
                      border: Border.all(
                        color: AppTheme.accentSecondary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16), // Pill shape
                    ),
                    child: Text(
                      '${widget.cardCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentSecondary,
                      ),
                    ),
                  ),
                ),

                // Emoji (top-right)
                if (widget.latestEmoji != null && widget.latestEmoji!.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Text(
                      widget.latestEmoji!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Player name
          Text(
            widget.playerName.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: widget.hasPower
                  ? AppTheme.accentSecondary
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
