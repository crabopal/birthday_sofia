import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'media_paths.dart';
import 'level_pack_store.dart';
import 'music_service.dart';

/// Plays pre-baked voice / SFX clips and temporary TTS for questions.
class VoiceService {
  VoiceService({AudioPlayer? player, this.store, this.music})
      : _injected = player;

  final AudioPlayer? _injected;
  final LevelPackStore? store;
  final MusicService? music;
  AudioPlayer? _player;
  FlutterTts? _tts;
  Map<String, String> _globalLines = {};
  bool _disabled = false;
  bool _ttsReady = false;

  /// For unit tests without a platform audio channel.
  void disableForTests() => _disabled = true;

  AudioPlayer get _audio {
    return _injected ?? (_player ??= AudioPlayer());
  }

  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Future<void> _ensureSfxContext() async {
    try {
      await _audio.setAudioContext(_sfxContext);
    } catch (_) {}
  }

  void configure(Map<String, String> globalLines) {
    _globalLines = Map<String, String>.from(globalLines);
  }

  Future<void> ensureTts() async {
    if (_disabled || _ttsReady) return;
    try {
      final tts = FlutterTts();
      _tts = tts;
      await tts.awaitSpeakCompletion(true);
      final langs = await tts.getLanguages;
      if (langs is List && langs.any((l) => l.toString().startsWith('ru'))) {
        await tts.setLanguage('ru-RU');
      } else {
        await tts.setLanguage('ru-RU');
      }
      await tts.setSpeechRate(0.42);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  Future<void> playKey(String key, {Map<String, String>? local}) async {
    if (_disabled) return;
    final path = local?[key] ?? _globalLines[key];
    if (path == null || path.isEmpty) return;
    await playPath(path);
  }

  Future<void> playPath(String path) async {
    if (_disabled) return;
    try {
      await stopAll();
      await _ensureSfxContext();
      final mediaStore = store;
      if (MediaPaths.isUser(path) && mediaStore != null) {
        final dir = await mediaStore.mediaDir;
        final file = MediaPaths.resolveUserFile(dir, path);
        if (await file.exists()) {
          await _audio.play(DeviceFileSource(file.path));
          return;
        }
      }
      if (MediaPaths.isAsset(path) || path.startsWith('assets/')) {
        final relative = path.startsWith('assets/')
            ? path.substring('assets/'.length)
            : path;
        await _audio.play(AssetSource(relative));
        return;
      }
      await _audio.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('VoiceService play failed for $path: $e');
    }
  }

  Future<void> playAsset(String assetPath) => playPath(assetPath);

  /// Speaks [text] with on-device TTS; ducks BGM while speaking.
  Future<void> speakText(String text) async {
    if (_disabled) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await ensureTts();
    final tts = _tts;
    if (tts == null) return;
    try {
      await _audio.stop();
      await tts.stop();
      await music?.duck();
      await tts.speak(trimmed);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    } finally {
      await music?.unduck();
    }
  }

  Future<void> stopAll() async {
    try {
      await _audio.stop();
    } catch (_) {}
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopAll();
    await _injected?.dispose();
    await _player?.dispose();
    await _tts?.stop();
  }
}
