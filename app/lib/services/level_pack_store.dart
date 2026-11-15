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
      final migrated = _migrateCommaSlot(LevelsPack.fromJson(json));
      return _ensureLetterSlots(migrated);
    }
    final bundled = await _loadBundled();
    final ensured = _ensureLetterSlots(bundled);
    await save(ensured);
    return ensured;
  }

  Future<LevelsPack> _loadBundled() async {
    final raw = await rootBundle.loadString('assets/levels/demo.json');
    return LevelsPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static final LevelDefinition bundledCommaLevel = LevelDefinition(
    id: 'L14',
    letterIndex: PhraseLayout.commaLetterIndex,
    type: LevelType.minigame,
    title: 'Экстра · Соник спасает Пости',
    question: 'Соник в городе робокаров — спаси Пости из лап Эггмана!',
    answer: 'sonic',
    acceptedAnswers: const ['sonic'],
    ready: true,
    extra: true,
    voiceLines: const {'start': 'assets/audio/voice/level_start.wav'},
  );

  /// Old packs had 17 letters (comma decorative). Shift СОНЯ up and insert comma.
  LevelsPack _migrateCommaSlot(LevelsPack pack) {
    final hasComma = pack.levels.any(
      (l) =>
          l.letterIndex == PhraseLayout.commaLetterIndex &&
          (l.extra || l.type == LevelType.minigame),
    );
    if (hasComma) return pack;
    final maxIdx = pack.levels.fold<int>(
      -1,
      (m, l) => l.letterIndex > m ? l.letterIndex : m,
    );
    // Only migrate classic 0..16 packs.
    if (maxIdx != 16 || pack.levels.length < 17) return pack;
    final shifted = [
      for (final l in pack.levels)
        if (l.letterIndex >= PhraseLayout.commaLetterIndex)
          l.copyWith(letterIndex: l.letterIndex + 1)
        else
          l,
    ];
    return pack.copyWith(levels: shifted);
  }

  /// Always one slot per phrase letter (incl. comma); keeps content, fills stubs.
  LevelsPack _ensureLetterSlots(LevelsPack pack) {
    final byLetter = <int, LevelDefinition>{
      for (final l in pack.levels) l.letterIndex: l,
    };
    final levels = <LevelDefinition>[];
    for (var i = 0; i < PhraseLayout.letterCount; i++) {
      final existing = byLetter[i];
      if (existing != null) {
        levels.add(existing);
      } else if (i == PhraseLayout.commaLetterIndex) {
        levels.add(bundledCommaLevel);
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
