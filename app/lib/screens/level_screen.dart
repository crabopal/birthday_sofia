import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../controllers/game_controller.dart';
import '../models/level.dart';
import '../services/media_resolver.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_progress.dart';
import '../widgets/pixel_scaffold.dart';
import '../widgets/tv_button.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final _answerController = TextEditingController();
  final _answerFocus = FocusNode();
  VideoPlayerController? _video;
  AudioPlayer? _audio;
  Widget? _image;
  bool _mediaReady = false;
  bool _videoPausedForQuestion = false;
  bool _submitting = false;
  late final MediaResolver _resolver;

  LevelDefinition? get level => widget.controller.currentLevel;

  @override
  void initState() {
    super.initState();
    _resolver = MediaResolver(widget.controller.store);
    _initMedia();
  }

  Future<void> _speakQuestion(String question) async {
    // Let the short level_start SFX finish first.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await widget.controller.voice.speakText(question);
  }

  Future<void> _initMedia() async {
    final lvl = level;
    if (lvl == null) return;

    if (lvl.type == LevelType.videoQuestion && lvl.videoAsset != null) {
      final controller = await _resolver.openVideo(lvl.videoAsset);
      if (controller == null) {
        if (mounted) {
          setState(() => _mediaReady = true);
          await _speakQuestion(lvl.question);
        }
        return;
      }
      _video = controller;
      await controller.initialize();
      controller.addListener(_onVideoTick);
      await controller.play();
      if (mounted) setState(() => _mediaReady = true);
      // Question is spoken when the video pauses (see _onVideoTick).
      if (lvl.pauseAtMs == null) {
        await _speakQuestion(lvl.question);
      }
    } else if (lvl.type == LevelType.audioQuestion && lvl.audioAsset != null) {
      // Narrate the question first, then play the puzzle audio.
      if (mounted) setState(() => _mediaReady = true);
      await _speakQuestion(lvl.question);
      if (!mounted) return;
      _audio = AudioPlayer();
      final source = await _resolver.audioSource(lvl.audioAsset);
      if (source != null) await _audio!.play(source);
    } else if (lvl.type == LevelType.pictureQuestion) {
      _image = await _resolver.imageWidget(lvl.imageAsset);
      if (mounted) setState(() => _mediaReady = true);
      await _speakQuestion(lvl.question);
    } else {
      if (mounted) setState(() => _mediaReady = true);
      await _speakQuestion(lvl.question);
    }
  }

  void _onVideoTick() {
    final lvl = level;
    final video = _video;
    if (lvl == null || video == null || _videoPausedForQuestion) return;
    final pauseAt = lvl.pauseAtMs;
    if (pauseAt == null) return;
    if (video.value.position.inMilliseconds >= pauseAt) {
      video.pause();
      setState(() => _videoPausedForQuestion = true);
      _answerFocus.requestFocus();
      _speakQuestion(lvl.question);
    }
  }

  Future<void> _replayAudio() async {
    final lvl = level;
    if (lvl?.audioAsset == null || _audio == null) return;
    final source = await _resolver.audioSource(lvl!.audioAsset);
    if (source == null) return;
    await widget.controller.voice.stopAll();
    await _audio!.stop();
    await _audio!.play(source);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.controller.submitAnswer(_answerController.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) widget.controller.advanceAfterCorrect();
    } else {
      _answerController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _answerController.text.length,
      );
      _answerFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _audio?.dispose();
    _answerController.dispose();
    _answerFocus.dispose();
    widget.controller.voice.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _body(),
    );
  }

  Widget _body() {
    final lvl = level;
    final snap = widget.controller.snapshot;
    if (lvl == null) {
      return const PixelScaffold(
        showCharacters: false,
        child: Center(child: Text('Нет уровня')),
      );
    }

    final showQuestion = lvl.type != LevelType.videoQuestion ||
        _videoPausedForQuestion ||
        (lvl.pauseAtMs == null);

    return PixelScaffold(
      title: lvl.title,
      showCharacters: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Expanded(child: _buildMedia(lvl)),
                  if (showQuestion) ...[
                    const SizedBox(height: 16),
                    Text(
                      lvl.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 14,
                        height: 1.6,
                        color: PoliColors.ink,
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Смотрим ролик...',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 12,
                          color: PoliColors.inkSoft,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              flex: 4,
              child: PixelPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LetterProgressView(
                      completedLetters: snap.completedLetters,
                      currentLetterIndex: lvl.letterIndex,
                      compact: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ход: ${snap.selectedGuest ?? '—'}',
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 11,
                        color: PoliColors.robocarRed,
                      ),
                    ),
                    const Spacer(),
                    if (showQuestion) ...[
                      TextField(
                        controller: _answerController,
                        focusNode: _answerFocus,
                        autofocus: lvl.type != LevelType.videoQuestion,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 14,
                          color: PoliColors.ink,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ответ',
                          labelText: 'Ответ',
                          labelStyle: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 10,
                            color: PoliColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TvButton(
                            label: 'ОТВЕТИТЬ',
                            onPressed: _submitting ? null : _submit,
                            enabled: !_submitting,
                          ),
                          if (lvl.type == LevelType.audioQuestion) ...[
                            const SizedBox(width: 12),
                            TvButton(
                              label: 'ЕЩЁ РАЗ',
                              primary: false,
                              onPressed: _replayAudio,
                            ),
                          ],
                        ],
                      ),
                      if (snap.lastFeedback != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          snap.lastFeedback!,
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 12,
                            color: snap.lastFeedback == 'Верно!'
                                ? PoliColors.mint
                                : PoliColors.robocarRed,
                          ),
                        ),
                      ],
                    ],
                    if (!_mediaReady)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Загрузка медиа...',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 9,
                            color: PoliColors.inkSoft,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(LevelDefinition lvl) {
    switch (lvl.type) {
      case LevelType.pictureQuestion:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PoliColors.panelBorder, width: 3),
            color: PoliColors.softWhite,
          ),
          clipBehavior: Clip.antiAlias,
          child: _image ??
              const Center(
                child: Text(
                  'нет картинки',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                    color: PoliColors.inkSoft,
                  ),
                ),
              ),
        );
      case LevelType.videoQuestion:
        final video = _video;
        if (video == null || !video.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: PoliColors.robocarRed),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PoliColors.panelBorder, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
        );
      case LevelType.audioQuestion:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PoliColors.hellyBlue, width: 3),
            color: PoliColors.panel,
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, size: 72, color: PoliColors.hellyBlue),
                SizedBox(height: 16),
                Text(
                  'АУДИО-ВОПРОС',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 14,
                    color: PoliColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      case LevelType.minigame:
        return const Center(
          child: Text(
            'Мини-игра — скоро',
            style: TextStyle(fontFamily: 'PressStart2P', fontSize: 14),
          ),
        );
    }
  }
}
