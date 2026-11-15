import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/level.dart';
import '../models/phrase.dart';

/// Persists an editable levels pack + user media under app documents.
class LevelPackStore {
  Directory? _root;
  Directory? _media;

  Future<Directory> get root async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    _root = Directory('${docs.path}/sonya_levels');
    if (!await _root!.exists()) {
      await _root!.create(recursive: true);
    }
    return _root!;
  }

  Future<Directory> get mediaDir async {
    if (_media != null) return _media!;
    final r = await root;
    _media = Directory('${r.path}/media');
    if (!await _media!.exists()) {
      await _media!.create(recursive: true);
    }
    return _media!;
  }

  Future<File> get packFile async {
    final r = await root;
    return File('${r.path}/pack.json');
  }

  Future<LevelsPack> load() async {
    final file = await packFile;
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _ensureSeventeen(LevelsPack.fromJson(json));
    }
    final bundled = await _loadBundled();
    final ensured = _ensureSeventeen(bundled);
    await save(ensured);
    return ensured;
  }

  Future<LevelsPack> _loadBundled() async {
    final raw = await rootBundle.loadString('assets/levels/demo.json');
    return LevelsPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Always 17 letter slots; keeps existing content, fills gaps with stubs.
  LevelsPack _ensureSeventeen(LevelsPack pack) {
    final byLetter = <int, LevelDefinition>{
      for (final l in pack.levels) l.letterIndex: l,
    };
    final levels = <LevelDefinition>[];
    for (var i = 0; i < PhraseLayout.letterCount; i++) {
      final existing = byLetter[i];
      if (existing != null) {
        levels.add(existing);
      } else {
        final letter = PhraseLayout.letters[i];
        levels.add(
          LevelDefinition(
            id: 'L${i + 1}',
            letterIndex: i,
            type: LevelType.pictureQuestion,
            title: 'Буква $letter',
            question: 'Контент ещё не заполнен. Ответ: далее',
            answer: 'далее',
            acceptedAnswers: const ['далее', 'дальше', 'ok', 'ок'],
            ready: false,
          ),
        );
      }
    }
    levels.sort((a, b) => a.letterIndex.compareTo(b.letterIndex));
    return pack.copyWith(levels: levels);
  }

  Future<void> save(LevelsPack pack) async {
    final file = await packFile;
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(pack.toJson()));
  }

  Future<void> resetToBundled() async {
    final file = await packFile;
    if (await file.exists()) {
      await file.delete();
    }
    final media = await mediaDir;
    if (await media.exists()) {
      await for (final entity in media.list()) {
        if (entity is File) await entity.delete();
      }
    }
  }

  Future<List<File>> listMedia() async {
    final dir = await mediaDir;
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File) files.add(entity);
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Saves bytes as `user:safeName` and returns that ref.
  Future<String> importBytes(String originalName, List<int> bytes) async {
    final dir = await mediaDir;
    final safe = _safeName(originalName);
    final file = File('${dir.path}/$safe');
    await file.writeAsBytes(bytes, flush: true);
    return 'user:$safe';
  }

  /// Copies a device file into the media library (preferred for large video).
  Future<String> importFromPath(String path, {String? originalName}) async {
    final source = File(path);
    if (!await source.exists()) {
      throw StateError('Файл не найден: $path');
    }
    final dir = await mediaDir;
    final name = originalName ?? source.uri.pathSegments.last;
    var safe = _safeName(name);
    var dest = File('${dir.path}/$safe');
    if (await dest.exists()) {
      final stem = safe.contains('.')
          ? safe.substring(0, safe.lastIndexOf('.'))
          : safe;
      final ext = safe.contains('.')
          ? safe.substring(safe.lastIndexOf('.'))
          : '';
      safe = '${stem}_${DateTime.now().millisecondsSinceEpoch}$ext';
      dest = File('${dir.path}/$safe');
    }
    await source.copy(dest.path);
    return 'user:$safe';
  }

  Future<void> deleteMedia(String userRef) async {
    if (!userRef.startsWith('user:')) return;
    final dir = await mediaDir;
    final file = File('${dir.path}/${userRef.substring(5)}');
    if (await file.exists()) await file.delete();
  }

  String _safeName(String name) {
    final base = name.split(RegExp(r'[\\/]')).last;
    final cleaned = base.replaceAll(RegExp(r'[^a-zA-Z0-9._\-]'), '_');
    if (cleaned.isEmpty) {
      return 'media_${DateTime.now().millisecondsSinceEpoch}';
    }
    return cleaned;
  }
}
