import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Loops theme BGM; ducks under levels / TTS / puzzle media.
class MusicService {
  MusicService({AudioPlayer? player}) : _injected = player;

  final AudioPlayer? _injected;
  AudioPlayer? _player;
  bool _disabled = false;
  bool _started = false;

  static const double menuVolume = 0.38;
  static const double levelVolume = 0.10;
  static const double duckedVolume = 0.045;

  double _baseVolume = menuVolume;
  int _duckDepth = 0;

  void disableForTests() => _disabled = true;

  AudioPlayer get _audio => _injected ?? (_player ??= AudioPlayer());

  Future<void> start() async {
    if (_disabled || _started) return;
    try {
      await _audio.setReleaseMode(ReleaseMode.loop);
      _baseVolume = menuVolume;
      await _audio.setVolume(menuVolume);
      await _audio.play(AssetSource('audio/music/theme_original.mp3'));
      _started = true;
    } catch (e) {
      debugPrint('MusicService start failed: $e');
    }
  }

  Future<void> _applyVolume() async {
    if (_disabled) return;
    final vol = _duckDepth > 0 ? duckedVolume : _baseVolume;
    try {
      await _audio.setVolume(vol);
      if (_started) await _audio.resume();
    } catch (_) {}
  }

  Future<void> setMenuVolume() async {
    _baseVolume = menuVolume;
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
    if (_disabled) return;
    try {
      await _audio.resume();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _audio.stop();
      await _injected?.dispose();
      await _player?.dispose();
    } catch (_) {}
  }
}
