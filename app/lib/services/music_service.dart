import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Loops theme BGM; ducks under levels / TTS / puzzle media.
class MusicService {
  MusicService({AudioPlayer? player}) : _injected = player;

  final AudioPlayer? _injected;
  AudioPlayer? _player;
  bool _disabled = false;
  bool _started = false;
  bool _lifecyclePaused = false;

  static const double menuVolume = 0.38;
  static const double levelVolume = 0.10;
  static const double duckedVolume = 0.045;

  double _baseVolume = menuVolume;
  int _duckDepth = 0;

  void disableForTests() => _disabled = true;

  AudioPlayer get _audio => _injected ?? (_player ??= AudioPlayer());

  /// Mix with SFX so a wheel spin beep does not system-duck the bed.
  static final AudioContext _bgmContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Future<void> start() async {
    if (_disabled || _started) return;
    try {
      await _audio.setAudioContext(_bgmContext);
      await _audio.setReleaseMode(ReleaseMode.loop);
      _baseVolume = menuVolume;
      await _audio.setVolume(menuVolume);
      await _audio.play(AssetSource('audio/music/theme_original.mp3'));
      _started = true;
      _lifecyclePaused = false;
    } catch (e) {
      debugPrint('MusicService start failed: $e');
    }
  }

  Future<void> _applyVolume() async {
    if (_disabled) return;
    final vol = _duckDepth > 0 ? duckedVolume : _baseVolume;
    try {
      await _audio.setVolume(vol);
    } catch (_) {}
  }

  Future<void> setMenuVolume() async {
    _baseVolume = menuVolume;
    // Clear any leftover task duck when returning to menu/wheel.
    _duckDepth = 0;
    await _applyVolume();
  }

  Future<void> setGameplayVolume() async {
    _baseVolume = levelVolume;
    await _applyVolume();
  }

  /// Temporary extra duck (TTS / puzzle audio / video). Nestable.
  Future<void> duck() async {
    _duckDepth++;
    await _applyVolume();
  }

  Future<void> unduck() async {
    if (_duckDepth > 0) _duckDepth--;
    await _applyVolume();
  }

  Future<void> pause() async {
    if (_disabled) return;
    try {
      await _audio.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_disabled || !_started || _lifecyclePaused) return;
    try {
      await _audio.resume();
    } catch (_) {}
  }

  /// Phone lock / app background — stop the bed until foreground again.
  Future<void> pauseForLifecycle() async {
    _lifecyclePaused = true;
    await pause();
  }

  Future<void> resumeAfterLifecycle() async {
    if (_disabled) return;
    _lifecyclePaused = false;
    if (_started) {
      await _applyVolume();
      await resume();
    }
  }

  Future<void> dispose() async {
    try {
      await _audio.stop();
      await _injected?.dispose();
      await _player?.dispose();
    } catch (_) {}
  }
}
