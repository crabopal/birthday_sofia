import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Loops cheerful menu BGM; volume dips during levels / TTS.
class MusicService {
  MusicService({AudioPlayer? player}) : _injected = player;

  final AudioPlayer? _injected;
  AudioPlayer? _player;
  bool _disabled = false;
  bool _started = false;

  void disableForTests() => _disabled = true;

  AudioPlayer get _audio => _injected ?? (_player ??= AudioPlayer());

  Future<void> start() async {
    if (_disabled || _started) return;
    try {
      await _audio.setReleaseMode(ReleaseMode.loop);
      await _audio.setVolume(0.32);
      await _audio.play(AssetSource('audio/music/theme_loop.wav'));
      _started = true;
    } catch (e) {
      debugPrint('MusicService start failed: $e');
    }
  }

  Future<void> setMenuVolume() async {
    if (_disabled) return;
    try {
      await _audio.setVolume(0.32);
      if (_started) await _audio.resume();
    } catch (_) {}
  }

  Future<void> setGameplayVolume() async {
    if (_disabled) return;
    try {
      await _audio.setVolume(0.12);
    } catch (_) {}
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
