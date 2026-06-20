import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Game-type configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the player-count constraints and display name for a game type.
class _GameConfig {
  final String displayName;
  final int minPlayers;
  final int maxPlayers;

  const _GameConfig({
    required this.displayName,
    required this.minPlayers,
    required this.maxPlayers,
  });
}

const _configs = <String, _GameConfig>{
  'thulla': _GameConfig(displayName: 'Thulla', minPlayers: 3, maxPlayers: 7),
  'bluff': _GameConfig(displayName: 'Bluff', minPlayers: 4, maxPlayers: 4),
  'rang': _GameConfig(displayName: 'Rang', minPlayers: 4, maxPlayers: 4),
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// A pre-game "who's playing?" screen that collects player names before any
/// local game starts.
///
/// **Navigation contract**
/// Route: `/add_players/:gameType`
///
/// On "Start Game" the screen calls `context.pop(List<String> names)`.
/// The caller (lobby or any future entry-point) receives that list via the
/// value returned from `context.push(...)`.
///
/// ```dart
/// // In the caller:
/// final names = await context.push<List<String>>(
///   '/add_players/thulla',
/// );
/// if (names != null) ref.read(thullaProvider.notifier).startGame(names);
/// ```
class AddPlayersScreen extends ConsumerStatefulWidget {
  /// One of `'thulla'`, `'bluff'`, or `'rang'`.
  final String gameType;

  const AddPlayersScreen({super.key, required this.gameType});

  @override
  ConsumerState<AddPlayersScreen> createState() => _AddPlayersScreenState();
}

class _AddPlayersScreenState extends ConsumerState<AddPlayersScreen> {
  late final _GameConfig _config;

  /// One controller and one FocusNode per player slot.
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();

    _config = _configs[widget.gameType] ??
        const _GameConfig(
          displayName: 'Game',
          minPlayers: 2,
          maxPlayers: 8,
        );

    // Start at the minimum player count.
    for (int i = 0; i < _config.minPlayers; i++) {
      _addSlot();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Slot management ────────────────────────────────────────────────────────

  void _addSlot() {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    // Rebuild on every keystroke so validation updates live.
    controller.addListener(() => setState(() {}));
    _controllers.add(controller);
    _focusNodes.add(focusNode);
  }

  void _removeLastSlot() {
    if (_controllers.length <= _config.minPlayers) return;
    _controllers.last.dispose();
    _focusNodes.last.dispose();
    _controllers.removeLast();
    _focusNodes.removeLast();
    setState(() {});
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Trimmed names for every visible slot.
  List<String> get _trimmedNames =>
      _controllers.map((c) => c.text.trim()).toList();

  /// Returns the validation error string for the slot at [index], or null.
  String? _errorFor(int index) {
    final name = _controllers[index].text.trim();
    if (name.isEmpty) return null; // empty → no inline error, just disables button

    // Duplicate check: same trimmed name at any other slot.
    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) continue;
      if (_controllers[i].text.trim().toLowerCase() == name.toLowerCase()) {
        return 'Duplicate name';
      }
    }
    return null;
  }

  bool get _hasDuplicates {
    final names =
        _trimmedNames.where((n) => n.isNotEmpty).map((n) => n.toLowerCase());
    final set = <String>{};
    for (final name in names) {
      if (!set.add(name)) return true;
    }
    return false;
  }

  bool get _canStart {
    final count = _controllers.length;
    if (count < _config.minPlayers || count > _config.maxPlayers) return false;
    if (_trimmedNames.any((n) => n.isEmpty)) return false;
    if (_hasDuplicates) return false;
    return true;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onStartGame() {
    if (!_canStart) return;
    final names = _trimmedNames;

    switch (widget.gameType) {
      case 'thulla':
        context.go('/thulla', extra: names);

      case 'bluff':
        context.go('/table/bluff', extra: names);

      case 'rang':
        context.go('/rang_table', extra: names);

      default:
        // Unknown game type — pop back to lobby.
        context.pop();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _suitIconByGame = <String, IconData>{
    'thulla': Icons.bolt,
    'bluff': Icons.visibility_off_rounded,
    'rang': Icons.style,
  };

  static const _subtitleByGame = <String, String>{
    'thulla': '3 – 7 players',
    'bluff': 'Exactly 4 players',
    'rang': 'Exactly 4 players',
  };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _controllers.length;
    final canAdd = count < _config.maxPlayers;
    final canRemove = count > _config.minPlayers;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          _config.displayName.toUpperCase(),
          style: const TextStyle(letterSpacing: 4.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _suitIconByGame[widget.gameType] ?? Icons.casino_rounded,
                      color: AppTheme.accentPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Who's playing?",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleByGame[widget.gameType] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(
              color: Colors.white.withValues(alpha: 0.06),
              thickness: 1,
              indent: 24,
              endIndent: 24,
            ),
            const SizedBox(height: 4),

            // ── Player slots ─────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: count,
                itemBuilder: (context, index) {
                  final isLast = index == count - 1;
                  final errorText = _errorFor(index);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label row
                          Row(
                            children: [
                              // Numbered badge
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _controllers[index]
                                            .text
                                            .trim()
                                            .isNotEmpty
                                        ? AppTheme.accentPrimary
                                            .withValues(alpha: 0.6)
                                        : Colors.white
                                            .withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _controllers[index]
                                              .text
                                              .trim()
                                              .isNotEmpty
                                          ? AppTheme.accentPrimary
                                          : AppTheme.textDisabled,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Player ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (canRemove && isLast) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: _removeLastSlot,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusError
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.statusError
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.remove_rounded,
                                          size: 14,
                                          color: AppTheme.statusError,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Remove',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.statusError,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Text field
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _controllers[index]
                                      .text
                                      .trim()
                                      .isNotEmpty
                                  ? [
                                      BoxShadow(
                                        color: errorText != null
                                            ? AppTheme.statusError
                                                .withValues(alpha: 0.12)
                                            : AppTheme.accentPrimary
                                                .withValues(alpha: 0.10),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: TextField(
                              key: ValueKey('player_name_field_$index'),
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textCapitalization: TextCapitalization.words,
                              textInputAction: (index < count - 1)
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onSubmitted: (_) {
                                if (index < count - 1) {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNodes[index + 1]);
                                } else {
                                  _onStartGame();
                                }
                              },
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Player ${index + 1} name',
                                hintStyle: const TextStyle(
                                  color: AppTheme.textDisabled,
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: AppTheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: errorText != null
                                        ? AppTheme.statusError
                                        : AppTheme.accentPrimary,
                                    width: 1.5,
                                  ),
                                ),
                                suffixIcon: _controllers[index]
                                        .text
                                        .trim()
                                        .isNotEmpty
                                    ? Icon(
                                        errorText != null
                                            ? Icons.error_outline_rounded
                                            : Icons.check_circle_outline_rounded,
                                        color: errorText != null
                                            ? AppTheme.statusError
                                            : AppTheme.statusSuccess,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // Inline duplicate error
                          if (errorText != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: AppTheme.statusError,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    errorText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.statusError,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Footer: Add Player + Start ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "+ Add Player" button — hidden once max reached.
                  if (canAdd)
                    GestureDetector(
                      onTap: () {
                        setState(() => _addSlot());
                        // Auto-focus the new field after the frame settles.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_focusNodes.isNotEmpty) {
                            FocusScope.of(context)
                                .requestFocus(_focusNodes.last);
                          }
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                AppTheme.accentPrimary.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color:
                                  AppTheme.accentPrimary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+ Add Player',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentPrimary
                                    .withValues(alpha: 0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // "Start Game" primary CTA.
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _canStart ? 1.0 : 0.45,
                      child: ElevatedButton(
                        key: const ValueKey('start_game_button'),
                        onPressed: _canStart ? _onStartGame : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.accentPrimary.withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white54,
                          elevation: _canStart ? 4 : 0,
                          shadowColor:
                              AppTheme.accentPrimary.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'START GAME',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


