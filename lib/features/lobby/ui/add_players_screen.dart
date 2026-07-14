import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/features/rang/state/rang_provider.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/utils/player_session_storage.dart';

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

const _thematicNames = ["Asad", "Marbo", "Jatt", "Gujjar", "Pinky", "Butt"];

// ─────────────────────────────────────────────────────────────────────────────
// Game difficulty — the three options shown to the player
// ─────────────────────────────────────────────────────────────────────────────

/// The three difficulty tiers exposed in the UI.
/// Each maps to an internal [BotDifficulty].
enum _GameDifficulty { easy, medium, hard }

extension _GameDifficultyX on _GameDifficulty {
  /// Display label shown on the segmented button.
  String get label {
    switch (this) {
      case _GameDifficulty.easy:
        return 'EASY';
      case _GameDifficulty.medium:
        return 'MEDIUM';
      case _GameDifficulty.hard:
        return 'HARD';
    }
  }

  /// Short subtitle shown beneath the label.
  String get subtitle {
    switch (this) {
      case _GameDifficulty.easy:
        return 'Simple logic';
      case _GameDifficulty.medium:
        return 'Thinks ahead';
      case _GameDifficulty.hard:
        return 'Mobile only';
    }
  }

  /// The internal [BotDifficulty] this tier maps to.
  BotDifficulty get botDifficulty {
    switch (this) {
      case _GameDifficulty.easy:
        return BotDifficulty.medium; // rule-based smallest-card strategy
      case _GameDifficulty.medium:
        return BotDifficulty.expert; // PIMC — perfect information Monte Carlo
      case _GameDifficulty.hard:
        return BotDifficulty.expert; // placeholder — disabled in UI
    }
  }

