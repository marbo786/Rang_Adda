import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class LobbyBackground extends StatefulWidget {
  const LobbyBackground({super.key});

  @override
  State<LobbyBackground> createState() => _LobbyBackgroundState();
}

class _LobbyBackgroundState extends State<LobbyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingSymbol> _symbols;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      _symbols = List.generate(18, (index) {
        // Pre-compute symbol properties based on index
        final isRed = index % 4 < 2; // 0,1 red; 2,3 black
        final suit = _getSuit(index);
        final startX = (index * 47.0) % size.width;
        final startY = (index * 93.0) % size.height;
        final sizeVal = 24.0 + (index % 5) * 10.0; // Varies between 24 and 64

        return _FloatingSymbol(
          suit: suit,
          isRed: isRed,
          startX: startX,
          startY: startY,
          size: sizeVal,
          index: index,
        );
      });
      _initialized = true;
    }
  }

  String _getSuit(int index) {
    switch (index % 4) {
      case 0:
        return '♥';
      case 1:
        return '♦';
      case 2:
        return '♣';
      case 3:
      default:
        return '♠';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPainter(
              symbols: _symbols,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _FloatingSymbol {
  final String suit;
  final bool isRed;
  final double startX;
  final double startY;
  final double size;
  final int index;

  _FloatingSymbol({
    required this.suit,
    required this.isRed,
    required this.startX,
    required this.startY,
    required this.size,
    required this.index,
  });
}

class _BackgroundPainter extends CustomPainter {
  final List<_FloatingSymbol> symbols;
  final double progress;

  _BackgroundPainter({required this.symbols, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var symbol in symbols) {
      // Calculate Y position with wrap around
      double y = symbol.startY - (progress * size.height * 0.4) + (symbol.index * size.height / 18);
      y = y % size.height;
      if (y < 0) y += size.height;

      // Calculate X position with sway
      final x = symbol.startX + math.sin(progress * 2 * math.pi + symbol.index) * 18;

      // Calculate rotation angle
      final angle = progress * math.pi * (symbol.index.isEven ? 1 : -1);

      // Determine color and opacity
      final color = symbol.isRed
          ? AppTheme.statusError.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.04);

      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol.suit,
          style: TextStyle(
            color: color,
            fontSize: symbol.size,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      canvas.save();
      canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
      canvas.rotate(angle);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
