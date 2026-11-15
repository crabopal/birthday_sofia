import 'package:material_ui/material_ui.dart';

import '../../controllers/game_controller.dart';
import '../../models/level.dart';
import '../../models/phrase.dart';
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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
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
        ),
      ),
    );
  }

  Future<void> _openMedia() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaLibraryScreen(
          controller: widget.controller,
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
    final compact = MediaQuery.sizeOf(context).height < 520;
    final useStacked = compact || MediaQuery.sizeOf(context).width < 700;

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Готово к игре: $readyCount / ${PhraseLayout.letterCount}',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: compact ? 9 : 10,
            color: PoliColors.cream,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Медиа — с USB/памяти ТВ через «МЕДИАТЕКА».',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: compact ? 8 : 9,
            height: 1.6,
            color: PoliColors.rescueBlue,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            TvButton(
              label: 'МЕДИАТЕКА',
              primary: false,
              compact: compact,
              onPressed: _openMedia,
            ),
            TvButton(
              label: 'СБРОС',
              primary: false,
              compact: compact,
              onPressed: _reset,
            ),
            TvButton(
              label: 'НАЗАД',
              autofocus: true,
              compact: compact,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Изменения сохраняются на устройстве\nбез пересборки APK.',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 8,
            height: 1.6,
            color: PoliColors.steel,
          ),
        ),
      ],
    );

    final levelList = Container(
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openLevel(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: level.ready
                          ? PoliColors.beaconYellow
                          : PoliColors.dimLetter,
                      width: 1,
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
              ),
            ),
          );
        },
      ),
    );

    return PixelScaffold(
      title: 'РЕДАКТОР УРОВНЕЙ',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 28,
          8,
          compact ? 12 : 28,
          16,
        ),
        child: useStacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  controls,
                  const SizedBox(height: 12),
                  Expanded(child: levelList),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 5, child: controls),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: levelList),
                ],
              ),
      ),
    );
  }
}
