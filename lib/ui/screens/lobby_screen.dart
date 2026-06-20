import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';
import '../../state/online_thulla_provider.dart';
import '../theme.dart';
import '../widgets/game_table_background.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppTheme.accentPrimary
              : Colors.transparent,
          foregroundColor: isPrimary
              ? Colors.white
              : AppTheme.accentPrimary,
          elevation: isPrimary ? 8 : 0,
          shadowColor:
              isPrimary ? AppTheme.accentPrimary.withValues(alpha: 0.4) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.5),
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
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
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
                      // Top: Logo Area with Gradient
                      Center(
                        child: Column(
                          children: [
                            // Gradient icon
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    AppTheme.accentPrimary,
                                    AppTheme.accentSecondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Icon(
                                Icons.style,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Title with gradient
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    AppTheme.accentPrimary,
                                    AppTheme.accentSecondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'RANG ADDA',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Choose your game',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),

                      // Center: Join Online Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPrimary
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'JOIN ONLINE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: AppTheme.accentPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _codeController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 6.0,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ROOM CODE',
                                hintStyle: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  fontSize: 18,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: AppTheme.backgroundPrimary,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.07),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.accentPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildButton('JOIN GAME', isPrimary: true, () async {
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
                            }),
                            const SizedBox(height: 12),
                            _buildButton('HOST NEW GAME', () async {
                              final user = ref.read(userProvider).value;
                              if (user == null) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text("Connecting...")),
                                );
                                try {
                                  await ref
                                      .read(authProvider)
                                      .signInAnonymously(
                                        "Host_${DateTime.now().millisecond}",
                                      );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content:
                                              Text("Auth Failed: $e")),
                                    );
                                  }
                                  return;
                                }
                              }
                              try {
                                String? uid = user?.uid ??
                                    (await ref
                                            .read(authProvider)
                                            .signInAnonymously(
                                              "Host_${DateTime.now().millisecond}",
                                            ))
                                        ?.uid;
                                if (uid == null) {
                                  throw Exception("Auth failed");
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text("Creating room..."),
                                    ),
                                  );
                                }
                                final gameId = await ref
                                    .read(firestoreServiceProvider)
                                    .createWaitingRoom(
                                      uid,
                                      user?.displayName ?? "Host",
                                    )
                                    .timeout(
                                        const Duration(seconds: 5));
                                ref
                                    .read(
                                        currentGameIdProvider.notifier,
                                    )
                                    .setId(gameId);
                                if (mounted) {
                                  context.push('/waiting_room/$gameId');
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                        content: Text("Error: $e")),
                                  );
                                }
                              }
                            }),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),

                      // Bottom: Local Games
                      Text(
                        'LOCAL PLAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildButton(
                        'THULLA (3-7 PLAYERS)',
                        () => context.push('/setup/thulla'),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildButton(
                              'BLUFF',
                              () => context.push('/setup/bluff'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildButton(
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
