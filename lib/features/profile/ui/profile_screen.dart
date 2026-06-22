import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/features/profile/state/user_profile_provider.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "PLAYER PROFILE",
          style: TextStyle(
            color: AppTheme.accentSecondary,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            shadows: [
              Shadow(
                color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                blurRadius: 12,
              )
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: GameTableBackground(
        child: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text("Profile not found.", style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentPrimary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonGlow,
                          blurRadius: 24,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 60, color: AppTheme.accentPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  profile.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Joined ${profile.createdAt.toLocal().toString().split(' ')[0]}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 64),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _StatCard(title: "WINS", value: profile.wins.toString(), color: AppTheme.statusSuccess)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(title: "LOSSES", value: profile.losses.toString(), color: AppTheme.statusError)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(
                      title: "WIN RATE",
                      value: "${profile.winRate.toStringAsFixed(1)}%",
                      color: AppTheme.accentSecondary,
                    )),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppTheme.statusError))),
      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -4,
          )
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(18.5),
        ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
