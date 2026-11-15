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
  });

  final GamePhase phase;
  final List<String> guests;
  final Set<int> completedLetters;
  final int currentLevelIndex;
  final String? selectedGuest;
  final String? lastFeedback;

  GameSnapshot copyWith({
    GamePhase? phase,
    List<String>? guests,
    Set<int>? completedLetters,
    int? currentLevelIndex,
    String? selectedGuest,
    String? lastFeedback,
    bool clearSelectedGuest = false,
    bool clearFeedback = false,
  }) {
    return GameSnapshot(
      phase: phase ?? this.phase,
      guests: guests ?? this.guests,
      completedLetters: completedLetters ?? this.completedLetters,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      selectedGuest:
          clearSelectedGuest ? null : (selectedGuest ?? this.selectedGuest),
      lastFeedback: clearFeedback ? null : (lastFeedback ?? this.lastFeedback),
    );
  }
}
