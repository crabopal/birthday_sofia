import 'package:material_ui/material_ui.dart';

import '../../controllers/game_controller.dart';
import '../../models/level.dart';
import '../../models/phrase.dart';
import '../../services/media_paths.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pixel_scaffold.dart';
import '../../widgets/tv_button.dart';
import 'media_library_screen.dart';

class LevelEditScreen extends StatefulWidget {
  const LevelEditScreen({
    super.key,
    required this.controller,
    required this.packIndex,
  });

  final GameController controller;
  final int packIndex;

  @override
  State<LevelEditScreen> createState() => _LevelEditScreenState();
}

class _LevelEditScreenState extends State<LevelEditScreen> {
  late TextEditingController _title;
  late TextEditingController _question;
  late TextEditingController _answer;
  late TextEditingController _accepted;
  late TextEditingController _pauseAt;
  late LevelType _type;
  late bool _ready;
  String? _image;
  String? _video;
  String? _audio;
  bool _saving = false;

  LevelDefinition get _original =>
      widget.controller.pack!.levels[widget.packIndex];

  @override
  void initState() {
    super.initState();
    final level = _original;
    _title = TextEditingController(text: level.title);
    _question = TextEditingController(text: level.question);
    _answer = TextEditingController(text: level.answer);
    _accepted = TextEditingController(text: level.acceptedAnswers.join(', '));
    _pauseAt = TextEditingController(
      text: level.pauseAtMs?.toString() ?? '',
    );
    _type = level.type;
    _ready = level.ready;
    _image = level.imageAsset;
    _video = level.videoAsset;
    _audio = level.audioAsset;
  }

  @override
  void dispose() {
    _title.dispose();
    _question.dispose();
    _answer.dispose();
    _accepted.dispose();
    _pauseAt.dispose();
    super.dispose();
  }

  Future<String?> _pickMedia() async {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MediaLibraryScreen(
          controller: widget.controller,
          pickMode: true,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final accepted = _accepted.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (accepted.isEmpty && _answer.text.trim().isNotEmpty) {
      accepted.add(_answer.text.trim());
    }
    final pause = int.tryParse(_pauseAt.text.trim());
    final updated = _original.copyWith(
      title: _title.text.trim(),
      question: _question.text.trim(),
      answer: _answer.text.trim(),
      acceptedAnswers: accepted,
      type: _type,
      ready: _ready,
      imageAsset: _image,
      videoAsset: _video,
      audioAsset: _audio,
      pauseAtMs: pause,
      clearImage: _image == null,
      clearVideo: _video == null,
      clearAudio: _audio == null,
      clearPauseAt: pause == null,
    );
    await widget.controller.updateLevelAtPackIndex(widget.packIndex, updated);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено на ТВ')),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 11,
          color: PoliColors.cream,
          height: 1.5,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 9,
            color: PoliColors.steel,
          ),
        ),
      ),
    );
  }

  Widget _mediaRow(String label, String? value, VoidCallback onPick, VoidCallback onClear) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: ${MediaPaths.displayName(value)}',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 9,
                color: PoliColors.cream,
              ),
            ),
          ),
          TvButton(label: 'ФАЙЛ', primary: false, onPressed: onPick),
          const SizedBox(width: 8),
          TvButton(label: '×', primary: false, onPressed: onClear),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = PhraseLayout.letters[_original.letterIndex];

    return PixelScaffold(
      title: 'БУКВА $letter',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: ListView(
                children: [
                  _field('Заголовок', _title),
                  _field('Вопрос', _question, maxLines: 3),
                  _field('Ответ', _answer),
                  _field('Доп. ответы (через запятую)', _accepted),
                  if (_type == LevelType.videoQuestion)
                    _field('Пауза видео, мс', _pauseAt),
                  const SizedBox(height: 8),
                  Text(
                    'Тип: ${LevelDefinition.typeLabel(_type)}',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      color: PoliColors.beaconYellow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in LevelType.values)
                        TvButton(
                          label: LevelDefinition.typeLabel(t).toUpperCase(),
                          primary: _type == t,
                          onPressed: () => setState(() => _type = t),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TvButton(
                    label: _ready ? 'В ИГРЕ: ДА' : 'В ИГРЕ: НЕТ',
                    primary: _ready,
                    onPressed: () => setState(() => _ready = !_ready),
                  ),
                  const SizedBox(height: 16),
                  if (_type == LevelType.pictureQuestion)
                    _mediaRow(
                      'Картинка',
                      _image,
                      () async {
                        final ref = await _pickMedia();
                        if (ref != null) setState(() => _image = ref);
                      },
                      () => setState(() => _image = null),
                    ),
                  if (_type == LevelType.videoQuestion)
                    _mediaRow(
                      'Видео',
                      _video,
                      () async {
                        final ref = await _pickMedia();
                        if (ref != null) setState(() => _video = ref);
                      },
                      () => setState(() => _video = null),
                    ),
                  if (_type == LevelType.audioQuestion)
                    _mediaRow(
                      'Аудио',
                      _audio,
                      () async {
                        final ref = await _pickMedia();
                        if (ref != null) setState(() => _audio = ref);
                      },
                      () => setState(() => _audio = null),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      TvButton(
                        label: _saving ? '...' : 'СОХРАНИТЬ',
                        autofocus: true,
                        enabled: !_saving,
                        onPressed: _saving ? null : _save,
                      ),
                      const SizedBox(width: 12),
                      TvButton(
                        label: 'ОТМЕНА',
                        primary: false,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
