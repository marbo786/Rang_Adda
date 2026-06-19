import 'dart:ui';
import 'package:flutter/material.dart';

class PassDeviceOverlay extends StatelessWidget {
  final String playerName;
  final VoidCallback onAcknowledge;

  const PassDeviceOverlay({
    Key? key,
    required this.playerName,
    required this.onAcknowledge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.screen_lock_portrait, size: 48, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Pass device to',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color, 
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playerName.toUpperCase(),
                  style: TextStyle(
                     color: Theme.of(context).primaryColor, 
                     fontSize: 32, 
                     fontWeight: FontWeight.w900,
                     letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: onAcknowledge,
                    child: const Text('READY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
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
