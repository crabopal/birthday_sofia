import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../controllers/game_controller.dart';
import '../../services/media_paths.dart';
import '../../services/media_upload_server.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pixel_scaffold.dart';
import '../../widgets/tv_button.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({
    super.key,
    required this.controller,
    required this.uploadServer,
    this.pickMode = false,
  });

  final GameController controller;
  final MediaUploadServer uploadServer;

  /// If true, tapping a file pops with `user:filename` ref.
  final bool pickMode;

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  List<File> _files = [];
  String? _lanIp;
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _reload();
    _sub = widget.uploadServer.uploaded.listen((_) => _reload());
    widget.uploadServer.lanIp().then((ip) {
      if (mounted) setState(() => _lanIp = ip);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final files = await widget.controller.store.listMedia();
    if (mounted) setState(() => _files = files);
  }

  Future<void> _delete(File file) async {
    final ref = MediaPaths.userRef(file.uri.pathSegments.last);
    await widget.controller.store.deleteMedia(ref);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final url = _lanIp == null
        ? 'http://<IP-ТВ>:${widget.uploadServer.port}'
        : 'http://$_lanIp:${widget.uploadServer.port}';

    return PixelScaffold(
      title: widget.pickMode ? 'ВЫБОР МЕДИА' : 'МЕДИАТЕКА',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Загрузите файл с телефона в браузере:\n$url',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 10,
                height: 1.6,
                color: PoliColors.rescueBlue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TvButton(label: 'ОБНОВИТЬ', onPressed: _reload),
                const SizedBox(width: 12),
                TvButton(
                  label: 'НАЗАД',
                  autofocus: true,
                  primary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: PoliColors.steel, width: 2),
                  color: PoliColors.road.withValues(alpha: 0.8),
                ),
                child: _files.isEmpty
                    ? const Center(
                        child: Text(
                          'Пока пусто.\nОткройте URL на телефоне.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 11,
                            height: 1.7,
                            color: PoliColors.steel,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _files.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final name = file.uri.pathSegments.last;
                          final ref = MediaPaths.userRef(name);
                          return Focus(
                            child: Builder(
                              builder: (context) {
                                final focused = Focus.of(context).hasFocus;
                                return InkWell(
                                  onTap: () {
                                    if (widget.pickMode) {
                                      Navigator.of(context).pop(ref);
                                    }
                                  },
                                  onLongPress: () => _delete(file),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: focused
                                            ? PoliColors.focus
                                            : PoliColors.robocarRed,
                                        width: focused ? 3 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontFamily: 'PressStart2P',
                                              fontSize: 11,
                                              color: PoliColors.cream,
                                            ),
                                          ),
                                        ),
                                        if (!widget.pickMode)
                                          TvButton(
                                            label: 'УДАЛ.',
                                            primary: false,
                                            onPressed: () => _delete(file),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
