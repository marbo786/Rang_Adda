import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';
import 'package:rang_adda/shared/models/game_state.dart';

enum ButtonType { primary, secondary }

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeFocus.addListener(() {
      setState(() {});
    });
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
                : BorderSide(
                    color: AppTheme.accentPrimary,
                    width: 1.5,
                  ),
          ),
        ),
        onPressed: () {
          ref.read(audioServiceProvider).playClick();
          onPressed();
        },
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  Widget _buildLocalButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: () {
        ref.read(audioServiceProvider).playClick();
        onPressed();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(
              color: AppTheme.accentPrimary,
              width: 3.0,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
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
          title: const Text(
            'HOST GAME',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 2.0),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connecting...")),
      );
      try {
        await ref
            .read(authProvider)
            .signInAnonymously("Host_${DateTime.now().millisecond}");
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Auth Failed: $e")),
          );
        }
        return;
      }
    }
    try {
      String? uid = user?.uid ??
          (await ref
                  .read(authProvider)
                  .signInAnonymously("Host_${DateTime.now().millisecond}"))
              ?.uid;
      if (uid == null) throw Exception("Auth failed");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Creating room...")),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnlineFocused = _codeFocus.hasFocus;

    return Scaffold(
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
      body: GameTableBackground(
        child: SafeArea(
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
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGlow,
                                blurRadius: 40,
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'RANG',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8.0,
                                  color: AppTheme.accentPrimary,
                                  height: 1.0,
                                ),
                              ),
                              Container(
                                height: 2,
                                width: 140,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.accentPrimary,
                                      Colors.transparent,
                                      AppTheme.accentSecondary,
                                    ],
                                  ),
                                ),
                              ),
                              const Text(
                                'ADDA',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8.0,
                                  color: AppTheme.accentSecondary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "PAKISTAN'S CARD GAMES",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                          ref.read(currentGameIdProvider.notifier).setId(null);
                        }),
                        const SizedBox(height: 32),
                      ],

                      // Center: Join Online Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.accentPrimary.withOpacity(0.20),
                          ),
                          boxShadow: isOnlineFocused
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonGlow,
                                    blurRadius: 16,
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'JOIN ONLINE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _codeController,
                              focusNode: _codeFocus,
                              textAlign: TextAlign.center,
                              cursorColor: AppTheme.accentPrimary,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 4.0,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ROOM CODE',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.15),
                                  fontSize: 18,
                                  letterSpacing: 4.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.textDisabled,
                                  ),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.textDisabled,
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.accentPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildButton('JOIN GAME', () async {
                              final user = ref.read(userProvider).value;
                              if (user == null ||
                                  _codeController.text.isEmpty) {
                                return;
                              }
                              try {
                                await ref
                                    .read(firestoreServiceProvider)
                                    .joinWaitingRoom(
                                      _codeController.text,
                                      user.uid,
                                      user.displayName ?? "Player",
                                    );
                                ref
                                    .read(
                                        currentGameIdProvider.notifier,
                                    )
                                    .setId(_codeController.text);
                                if (mounted) {
                                  context.push(
                                    '/waiting_room/${_codeController.text}',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                    ),
                                  );
                                }
                              }
                            }, type: ButtonType.primary),
                            const SizedBox(height: 12),
                            _buildButton('HOST NEW GAME', _showHostGameDialog),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),

                      // Bottom: Local Games
                      const Text(
                        'LOCAL PLAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLocalButton(
                        'THULLA (3-7 PLAYERS)',
                        () => context.push('/setup/thulla'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLocalButton(
                              'BLUFF',
                              () => context.push('/setup/bluff'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLocalButton(
                              'RANG',
                              () => context.push('/setup/rang'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
