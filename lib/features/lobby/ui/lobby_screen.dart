import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';
import 'package:rang_adda/shared/ui/lobby_background.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';

enum ButtonType { primary, secondary }

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  late AnimationController _logoController;
  late AnimationController _underlineController;
  late AnimationController _cardsController;

  @override
  void initState() {
    super.initState();
    _codeFocus.addListener(() {
      setState(() {});
    });

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });

    _underlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref
            .read(authProvider)
            .signInAnonymously("Player_${DateTime.now().millisecond}");
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Firebase Error: $e"),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    _logoController.dispose();
    _underlineController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    ButtonType type = ButtonType.secondary,
  }) {
    final isPrimary = type == ButtonType.primary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppTheme.accentPrimary
              : Colors.transparent,
          foregroundColor: isPrimary
              ? AppTheme.backgroundPrimary
              : AppTheme.accentPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: AppTheme.accentPrimary, width: 1.5),
          ),
        ),
        onPressed: () {
          ref.read(audioServiceProvider).playClick();
          onPressed();
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: isPrimary ? 2.0 : 1.5,
          ),
        ),
      ),
    );
  }

  void _showHostGameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.accentPrimary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          title: const Text(
            'HOST GAME',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton('THULLA', () {
                Navigator.of(context).pop();
                _hostGame('thulla');
              }),
              const SizedBox(height: 12),
              _buildButton('BLUFF', () {
                Navigator.of(context).pop();
                _hostGame('bluff');
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _hostGame(String gameType) async {
    final user = ref.read(userProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Connecting...")));
      try {
        await ref
            .read(authProvider)
            .signInAnonymously("Host_${DateTime.now().millisecond}");
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Auth Failed: $e")));
        }
        return;
      }
    }
    try {
      String? uid =
          user?.uid ??
          (await ref
                  .read(authProvider)
                  .signInAnonymously("Host_${DateTime.now().millisecond}"))
              ?.uid;
      if (uid == null) throw Exception("Auth failed");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Creating room...")));
      }
      final gameId = await ref
          .read(firestoreServiceProvider)
          .createWaitingRoom(uid, user?.displayName ?? "Host", gameType)
          .timeout(const Duration(seconds: 5));
      ref.read(currentGameIdProvider.notifier).setId(gameId);
      if (mounted) {
        context.push('/waiting_room/$gameId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final isOnlineFocused = _codeFocus.hasFocus;

    if (userAsyncValue.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: AppTheme.accentPrimary),
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: AppTheme.accentPrimary),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const GameTableBackground(child: SizedBox.expand()),
          const LobbyBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top: Logo Area
                        _buildLogoBlock(),
                        const Spacer(flex: 1),

                        if (ref.watch(currentGameIdProvider) != null) ...[
                          _buildButton('RECONNECT TO GAME', () {
                            final gameId = ref.read(currentGameIdProvider);
                            if (gameId != null) {
                              context.push('/waiting_room/$gameId');
                            }
                          }, type: ButtonType.primary),
                          const SizedBox(height: 12),
                          _buildButton('LEAVE CURRENT GAME', () {
                            ref
                                .read(currentGameIdProvider.notifier)
                                .setId(null);
                          }),
                          const SizedBox(height: 32),
                        ],

                        // Center: Online Play Panel
                        _buildOnlinePlayPanel(isOnlineFocused),
                        const Spacer(flex: 2),

                        // Bottom: Local Games
                        _buildLocalGamesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoBlock() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final opacity = _logoController.value;
        final translateY = 20.0 * (1 - opacity);
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'RANG',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10.0,
                    color: AppTheme.accentPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentSecondary,
                      shadows: [
                        Shadow(color: AppTheme.cyanGlow, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'ADDA',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10.0,
                    color: AppTheme.accentSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Pakistan's Card Games",
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _underlineController,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        AppTheme.accentPrimary,
                        Colors.white,
                        AppTheme.accentSecondary,
                      ],
                      stops: [
                        (_underlineController.value - 0.2).clamp(0.0, 1.0),
                        _underlineController.value,
                        (_underlineController.value + 0.2).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlinePlayPanel(bool isOnlineFocused) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.15),
        ),
        boxShadow: isOnlineFocused
            ? [BoxShadow(color: AppTheme.neonGlow, blurRadius: 16)]
            : [],
      ),
      child: Column(
        children: [
          const Text(
            '── ONLINE PLAY ──',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.0,
              color: AppTheme.textDisabled,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            focusNode: _codeFocus,
            textAlign: TextAlign.center,
            cursorColor: AppTheme.accentPrimary,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'ENTER ROOM CODE',
              counterText: '', // Hide the length counter
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 16,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w600,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.textDisabled),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.textDisabled),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accentPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildButton('JOIN GAME', () async {
            final user = ref.read(userProvider).value;
            if (user == null || _codeController.text.isEmpty) return;
            try {
              await ref
                  .read(firestoreServiceProvider)
                  .joinWaitingRoom(
                    _codeController.text,
                    user.uid,
                    user.displayName ?? "Player",
                  );
              ref
                  .read(currentGameIdProvider.notifier)
                  .setId(_codeController.text);
              if (mounted) {
                context.push('/waiting_room/${_codeController.text}');
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          }, type: ButtonType.primary),
          const SizedBox(height: 10),
          _buildButton('HOST NEW GAME', _showHostGameDialog),
        ],
      ),
    );
  }

  Widget _buildLocalGamesSection() {
    return Column(
      children: [
        const Text(
          '── LOCAL GAMES ──',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: AppTheme.textDisabled,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildGameCard(
                  title: 'THULLA',
                  subtitle: 'Getaway',
                  gradientColors: const [Color(0xFF0A1A10), Color(0xFF060A0F)],
                  borderColor: AppTheme.accentPrimary.withValues(alpha: 0.25),
                  icons: const ['♠', '♠', '♠'],
                  iconsColor: AppTheme.accentPrimary.withValues(alpha: 0.08),
                  onTap: () => context.push('/setup/thulla'),
                  interval: const Interval(
                    0.0,
                    0.714,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 16),
                _buildGameCard(
                  title: 'BLUFF',
                  subtitle: 'Cheat / BS',
                  gradientColors: const [Color(0xFF1A0A0A), Color(0xFF060A0F)],
                  borderColor: AppTheme.statusError.withValues(alpha: 0.20),
                  icons: const ['♥', '♦', '♣'],
                  iconsColor: AppTheme.statusError.withValues(alpha: 0.08),
                  onTap: () => context.push('/setup/bluff'),
                  interval: const Interval(
                    0.142,
                    0.857,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 16),
                _buildGameCard(
                  title: 'RANG',
                  subtitle: 'Court Piece',
                  gradientColors: const [Color(0xFF0A0A1A), Color(0xFF060A0F)],
                  borderColor: AppTheme.accentTertiary.withValues(alpha: 0.25),
                  icons: const ['♥', '♠', '♦', '♣'],
                  iconsColor: AppTheme.accentTertiary.withValues(alpha: 0.10),
                  onTap: () => context.push('/setup/rang'),
                  interval: const Interval(
                    0.285,
                    1.0,
                    curve: Curves.easeOutCubic,
                  ),
                  isComingSoon: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color borderColor,
    required List<String> icons,
    required Color iconsColor,
    required VoidCallback onTap,
    required Interval interval,
    bool isComingSoon = false,
  }) {
    return AnimatedBuilder(
      animation: _cardsController,
      builder: (context, child) {
        final progress = interval.transform(_cardsController.value);
        final opacity = progress;
        final translateY = 20.0 * (1 - progress);
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          // HapticFeedback.lightImpact();
          ref.read(audioServiceProvider).playClick();
          onTap();
        },
        child: Container(
          width: 160,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isComingSoon)
                Positioned(
                  top: 12,
                  right: -30,
                  child: Transform.rotate(
                    angle: 0.785398, // 45 degrees
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 4,
                      ),
                      color: AppTheme.accentSecondary,
                      child: const Text(
                        'SOON',
                        style: TextStyle(
                          color: AppTheme.backgroundPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              // Diagonal Icons
              ...List.generate(icons.length, (index) {
                return Positioned(
                  right: 10.0 + (index * 25),
                  top: 20.0 + (index * 30),
                  child: Text(
                    icons[index],
                    style: TextStyle(
                      fontSize: 48,
                      color: iconsColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              // Text Content
              Positioned(
                left: 16,
                bottom: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: borderColor.withValues(alpha: 1.0),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'TAP TO PLAY',
                    style: TextStyle(
                      color: AppTheme.textDisabled,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
