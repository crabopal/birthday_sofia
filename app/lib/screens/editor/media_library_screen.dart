import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../controllers/game_controller.dart';
import '../../services/media_paths.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pixel_scaffold.dart';
import '../../widgets/tv_button.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({
    super.key,
    required this.controller,
    this.pickMode = false,
  });

  final GameController controller;

  /// If true, tapping a file pops with `user:filename` ref.
  final bool pickMode;

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  List<File> _files = [];
  bool _importing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final files = await widget.controller.store.listMedia();
    if (mounted) setState(() => _files = files);
  }

  Future<void> _importFromDevice() async {
    if (_importing) return;
    setState(() {
      _importing = true;
      _status = 'Откройте файл на устройстве…';
    });
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'mp4',
          'webm',
          'mkv',
          'mov',
          'avi',
          'mp3',
          'wav',
          'aac',
          'm4a',
          'ogg',
          'flac',
        ],
      );
      if (picked.isEmpty) {
        if (mounted) setState(() => _status = null);
        return;
      }

      var imported = 0;
      for (final f in picked) {
        final path = f.path;
        if (path != null && path.isNotEmpty) {
          await widget.controller.store
              .importFromPath(path, originalName: f.name);
          imported++;
          continue;
        }
        // Fallback when the picker only exposes bytes / content URI.
        final bytes = await f.readAsBytes();
        await widget.controller.store.importBytes(f.name, bytes);
        imported++;
      }
      await _reload();
      if (mounted) {
        setState(() {
          _status = imported == 0
              ? 'Не удалось импортировать файлы'
              : 'Добавлено: $imported';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Ошибка: $e');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _delete(File file) async {
    final ref = MediaPaths.userRef(file.uri.pathSegments.last);
    await widget.controller.store.deleteMedia(ref);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 520;

    return PixelScaffold(
      title: widget.pickMode ? 'ВЫБОР МЕДИА' : 'МЕДИАТЕКА',
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Скопируйте файлы на ТВ (USB / Downloads),\nзатем нажмите «ДОБАВИТЬ ФАЙЛ».',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: compact ? 8 : 10,
                height: 1.6,
                color: PoliColors.rescueBlue,
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status!,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 9,
                  height: 1.5,
                  color: PoliColors.mint,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                TvButton(
                  label: _importing ? '…' : 'ДОБАВИТЬ ФАЙЛ',
                  autofocus: true,
                  compact: compact,
                  enabled: !_importing,
                  onPressed: _importing ? null : _importFromDevice,
                ),
                TvButton(
                  label: 'ОБНОВИТЬ',
                  primary: false,
                  compact: compact,
                  onPressed: _reload,
                ),
                TvButton(
                  label: 'НАЗАД',
                  primary: false,
                  compact: compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PixelPanel(
                padding: const EdgeInsets.all(8),
                color: PoliColors.softWhite,
                child: _files.isEmpty
                    ? const Center(
                        child: Text(
                          'Пока пусто.\nДобавьте файл с устройства.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 11,
                            height: 1.7,
                            color: PoliColors.inkSoft,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _files.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final name = file.uri.pathSegments.last;
                          final ref = MediaPaths.userRef(name);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (widget.pickMode) {
                                  Navigator.of(context).pop(ref);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: PoliColors.robocarRed,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'PressStart2P',
                                          fontSize: 10,
                                          height: 1.4,
                                          color: PoliColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (!widget.pickMode)
                                      TvButton(
                                        label: 'УДАЛ.',
                                        primary: false,
                                        compact: true,
                                        onPressed: () => _delete(file),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
