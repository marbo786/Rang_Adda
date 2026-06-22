import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/features/rang/state/rang_provider.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';

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

class AddPlayersScreen extends ConsumerStatefulWidget {
  /// One of `'thulla'`, `'bluff'`, or `'rang'`.
  final String gameType;

  const AddPlayersScreen({super.key, required this.gameType});

  @override
  ConsumerState<AddPlayersScreen> createState() => _AddPlayersScreenState();
}

class _AddPlayersScreenState extends ConsumerState<AddPlayersScreen> {
  late final _GameConfig _config;

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
    controller.addListener(() => setState(() {}));
    _focusNodes.add(focusNode);
    // Also trigger rebuild on focus change for the glow effect
    focusNode.addListener(() {
      setState(() {});
    });
    _controllers.add(controller);
  }

  void _removeLastSlot() {
    if (_controllers.length <= _config.minPlayers) return;
    _controllers.last.dispose();
    _focusNodes.last.dispose();
    _controllers.removeLast();
    _focusNodes.removeLast();
    setState(() {});
  }

  void _removeSlotAt(int index) {
    if (_controllers.length <= _config.minPlayers) return;
    _controllers[index].dispose();
    _focusNodes[index].dispose();
    _controllers.removeAt(index);
    _focusNodes.removeAt(index);
    setState(() {});
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  List<String> get _trimmedNames =>
      _controllers.map((c) => c.text.trim()).toList();

  String? _errorFor(int index) {
    final name = _controllers[index].text.trim();
    if (name.isEmpty) return null;

    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) continue;
      if (_controllers[i].text.trim().toLowerCase() == name.toLowerCase()) {
        return 'Duplicate';
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
        ref.read(rangProvider.notifier).startGame(names);
        context.go('/rang_table', extra: names);
      default:
        context.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final count = _controllers.length;
    final canAdd = count < _config.maxPlayers;
    final canRemove = count > _config.minPlayers;

    final gameTypeLabel = '${_config.displayName.toUpperCase()} — ${_config.maxPlayers == _config.minPlayers ? _config.maxPlayers : '${_config.minPlayers}-${_config.maxPlayers}'} PLAYERS';

    final playerFields = List.generate(count, (index) {
      final errorText = _errorFor(index);
      final hasFocus = _focusNodes[index].hasFocus;

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
                    color: hasFocus ? AppTheme.accentPrimary : AppTheme.textDisabled,
                  ),
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
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: AppTheme.neonGlow,
                          blurRadius: 16,
                          spreadRadius: -8,
                          offset: const Offset(0, 8),
                        )
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
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
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
                    borderSide: BorderSide(color: AppTheme.textDisabled, width: 1),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.textDisabled, width: 1),
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
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              setState(() => _addSlot());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_focusNodes.isNotEmpty) {
                  FocusScope.of(context).requestFocus(_focusNodes.last);
                }
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.accentPrimary, width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ADD PLAYER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentPrimary,
                letterSpacing: 2.0,
              ),
            ),
          ),
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
          disabledBackgroundColor: AppTheme.accentPrimary.withValues(alpha: 0.3),
          disabledForegroundColor: AppTheme.backgroundPrimary.withValues(alpha: 0.5),
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

                    const Text('WHO\'S PLAYING',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                      ),
                    ),
                    Text(gameTypeLabel,
                      style: const TextStyle(color: AppTheme.accentSecondary, fontSize: 12, letterSpacing: 2),
                    ),
                    const SizedBox(height: 28),

                    ...playerFields,
                    const SizedBox(height: 12),
                    ...addRemoveButtons,
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


