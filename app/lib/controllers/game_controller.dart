import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/level.dart';
import '../services/voice_service.dart';
import '../wheel/fair_queue.dart';

class GameController extends ChangeNotifier {
  GameController({VoiceService? voice, FairQueue? queue})
      : _voice = voice ?? VoiceService(),
        _queue = queue ?? FairQueue();

  final VoiceService _voice;
  final FairQueue _queue;

  LevelsPack? _pack;
  GameSnapshot _snapshot = const GameSnapshot(
    phase: GamePhase.splash,
    guests: [],
    completedLetters: {},
    currentLevelIndex: 0,
    selectedGuest: null,
    lastFeedback: null,
  );

  /// Names currently drawn on the wheel (may shrink as people are picked).
  List<String> wheelNames = const [];

  GameSnapshot get snapshot => _snapshot;
  LevelsPack? get pack => _pack;
  VoiceService get voice => _voice;
  FairQueue get queue => _queue;

  LevelDefinition? get currentLevel {
    final pack = _pack;
    if (pack == null) return null;
    if (_snapshot.currentLevelIndex < 0 ||
        _snapshot.currentLevelIndex >= pack.levels.length) {
      return null;
    }
    return pack.levels[_snapshot.currentLevelIndex];
  }

  bool get hasMoreDemoLevels {
    final pack = _pack;
    if (pack == null) return false;
    return _snapshot.currentLevelIndex < pack.levels.length;
  }

  Future<void> loadDemoPack() async {
    final raw = await rootBundle.loadString('assets/levels/demo.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _pack = LevelsPack.fromJson(json);
    _voice.configure(_pack!.voiceLines);
    notifyListeners();
  }

  void goToLobby() {
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.lobby,
      clearFeedback: true,
      clearSelectedGuest: true,
    );
    notifyListeners();
  }

  void addGuest(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_snapshot.guests.any((g) => g.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final next = [..._snapshot.guests, trimmed];
    _queue.setGuests(next);
    _snapshot = _snapshot.copyWith(guests: next);
    notifyListeners();
  }

  void removeGuest(String name) {
    final next = _snapshot.guests.where((g) => g != name).toList();
    _queue.setGuests(next);
    _snapshot = _snapshot.copyWith(guests: next);
    notifyListeners();
  }

  void startGame() {
    if (_snapshot.guests.length < 2) return;
    _queue.setGuests(_snapshot.guests);
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.progress,
      currentLevelIndex: 0,
      completedLetters: {},
      clearSelectedGuest: true,
      clearFeedback: true,
    );
    notifyListeners();
  }

  Future<void> continueFromProgress() async {
    if (!hasMoreDemoLevels) {
      _snapshot = _snapshot.copyWith(phase: GamePhase.demoDone);
      notifyListeners();
      await _voice.playKey('victory');
      return;
    }
    wheelNames = _queue.peekWheelNames();
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.wheel,
      clearSelectedGuest: true,
      clearFeedback: true,
    );
    notifyListeners();
  }

  /// Prepares spin: locks wheel names and returns winner + index for animation.
  Future<({String winner, int index})> prepareSpin() async {
    await _voice.playKey('spin');
    wheelNames = _queue.peekWheelNames();
    final winner = _queue.next();
    final index = wheelNames.indexOf(winner).clamp(0, wheelNames.length - 1);
    notifyListeners();
    return (winner: winner, index: index);
  }

  void finishSpin(String winner) {
    _snapshot = _snapshot.copyWith(selectedGuest: winner);
    notifyListeners();
  }

  void openLevel() {
    _snapshot = _snapshot.copyWith(phase: GamePhase.level, clearFeedback: true);
    notifyListeners();
    final level = currentLevel;
    if (level != null) {
      _voice.playKey('start', local: level.voiceLines);
      if (!level.voiceLines.containsKey('start')) {
        _voice.playKey('level_start');
      }
    }
  }

  Future<bool> submitAnswer(String answer) async {
    final level = currentLevel;
    if (level == null) return false;
    final ok = level.matchesAnswer(answer);
    if (ok) {
      final completed = {..._snapshot.completedLetters, level.letterIndex};
      _snapshot = _snapshot.copyWith(
        completedLetters: completed,
        lastFeedback: 'Верно!',
      );
      notifyListeners();
      await _voice.playKey('correct');
    } else {
      _snapshot = _snapshot.copyWith(lastFeedback: 'Неверно, попробуйте ещё');
      notifyListeners();
      await _voice.playKey('wrong');
    }
    return ok;
  }

  void advanceAfterCorrect() {
    final nextIndex = _snapshot.currentLevelIndex + 1;
    final pack = _pack;
    if (pack == null || nextIndex >= pack.levels.length) {
      _snapshot = _snapshot.copyWith(
        phase: GamePhase.demoDone,
        currentLevelIndex: nextIndex,
        clearSelectedGuest: true,
        clearFeedback: true,
      );
      notifyListeners();
      _voice.playKey('victory');
      return;
    }
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.progress,
      currentLevelIndex: nextIndex,
      clearSelectedGuest: true,
      clearFeedback: true,
    );
    notifyListeners();
  }

  void restart() {
    _snapshot = const GameSnapshot(
      phase: GamePhase.lobby,
      guests: [],
      completedLetters: {},
      currentLevelIndex: 0,
      selectedGuest: null,
      lastFeedback: null,
    );
    wheelNames = const [];
    _queue.setGuests(const []);
    notifyListeners();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }
}
