import 'package:material_ui/material_ui.dart';

import '../../controllers/game_controller.dart';
import '../../models/level.dart';
import '../../models/phrase.dart';
import '../../services/media_upload_server.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pixel_scaffold.dart';
import '../../widgets/tv_button.dart';
import 'level_edit_screen.dart';
import 'media_library_screen.dart';

class EditorHomeScreen extends StatefulWidget {
  const EditorHomeScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<EditorHomeScreen> createState() => _EditorHomeScreenState();
}

class _EditorHomeScreenState extends State<EditorHomeScreen> {
  late final MediaUploadServer _uploadServer;
  String? _lanIp;
  bool _serverOn = false;

  @override
  void initState() {
    super.initState();
    _uploadServer = MediaUploadServer(widget.controller.store);
    widget.controller.addListener(_refresh);
    _bootstrapServer();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrapServer() async {
    try {
      await _uploadServer.start();
      final ip = await _uploadServer.lanIp();
      if (mounted) {
        setState(() {
          _serverOn = true;
          _lanIp = ip;
        });
      }
    } catch (e) {
      debugPrint('upload server failed: $e');
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _uploadServer.dispose();
    super.dispose();
  }

  Future<void> _openLevel(int index) async {
    final pack = widget.controller.pack;
    if (pack == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelEditScreen(
          controller: widget.controller,
          packIndex: index,
          uploadServer: _uploadServer,
        ),
      ),
    );
  }

  Future<void> _openMedia() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaLibraryScreen(
          controller: widget.controller,
          uploadServer: _uploadServer,
        ),
      ),
    );
  }

  Future<void> _reset() async {
    await widget.controller.store.resetToBundled();
    await widget.controller.reloadPack();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сброшено к демо из APK')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.controller.pack;
    final levels = pack?.levels ?? const <LevelDefinition>[];
    final readyCount = levels.where((l) => l.ready).length;
    final url = _lanIp == null
        ? 'сервер: порт ${_uploadServer.port}'
        : 'http://$_lanIp:${_uploadServer.port}';

    return PixelScaffold(
      title: 'РЕДАКТОР УРОВНЕЙ',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Готово к игре: $readyCount / ${PhraseLayout.letterCount}',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      color: PoliColors.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _serverOn
                        ? 'Загрузка медиа с телефона:\n$url'
                        : 'Сервер загрузки не запущен',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      height: 1.6,
                      color: PoliColors.rescueBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TvButton(
                        label: 'МЕДИАТЕКА',
                        primary: false,
                        onPressed: _openMedia,
                      ),
                      const SizedBox(width: 12),
                      TvButton(
                        label: 'СБРОС',
                        primary: false,
                        onPressed: _reset,
                      ),
                      const SizedBox(width: 12),
                      TvButton(
                        label: 'НАЗАД',
                        autofocus: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Изменения сохраняются на ТВ\nбез пересборки APK.',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 8,
                      height: 1.6,
                      color: PoliColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: PoliColors.road.withValues(alpha: 0.85),
                  border: Border.all(color: PoliColors.steel, width: 2),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    final letter = PhraseLayout.letters[level.letterIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Focus(
                        child: Builder(
                          builder: (context) {
                            final focused = Focus.of(context).hasFocus;
                            return InkWell(
                              onTap: () => _openLevel(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: focused
                                        ? PoliColors.focus
                                        : (level.ready
                                            ? PoliColors.beaconYellow
                                            : PoliColors.dimLetter),
                                    width: focused ? 3 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      letter,
                                      style: TextStyle(
                                        fontFamily: 'PressStart2P',
                                        fontSize: 16,
                                        color: level.ready
                                            ? PoliColors.beaconYellow
                                            : PoliColors.steel,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        '${level.title} · ${LevelDefinition.typeLabel(level.type)}'
                                        '${level.ready ? '' : ' · черновик'}',
                                        style: const TextStyle(
                                          fontFamily: 'PressStart2P',
                                          fontSize: 9,
                                          height: 1.5,
                                          color: PoliColors.cream,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '>',
                                      style: TextStyle(
                                        fontFamily: 'PressStart2P',
                                        fontSize: 12,
                                        color: PoliColors.robocarRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
