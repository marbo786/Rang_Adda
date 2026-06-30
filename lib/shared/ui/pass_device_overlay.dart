import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class PassDeviceOverlay extends StatelessWidget {
  final String playerName;
  final VoidCallback onAcknowledge;

  const PassDeviceOverlay({
    super.key,
    required this.playerName,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: AppTheme.backgroundPrimary.withValues(alpha: 0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPrimary.withValues(alpha: 0.30),
                width: 1.5,
              ),
              boxShadow: [BoxShadow(color: AppTheme.neonGlow, blurRadius: 24)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 48,
                  color: AppTheme.accentPrimary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Pass device to',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playerName.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.accentPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: AppTheme.neonGlow, blurRadius: 8)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(
                        const BorderSide(
                          color: AppTheme.accentPrimary,
                          width: 1.5,
                        ),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return AppTheme.accentPrimary.withValues(alpha: 0.15);
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.all(
                        AppTheme.accentPrimary,
                      ),
                    ),
                    onPressed: () {
                      onAcknowledge();
                    },
                    child: const Text(
                      'READY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
