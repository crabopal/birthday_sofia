import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays pre-baked voice / SFX clips from assets.
class VoiceService {
  VoiceService({AudioPlayer? player}) : _injected = player;

  AudioPlayer? _injected;
  AudioPlayer? _player;
  Map<String, String> _globalLines = {};
  bool _disabled = false;

  /// For unit tests without a platform audio channel.
  void disableForTests() => _disabled = true;

  AudioPlayer get _audio {
    return _injected ??= _player ??= AudioPlayer();
  }

  void configure(Map<String, String> globalLines) {
    _globalLines = Map<String, String>.from(globalLines);
  }

  Future<void> playKey(String key, {Map<String, String>? local}) async {
    if (_disabled) return;
    final path = local?[key] ?? _globalLines[key];
    if (path == null || path.isEmpty) return;
    await playAsset(path);
  }

  Future<void> playAsset(String assetPath) async {
    if (_disabled) return;
    try {
      final relative = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;
      await _audio.stop();
      await _audio.play(AssetSource(relative));
    } catch (e) {
      debugPrint('VoiceService play failed for $assetPath: $e');
    }
  }

  Future<void> dispose() async {
    await _injected?.dispose();
    await _player?.dispose();
  }
}
