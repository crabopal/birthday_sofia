import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/level.dart';
import '../models/phrase.dart';
import '../models/robocar_character.dart';
import '../services/level_pack_store.dart';
import '../services/music_service.dart';
import '../services/voice_service.dart';
import '../wheel/fair_queue.dart';

class GameController extends ChangeNotifier {
  GameController({
    VoiceService? voice,
    FairQueue? queue,
    LevelPackStore? store,
    MusicService? music,
  })  : store = store ?? LevelPackStore(),
        _queue = queue ?? FairQueue(),
        music = music ?? MusicService() {
    _voice = voice ??
        VoiceService(
          store: this.store,
          music: this.music,
        );
  }

  late final VoiceService _voice;
  final FairQueue _queue;
  final LevelPackStore store;
  final MusicService music;

  LevelsPack? _pack;
  GameSnapshot _snapshot = const GameSnapshot(
    phase: GamePhase.splash,
    guests: [],
    completedLetters: {},
    currentLevelIndex: 0,
    selectedGuest: null,
    lastFeedback: null,
  );

  int? _pendingLitLetter;

  /// Names currently drawn on the wheel (may shrink as people are picked).
  List<String> wheelNames = const [];

  /// Guest display name → robocar character id.
  Map<String, String> guestCharacters = const {};

  GameSnapshot get snapshot => _snapshot;
  LevelsPack? get pack => _pack;
  VoiceService get voice => _voice;
  FairQueue get queue => _queue;

  RobocarCharacter? characterForGuest(String? guest) {
    if (guest == null) return null;
    final id = guestCharacters[guest];
    if (id == null) return null;
    return robocarById(id);
  }

  String labelForGuest(String guest) {
    final c = characterForGuest(guest);
    if (c == null) return guest;
    return c.labelForGuest(guest);
  }

  void _reassignCharacters() {
    guestCharacters = assignRobocarsToGuests(
      _snapshot.guests,
      existing: guestCharacters,
    );
  }

  Future<void> ensureMusic() => music.start();

  /// Playable (ready) levels in letter order.
  List<LevelDefinition> get playableLevels => _pack?.playableLevels ?? const [];

  LevelDefinition? get currentLevel {
    final levels = playableLevels;
    if (_snapshot.currentLevelIndex < 0 ||
        _snapshot.currentLevelIndex >= levels.length) {
      return null;
    }
    return levels[_snapshot.currentLevelIndex];
  }

  bool get hasMoreLevels {
    return _snapshot.currentLevelIndex < playableLevels.length;
  }

  Future<void> loadPack() async {
    _pack = await store.load();
    _voice.configure(_pack!.voiceLines);
    notifyListeners();
  }

  Future<void> reloadPack() async {
    await loadPack();
  }

  Future<void> savePack(LevelsPack pack) async {
    _pack = pack;
    await store.save(pack);
    _voice.configure(pack.voiceLines);
    notifyListeners();
  }

  /// In-memory pack swap for unit tests (skips disk).
  void debugSetPack(LevelsPack pack) {
    _pack = pack;
    _voice.configure(pack.voiceLines);
    notifyListeners();
  }

  Future<void> updateLevelAtPackIndex(int packIndex, LevelDefinition level) async {
    final pack = _pack;
    if (pack == null) return;
    final next = pack.replaceLevel(packIndex, level);
    await savePack(next);
  }

  void goToLobby() {
    music.setMenuVolume();
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
    _reassignCharacters();
    notifyListeners();
  }

  void removeGuest(String name) {
    final next = _snapshot.guests.where((g) => g != name).toList();
    _queue.setGuests(next);
    _snapshot = _snapshot.copyWith(guests: next);
    _reassignCharacters();
    notifyListeners();
  }

