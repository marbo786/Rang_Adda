import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../state/online_thulla_provider.dart';

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
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          foregroundColor: isPrimary
              ? Colors.white
              : Theme.of(context).primaryColor,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                      child: Column(
                        children: [
                          Icon(
                            Icons.style,
                            size: 64,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'RANG ADDA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose your game',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),

                    // Center: Join Online
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'JOIN ONLINE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _codeController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              letterSpacing: 4.0,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ROOM CODE',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 16,
                                letterSpacing: 2.0,
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildButton('JOIN GAME', isPrimary: true, () async {
                            final user = ref.read(userProvider).value;
                            if (user == null || _codeController.text.isEmpty) {
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
                                  .read(currentGameIdProvider.notifier)
                                  .setId(_codeController.text);
                              if (mounted) {
                                context.push(
                                  '/waiting_room/${_codeController.text}',
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }),
                          const SizedBox(height: 8),
                          _buildButton('HOST NEW GAME', () async {
                            final user = ref.read(userProvider).value;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Connecting...")),
                              );
                              try {
                                await ref
                                    .read(authProvider)
                                    .signInAnonymously(
                                      "Host_${DateTime.now().millisecond}",
                                    );
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
                              String? uid =
                                  user?.uid ??
                                  (await ref
                                          .read(authProvider)
                                          .signInAnonymously(
                                            "Host_${DateTime.now().millisecond}",
                                          ))
                                      ?.uid;
                              if (uid == null) throw Exception("Auth failed");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                  .timeout(const Duration(seconds: 5));
                              ref
                                  .read(currentGameIdProvider.notifier)
                                  .setId(gameId);
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
                          }),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),

                    // Bottom: Local Games
                    const Center(
                      child: Text(
                        'LOCAL PLAY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      'Play Thulla (Pass & Play)',
                      () => context.push('/setup/thulla'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildButton(
                            'Play Bluff',
                            () => context.push('/setup/bluff'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildButton(
                            'Play Rang',
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
    );
  }
}
