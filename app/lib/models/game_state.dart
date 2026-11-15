enum GamePhase {
  splash,
  lobby,
  progress,
  wheel,
  level,
  demoDone,
}

class GameSnapshot {
  const GameSnapshot({
    required this.phase,
    required this.guests,
    required this.completedLetters,
    required this.currentLevelIndex,
    required this.selectedGuest,
    required this.lastFeedback,
    this.lastPlayer,
    this.justLitLetter,
  });

  final GamePhase phase;
  final List<String> guests;
  final Set<int> completedLetters;
  final int currentLevelIndex;
  final String? selectedGuest;
  final String? lastFeedback;

  /// Guest who just finished a level (shown on progress reactions).
  final String? lastPlayer;

  /// Letter that should play the light-up ritual on the progress board.
  final int? justLitLetter;

  GameSnapshot copyWith({
    GamePhase? phase,
    List<String>? guests,
    Set<int>? completedLetters,
    int? currentLevelIndex,
    String? selectedGuest,
    String? lastFeedback,
    String? lastPlayer,
    int? justLitLetter,
    bool clearSelectedGuest = false,
    bool clearFeedback = false,
    bool clearLastPlayer = false,
    bool clearJustLitLetter = false,
  }) {
    return GameSnapshot(
      phase: phase ?? this.phase,
      guests: guests ?? this.guests,
      completedLetters: completedLetters ?? this.completedLetters,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      selectedGuest:
          clearSelectedGuest ? null : (selectedGuest ?? this.selectedGuest),
      lastFeedback: clearFeedback ? null : (lastFeedback ?? this.lastFeedback),
      lastPlayer: clearLastPlayer ? null : (lastPlayer ?? this.lastPlayer),
      justLitLetter:
          clearJustLitLetter ? null : (justLitLetter ?? this.justLitLetter),
    );
  }
}
