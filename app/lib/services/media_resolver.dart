import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import 'level_pack_store.dart';
import 'media_paths.dart';

class MediaResolver {
  MediaResolver(this.store);

  final LevelPackStore store;

  Future<VideoPlayerController?> openVideo(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (MediaPaths.isAsset(path)) {
      return VideoPlayerController.asset(path);
    }
    if (MediaPaths.isUser(path)) {
      final dir = await store.mediaDir;
      final file = MediaPaths.resolveUserFile(dir, path);
      if (!await file.exists()) return null;
      return VideoPlayerController.file(file);
    }
    return VideoPlayerController.file(File(path));
  }

  Future<Source?> audioSource(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (MediaPaths.isAsset(path)) {
      final relative = path.startsWith('assets/')
          ? path.substring('assets/'.length)
          : path;
      return AssetSource(relative);
    }
    if (MediaPaths.isUser(path)) {
      final dir = await store.mediaDir;
      final file = MediaPaths.resolveUserFile(dir, path);
      if (!await file.exists()) return null;
      return DeviceFileSource(file.path);
    }
    return DeviceFileSource(path);
  }

  Future<Widget?> imageWidget(String? path, {BoxFit fit = BoxFit.contain}) async {
    if (path == null || path.isEmpty) return null;
    if (MediaPaths.isAsset(path)) {
      return Image.asset(path, fit: fit);
    }
    if (MediaPaths.isUser(path)) {
      final dir = await store.mediaDir;
      final file = MediaPaths.resolveUserFile(dir, path);
      if (!await file.exists()) {
        return const Center(child: Text('файл не найден'));
      }
      return Image.file(file, fit: fit);
    }
    return Image.file(File(path), fit: fit);
  }
}
