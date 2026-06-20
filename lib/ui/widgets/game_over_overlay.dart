import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class GameOverOverlay extends StatefulWidget {
  final String winnerName;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToLobby;

  const GameOverOverlay({
    super.key,
    required this.winnerName,
    required this.onPlayAgain,
    required this.onBackToLobby,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _titleController;
  late AnimationController _buttonsController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward(from: 0.3);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _titleController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti effect
        ConfettiWidget(
          controller: _confettiController,
        ),
        // Semi-transparent overlay
        Container(
          color: Colors.black.withValues(alpha: 0.6),
        ),
        // Content
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Winner announcement
                ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: _titleController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _titleController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                    child: Column(
                      children: [
                        // Celebratory icon
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                AppTheme.statusSuccess,
                                AppTheme.accentPrimary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.celebration_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Winner name
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                AppTheme.statusSuccess,
                                AppTheme.accentPrimary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Text(
                            widget.winnerName,
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "WINS!" text
                        Text(
                          'WINS!',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: AppTheme.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Action buttons
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: _buttonsController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    )
                        .animate(
                          CurvedAnimation(
                            parent: _buttonsController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Column(
                      children: [
                        // Play Again button
                        SizedBox(
                          width: 280,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusSuccess,
                              foregroundColor: AppTheme.backgroundPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              shadowColor:
                                  AppTheme.statusSuccess.withValues(alpha: 0.5),
                            ),
                            onPressed: widget.onPlayAgain,
                            child: const Text(
                              'PLAY AGAIN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Back to Lobby button
                        SizedBox(
                          width: 280,
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.statusSuccess,
                              side: const BorderSide(
                                color: AppTheme.statusSuccess,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: widget.onBackToLobby,
                            child: const Text(
                              'BACK TO LOBBY',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ConfettiWidget extends StatefulWidget {
  final AnimationController controller;

  const ConfettiWidget({
    super.key,
    required this.controller,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> {
  late List<Confetti> confetti;

  @override
  void initState() {
    super.initState();
    _generateConfetti();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    confetti = List.generate(50, (index) {
      return Confetti(
        x: random.nextDouble(),
        y: 0,
        xVelocity: (random.nextDouble() - 0.5) * 2,
        yVelocity: random.nextDouble() * 0.5 + 0.3,
        rotation: random.nextDouble() * 360,
        rotationVelocity: (random.nextDouble() - 0.5) * 10,
        size: random.nextDouble() * 8 + 4,
        color: [
          AppTheme.statusSuccess,
          AppTheme.accentPrimary,
          AppTheme.accentSecondary,
          Colors.cyan,
          Colors.amber,
        ][random.nextInt(5)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ConfettiPainter(
        confetti: confetti,
        progress: widget.controller.value,
      ),
      size: Size.infinite,
    );
  }
}

class Confetti {
  double x;
  double y;
  double xVelocity;
  double yVelocity;
  double rotation;
  double rotationVelocity;
  double size;
  Color color;

  Confetti({
    required this.x,
    required this.y,
    required this.xVelocity,
    required this.yVelocity,
    required this.rotation,
    required this.rotationVelocity,
    required this.size,
    required this.color,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;
  final double progress;

  ConfettiPainter({
    required this.confetti,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in confetti) {
      // Update position
      particle.x += particle.xVelocity * progress;
      particle.y += particle.yVelocity * progress;
      particle.rotation += particle.rotationVelocity * progress;

      // Add gravity
      final gravity = 0.1 * progress;
      particle.yVelocity += gravity;

      // Opacity based on progress (fade out near the end)
      final opacity = 1.0 - (progress > 0.7 ? (progress - 0.7) / 0.3 : 0.0);

      // Only draw if particle is still visible
      if (particle.y < 1.0 && opacity > 0) {
        final paint = Paint()
          ..color = particle.color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(
          particle.x * size.width,
          particle.y * size.height,
        );
        canvas.rotate(particle.rotation * math.pi / 180);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