  void startGame() {
    if (_snapshot.guests.length < 2) return;
    if (playableLevels.isEmpty) return;
    music.setMenuVolume();
    _reassignCharacters();
    _queue.setGuests(_snapshot.guests);
    _pendingLitLetter = null;
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.progress,
      currentLevelIndex: 0,
      completedLetters: {},
      clearSelectedGuest: true,
      clearFeedback: true,
      clearLastPlayer: true,
      clearJustLitLetter: true,
    );
    notifyListeners();
  }

  bool get currentLevelIsExtra => currentLevel?.extra == true;

  Future<void> continueFromProgress() async {
    await _voice.stopAll();
    if (!hasMoreLevels) {
      _snapshot = _snapshot.copyWith(phase: GamePhase.demoDone);
      notifyListeners();
      await _voice.playKey('victory');
      return;
    }
    // Keep full menu bed while the wheel spins (no gameplay duck).
    await music.setMenuVolume();
    // Secret «экстра» levels draw from the full guest pool.
    wheelNames = currentLevelIsExtra
        ? _queue.peekAllNames()
        : _queue.peekWheelNames();
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.wheel,
      clearSelectedGuest: true,
      clearFeedback: true,
      clearJustLitLetter: true,
    );
    notifyListeners();
  }

  Future<({String winner, int index})> prepareSpin() async {
    await music.setMenuVolume();
    await _voice.playKey('spin');
    final extra = currentLevelIsExtra;
    wheelNames = extra ? _queue.peekAllNames() : _queue.peekWheelNames();
    final winner = extra ? _queue.nextFromPool() : _queue.next();
    final index = wheelNames.indexOf(winner).clamp(0, wheelNames.length - 1);
    notifyListeners();
    return (winner: winner, index: index);
  }

  void finishSpin(String winner) {
    _snapshot = _snapshot.copyWith(selectedGuest: winner);
    notifyListeners();
  }

  /// Android/TV Back: leave the current phase without exiting the app.
  /// Returns true if the event was handled in-app.
  bool handleSystemBack() {
    switch (_snapshot.phase) {
      case GamePhase.splash:
        return false;
      case GamePhase.lobby:
        backToSplash();
        return true;
      case GamePhase.progress:
        goToLobby();
        return true;
      case GamePhase.wheel:
        music.setMenuVolume();
        _snapshot = _snapshot.copyWith(
          phase: GamePhase.progress,
          clearSelectedGuest: true,
          clearFeedback: true,
        );
        notifyListeners();
        return true;
      case GamePhase.level:
        // Leave the task → letter board (do not exit the app).
        _voice.stopAll();
        music.setMenuVolume();
        _snapshot = _snapshot.copyWith(
          phase: GamePhase.progress,
          clearSelectedGuest: true,
          clearFeedback: true,
        );
        notifyListeners();
        return true;
      case GamePhase.demoDone:
        restart();
        return true;
    }
  }

  void openLevel() {
    music.setGameplayVolume();
    _snapshot = _snapshot.copyWith(phase: GamePhase.level, clearFeedback: true);
    notifyListeners();
    // Short SFX; question narration is handled on LevelScreen when the
    // question is actually shown (after video pause for video levels).
    final level = currentLevel;
    if (level != null) {
      if (level.voiceLines.containsKey('start')) {
        _voice.playKey('start', local: level.voiceLines);
      } else {
        _voice.playKey('level_start');
      }
    }
  }

  Future<bool> submitAnswer(String answer) async {
    final level = currentLevel;
    if (level == null) return false;
    final ok = level.matchesAnswer(answer);
    if (ok) {
      await completeCurrentLevel(feedback: 'Верно!');
    } else {
      _snapshot = _snapshot.copyWith(lastFeedback: 'Неверно, попробуйте ещё');
      notifyListeners();
      await _voice.playKey('wrong');
    }
    return ok;
  }

  /// Marks the current letter done (quiz or mini-game win).
  Future<void> completeCurrentLevel({String feedback = 'Верно!'}) async {
    final level = currentLevel;
    if (level == null) return;
    _pendingLitLetter = level.letterIndex;
    final completed = {..._snapshot.completedLetters, level.letterIndex};
    _snapshot = _snapshot.copyWith(
      completedLetters: completed,
      lastFeedback: feedback,
    );
    notifyListeners();
    await _voice.playKey('correct');
  }

  void advanceAfterCorrect() {
    final nextIndex = _snapshot.currentLevelIndex + 1;
    final player = _snapshot.selectedGuest;
    final lit = _pendingLitLetter;
    _pendingLitLetter = null;
    music.setMenuVolume();
    if (nextIndex >= playableLevels.length) {
      _snapshot = _snapshot.copyWith(
        phase: GamePhase.demoDone,
        currentLevelIndex: nextIndex,
        lastPlayer: player,
        justLitLetter: lit,
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
      lastPlayer: player,
      justLitLetter: lit,
      clearSelectedGuest: true,
      clearFeedback: true,
    );
    notifyListeners();
  }

  String progressHostLine() {
    final lit = _snapshot.justLitLetter;
    final next = currentLevel;
    if (lit != null) {
      if (PhraseLayout.isExtraLetter(lit)) {
        return 'Экстра пройдена! Дальше — круг.';
      }
      final ch = PhraseLayout.letters[lit];
      return 'Буква «$ch» зажглась! Дальше — круг.';
    }
    if (next?.extra == true) {
      return 'Секретная миссия! Гость — из всего пула.';
    }
    if (_snapshot.completedLetters.isEmpty) {
      return 'Соберим поздравление! Крутим круг.';
    }
    return 'Готовы к следующей букве? Крутим круг!';
  }

  void restart() {
    music.setMenuVolume();
    _pendingLitLetter = null;
    _snapshot = const GameSnapshot(
      phase: GamePhase.lobby,
      guests: [],
      completedLetters: {},
      currentLevelIndex: 0,
      selectedGuest: null,
      lastFeedback: null,
    );
    wheelNames = const [];
    guestCharacters = const {};
    _queue.setGuests(const []);
    notifyListeners();
  }

  void backToSplash() {
    music.setMenuVolume();
    _snapshot = _snapshot.copyWith(
      phase: GamePhase.splash,
      clearFeedback: true,
      clearSelectedGuest: true,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _voice.dispose();
    music.dispose();
    super.dispose();
  }
}