  /// Whether this option can be selected on the current platform.
  bool get isEnabled => this != _GameDifficulty.hard;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerSlot {
  final TextEditingController controller;
  final FocusNode focusNode;
  bool isBot;

  _PlayerSlot()
    : controller = TextEditingController(),
      focusNode = FocusNode(),
      isBot = false;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class AddPlayersScreen extends ConsumerStatefulWidget {
  /// One of `'thulla'`, `'bluff'`, or `'rang'`.
  final String gameType;

  const AddPlayersScreen({super.key, required this.gameType});

  @override
  ConsumerState<AddPlayersScreen> createState() => _AddPlayersScreenState();
}

class _AddPlayersScreenState extends ConsumerState<AddPlayersScreen> {
  late final _GameConfig _config;

  final List<_PlayerSlot> _slots = [];
  final Random _rand = Random();

  /// Single game-level difficulty shared by all bots.
  _GameDifficulty _gameDifficulty = _GameDifficulty.medium;

  @override
  void initState() {
    super.initState();

    _config =
        _configs[widget.gameType] ??
        const _GameConfig(displayName: 'Game', minPlayers: 2, maxPlayers: 8);

    // Start at the minimum player count.
    for (int i = 0; i < _config.minPlayers; i++) {
      _addSlot(isBot: i > 0); // Default first slot human, others bot
    }
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.dispose();
    }
    super.dispose();
  }

  // ── Slot management ────────────────────────────────────────────────────────

  void _addSlot({bool isBot = false}) {
    final slot = _PlayerSlot();
    slot.isBot = isBot;

    if (isBot) {
      slot.controller.text = _getUnusedBotName();
    }

    slot.controller.addListener(() => setState(() {}));
    slot.focusNode.addListener(() {
      setState(() {});
    });

    _slots.add(slot);
  }

  String _getUnusedBotName() {
    final usedNames = _trimmedNames.map((n) => n.toLowerCase()).toSet();
    final available = _thematicNames
        .where((n) => !usedNames.contains(n.toLowerCase()))
        .toList();
    if (available.isEmpty) {
      return "${_thematicNames[_rand.nextInt(_thematicNames.length)]} ${_rand.nextInt(100)}";
    }
    return available[_rand.nextInt(available.length)];
  }

  void _removeSlotAt(int index) {
    if (_slots.length <= _config.minPlayers) return;
    _slots[index].dispose();
    _slots.removeAt(index);
    setState(() {});
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  List<String> get _trimmedNames =>
      _slots.map((s) => s.controller.text.trim()).toList();

  String? _errorFor(int index) {
    final name = _slots[index].controller.text.trim();
    if (name.isEmpty) return null;

    for (int i = 0; i < _slots.length; i++) {
      if (i == index) continue;
      if (_slots[i].controller.text.trim().toLowerCase() ==
          name.toLowerCase()) {
        return 'Duplicate';
      }
    }
    return null;
  }

  bool get _hasDuplicates {
    final names = _trimmedNames
        .where((n) => n.isNotEmpty)
        .map((n) => n.toLowerCase());
    final set = <String>{};
    for (final name in names) {
      if (!set.add(name)) return true;
    }
    return false;
  }

  bool get _canStart {
    final count = _slots.length;
    if (count < _config.minPlayers || count > _config.maxPlayers) return false;
    if (_trimmedNames.any((n) => n.isEmpty)) return false;
    if (_hasDuplicates) return false;

    // At least one human player
    if (!_slots.any((s) => !s.isBot)) return false;

    return true;
  }

  bool get _hasAnyBot => _slots.any((s) => s.isBot);

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onStartGame() {
    if (!_canStart) return;

    final assignedDifficulty = _gameDifficulty.botDifficulty;

    final players = List.generate(_slots.length, (i) {
      final slot = _slots[i];
      return Player(
        id: 'p${i + 1}',
        name: slot.controller.text.trim(),
        isBot: slot.isBot,
        botDifficulty: slot.isBot ? assignedDifficulty : null,
      );
    });

    saveGameSession(widget.gameType, players);

    switch (widget.gameType) {
      case 'thulla':
        context.go('/thulla', extra: players);
      case 'bluff':
        context.go('/table/bluff', extra: players);
      case 'rang':
        ref.read(rangProvider.notifier).startGame(players);
        context.go('/rang_table', extra: players);
      default:
        context.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final count = _slots.length;
    final canAdd = count < _config.maxPlayers;
    final canRemove = count > _config.minPlayers;

    final gameTypeLabel =
        '${_config.displayName.toUpperCase()} — ${_config.maxPlayers == _config.minPlayers ? _config.maxPlayers : '${_config.minPlayers}-${_config.maxPlayers}'} PLAYERS';

    final playerFields = List.generate(count, (index) {
      final slot = _slots[index];
      final errorText = _errorFor(index);
      final hasFocus = slot.focusNode.hasFocus;

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'P${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: hasFocus
                        ? AppTheme.accentPrimary
                        : AppTheme.textDisabled,
                  ),
                ),
                const SizedBox(width: 12),
                // Bot Toggle
                ChoiceChip(
                  label: Text(
                    slot.isBot ? 'BOT' : 'HUMAN',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: slot.isBot,
                  selectedColor: AppTheme.accentSecondary,
                  backgroundColor: AppTheme.surfaceElevated,
                  onSelected: (val) {
                    setState(() {
                      slot.isBot = val;
                      if (val) {
                        if (slot.controller.text.isEmpty ||
                            !_thematicNames.contains(slot.controller.text)) {
                          slot.controller.text = _getUnusedBotName();
                        }
                      }
                    });
                  },
                ),
                const Spacer(),
                if (canRemove)
                  GestureDetector(
                    onTap: () => _removeSlotAt(index),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.statusError.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: AppTheme.neonGlow,
                          blurRadius: 16,
                          spreadRadius: -8,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                key: ValueKey('player_name_field_$index'),
                controller: slot.controller,
                focusNode: slot.focusNode,
                textCapitalization: TextCapitalization.words,
                textInputAction: (index < count - 1)
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: (_) {
                  if (index < count - 1) {
                    FocusScope.of(
                      context,
                    ).requestFocus(_slots[index + 1].focusNode);
                  } else {
                    _onStartGame();
                  }
                },
                cursorColor: AppTheme.accentPrimary,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: AppTheme.accentPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'PLAYER NAME',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    fontSize: 16,
                    letterSpacing: 2.0,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.textDisabled,
                      width: 1,
                    ),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.textDisabled,
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: errorText != null
                          ? AppTheme.statusError
                          : AppTheme.accentPrimary,
                      width: 2,
                    ),
                  ),
                  suffixIcon: errorText != null
                      ? const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.statusError,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.statusError,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
          ],
        ),
      );
    });

    final addRemoveButtons = [
      if (canAdd)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _addSlot(isBot: false));
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_slots.isNotEmpty) {
                        FocusScope.of(
                          context,
                        ).requestFocus(_slots.last.focusNode);
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppTheme.accentPrimary,
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '+ HUMAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPrimary,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _addSlot(isBot: true));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppTheme.accentSecondary,
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '+ BOT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentSecondary,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    ];

    final startGameButton = Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        boxShadow: _canStart
            ? [
                BoxShadow(
                  color: AppTheme.neonGlow,
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        key: const ValueKey('start_game_button'),
        onPressed: _canStart ? _onStartGame : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentPrimary,
          foregroundColor: AppTheme.backgroundPrimary,
          disabledBackgroundColor: AppTheme.accentPrimary.withValues(
            alpha: 0.3,
          ),
          disabledForegroundColor: AppTheme.backgroundPrimary.withValues(
            alpha: 0.5,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'START GAME',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Stack(
        children: [
          const GameTableBackground(child: SizedBox.shrink()),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppTheme.textSecondary,
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'WHO\'S PLAYING',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                      ),
                    ),
                    Text(
                      gameTypeLabel,
                      style: const TextStyle(
                        color: AppTheme.accentSecondary,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 28),

                    ...playerFields,
                    const SizedBox(height: 12),
                    ...addRemoveButtons,

                    // ── Bot difficulty selector ───────────────────────────────
                    if (_hasAnyBot) ...[
                      const SizedBox(height: 28),
                      _BotDifficultySelector(
                        selected: _gameDifficulty,
                        onChanged: (d) => setState(() => _gameDifficulty = d),
                      ),
                    ],

                    const SizedBox(height: 32),
                    startGameButton,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bot difficulty selector widget
// ─────────────────────────────────────────────────────────────────────────────

class _BotDifficultySelector extends StatelessWidget {
  final _GameDifficulty selected;
  final ValueChanged<_GameDifficulty> onChanged;

  const _BotDifficultySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.psychology_rounded,
              size: 14,
              color: AppTheme.accentSecondary,
            ),
            const SizedBox(width: 6),
            const Text(
              'BOT DIFFICULTY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: AppTheme.accentSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _GameDifficulty.values.map((tier) {
            final isSelected = selected == tier;
            final isDisabled = !tier.isEnabled;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: tier != _GameDifficulty.hard ? 8 : 0,
                ),
                child: _DifficultyTile(
                  tier: tier,
                  isSelected: isSelected,
                  isDisabled: isDisabled,
                  onTap: isDisabled ? null : () => onChanged(tier),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final _GameDifficulty tier;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _DifficultyTile({
    required this.tier,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  Color get _borderColor {
    if (isDisabled) return AppTheme.textDisabled.withValues(alpha: 0.2);
    if (isSelected) return _accentColor;
    return AppTheme.textDisabled.withValues(alpha: 0.3);
  }

  Color get _accentColor {
    switch (tier) {
      case _GameDifficulty.easy:
        return const Color(0xFF4ADE80); // green
      case _GameDifficulty.medium:
        return AppTheme.accentPrimary; // gold
      case _GameDifficulty.hard:
        return AppTheme.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = isDisabled ? 0.35 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _accentColor.withValues(alpha: 0.12)
                : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: isSelected ? 1.5 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tier.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: isSelected ? _accentColor : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tier.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? _accentColor.withValues(alpha: 0.7)
                      : AppTheme.textDisabled,
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textDisabled.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SOON',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppTheme.textDisabled,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
