import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/phrase.dart';
import '../theme/app_theme.dart';

class LetterProgressView extends StatelessWidget {
  const LetterProgressView({
    super.key,
    required this.completedLetters,
    this.currentLetterIndex,
    this.celebrateLetter,
    this.celebration,
    this.showArrow = true,
    this.compact = false,
  });

  final Set<int> completedLetters;
  final int? currentLetterIndex;

  /// Letter that just lit — pulses / sparks while [celebration] runs.
  final int? celebrateLetter;
  final Animation<double>? celebration;
  final bool showArrow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final grid = PhraseLayout.letterIndexGrid;
    final fontSize = compact ? 18.0 : 28.0;
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var line = 0; line < grid.length; line++) ...[
          _PhraseLine(
            chars: PhraseLayout.lines[line].split(''),
            indices: grid[line],
            completedLetters: completedLetters,
            currentLetterIndex: currentLetterIndex,
            celebrateLetter: celebrateLetter,
            celebration: celebration,
            showArrow: showArrow,
            fontSize: fontSize,
          ),
          SizedBox(height: compact ? 8 : 16),
        ],
      ],
    );
    if (celebration == null || celebrateLetter == null) return child;
    return AnimatedBuilder(animation: celebration!, builder: (_, _) => child);
  }
}

class _PhraseLine extends StatelessWidget {
  const _PhraseLine({
    required this.chars,
    required this.indices,
    required this.completedLetters,
    required this.currentLetterIndex,
    required this.celebrateLetter,
    required this.celebration,
    required this.showArrow,
    required this.fontSize,
  });

  final List<String> chars;
  final List<int?> indices;
  final Set<int> completedLetters;
  final int? currentLetterIndex;
  final int? celebrateLetter;
  final Animation<double>? celebration;
  final bool showArrow;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < chars.length; i++)
          _LetterCell(
            char: chars[i],
            letterIndex: indices[i],
            completed:
                indices[i] != null && completedLetters.contains(indices[i]),
            isCurrent:
                indices[i] != null && indices[i] == currentLetterIndex,
            celebrating:
                indices[i] != null && indices[i] == celebrateLetter,
            celebration: celebration,
            showArrow: showArrow,
            fontSize: fontSize,
          ),
      ],
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.char,
    required this.letterIndex,
    required this.completed,
    required this.isCurrent,
    required this.celebrating,
    required this.celebration,
    required this.showArrow,
    required this.fontSize,
  });

  final String char;
  final int? letterIndex;
  final bool completed;
  final bool isCurrent;
  final bool celebrating;
  final Animation<double>? celebration;
  final bool showArrow;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDecoration = letterIndex == null;
    final t = celebrating ? (celebration?.value ?? 1.0) : 1.0;
    Color color;
    if (isDecoration) {
      color = PoliColors.steel;
    } else if (celebrating) {
      // Flash from dim → bright mint/gold.
      color = Color.lerp(
            PoliColors.dimLetter,
            PoliColors.amberYellow,
            Curves.easeOut.transform(t.clamp(0.0, 1.0)),
          ) ??
          PoliColors.litLetter;
    } else if (completed) {
      color = PoliColors.litLetter;
    } else if (isCurrent) {
      color = PoliColors.robocarRed;
    } else {
      color = PoliColors.dimLetter;
    }

    final scale = celebrating ? 1.0 + 0.28 * math.sin(t * math.pi) : 1.0;

    return SizedBox(
      width: fontSize + 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: fontSize * 0.7,
            child: showArrow && isCurrent && !celebrating
                ? const Icon(
                    Icons.arrow_downward,
                    color: PoliColors.robocarRed,
                    size: 22,
                  )
                : celebrating
                    ? Opacity(
                        opacity: (1.0 - t).clamp(0.0, 1.0),
                        child: Icon(
                          Icons.auto_awesome,
                          color: PoliColors.amberYellow,
                          size: 18 + 6 * t,
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          Transform.scale(
            scale: scale,
            child: Text(
              char,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: fontSize,
                color: color,
                height: 1.2,
                shadows: completed || isCurrent || celebrating
                    ? [
                        Shadow(
                          color: color.withValues(alpha: 0.55 + 0.35 * t),
                          blurRadius: 10 + 12 * t,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
