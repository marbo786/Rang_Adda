import 'package:flutter/material.dart';

class TuingRabbitOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TuingRabbitOverlay({super.key, required this.onComplete});

  @override
  State<TuingRabbitOverlay> createState() => _TuingRabbitOverlayState();
}

class _TuingRabbitOverlayState extends State<TuingRabbitOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> xAnimation;
  late Animation<double> yAnimation;
  late Animation<double> shadowOpacity;
  late Animation<double> scaleYAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Rabbit travels from right to left
    xAnimation = Tween<double>(
      begin: screenWidth + 50,
      end: -150,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));

    final groundY = screenHeight * 0.4;
    final jumpHeight = 120.0;

    // Create 3 bounces over 1.1s
    final ySequence = <TweenSequenceItem<double>>[];
    final shadowSequence = <TweenSequenceItem<double>>[];
    final scaleSequence = <TweenSequenceItem<double>>[];

    int numBounces = 3;
    double weightPerBounce = 100.0 / numBounces;

    for (int i = 0; i < numBounces; i++) {
      // Jump up
      ySequence.add(
        TweenSequenceItem(
          tween: Tween<double>(
            begin: groundY,
            end: groundY - jumpHeight,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: weightPerBounce * 0.4,
        ),
      );
      shadowSequence.add(
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.6,
            end: 0.1,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: weightPerBounce * 0.4,
        ),
      );
      scaleSequence.add(
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          weight: weightPerBounce * 0.4,
        ),
      );

      // Fall down
      ySequence.add(
        TweenSequenceItem(
          tween: Tween<double>(
            begin: groundY - jumpHeight,
            end: groundY,
          ).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: weightPerBounce * 0.4,
        ),
      );
      shadowSequence.add(
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.1,
            end: 0.6,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: weightPerBounce * 0.4,
        ),
      );
      scaleSequence.add(
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          weight: weightPerBounce * 0.4,
        ),
      );

      // Squish
      ySequence.add(
        TweenSequenceItem(
          tween: Tween<double>(begin: groundY, end: groundY),
          weight: weightPerBounce * 0.2,
        ),
      );
      shadowSequence.add(
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.6, end: 0.6),
          weight: weightPerBounce * 0.2,
        ),
      );
      scaleSequence.add(
        TweenSequenceItem(
          tween: TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween<double>(begin: 1.0, end: 0.7),
              weight: 50,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.7, end: 1.0),
              weight: 50,
            ),
          ]),
          weight: weightPerBounce * 0.2,
        ),
      );
    }

    yAnimation = TweenSequence<double>(ySequence).animate(controller);
    shadowOpacity = TweenSequence<double>(shadowSequence).animate(controller);
    scaleYAnimation = TweenSequence<double>(scaleSequence).animate(controller);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Shadow (rendered slightly below rabbit)
            Positioned(
              left:
                  xAnimation.value +
                  10, // slight offset so shadow is under rabbit
              top: yAnimation.value + 72, // below the rabbit image
              child: Opacity(
                opacity: shadowOpacity.value,
                child: Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
            // Rabbit
            Positioned(
              left: xAnimation.value,
              top: yAnimation.value,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  1.0,
                  scaleYAnimation.value,
                  1.0,
                ),
                child: Image.asset(
                  'assets/images/rabbit_tuing.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
