import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../models/level.dart';
import '../models/phrase.dart';
import '../models/robocar_character.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_progress.dart';
import '../widgets/pixel_scaffold.dart';
import '../widgets/robocar_avatar.dart';
import '../widgets/tv_button.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  late final AnimationController _celebrate;
  late final AnimationController _guestBounce;
  late final AnimationController _confetti;
  bool _spoke = false;
  int? _ritualFor;

  @override
  void initState() {
    super.initState();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _guestBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoff());
  }

  void _kickoff() {
    if (!mounted) return;
    final snap = widget.controller.snapshot;
    final lit = snap.justLitLetter;
    _ritualFor = lit;
    if (lit != null) {
      _celebrate.forward(from: 0);
      _confetti.forward(from: 0);
    }
    if (snap.lastPlayer != null) {
      _guestBounce.forward(from: 0);
    }
    _speakHostLine();
  }

  Future<void> _speakHostLine() async {
    if (_spoke) return;
    _spoke = true;
    final line = widget.controller.progressHostLine();
    // Let letter SFX / celebration start first.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await widget.controller.voice.speakText(line);
  }

  @override
  void dispose() {
    _celebrate.dispose();
    _guestBounce.dispose();
    _confetti.dispose();
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
    final c = widget.controller;
    final snap = c.snapshot;
    final level = c.currentLevel;
    final letterIndex = level?.letterIndex ?? snap.currentLevelIndex;
    final levelLabel = PhraseLayout.displayTitleForLetter(letterIndex);
    final isExtra = level?.extra == true;
    final host = c.characterForGuest(snap.lastPlayer) ?? kCoreRobocars.first;
    final hostLine = c.progressHostLine();
    final compact = MediaQuery.sizeOf(context).height < 560;

    return PixelScaffold(
      title: 'ТАБЛО',
      showCharacters: false,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 28,
              vertical: 6,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: PixelPanel(
                        padding: EdgeInsets.all(compact ? 14 : 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HostBanner(
                              character: host,
                              line: hostLine,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 12 : 18),
                            LetterProgressView(
                              completedLetters: snap.completedLetters,
                              currentLetterIndex: letterIndex,
                              celebrateLetter: _ritualFor,
                              celebration: _celebrate,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 12 : 18),
                            if (level != null)
                              _NextTeaserCard(
                                level: level,
                                levelLabel: levelLabel,
                                isExtra: isExtra,
                                compact: compact,
                              ),
                            SizedBox(height: compact ? 12 : 16),
                            _GuestReactionStrip(
                              controller: c,
                              guests: snap.guests,
                              lastPlayer: snap.lastPlayer,
                              bounce: _guestBounce,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 14 : 22),
                            TvButton(
                              label: 'ДАЛЬШЕ — КРУГ',
                              autofocus: true,
                              compact: compact,
                              onPressed: () => c.continueFromProgress(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_ritualFor != null)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(
                  painter: _ConfettiPainter(progress: _confetti.value),
                  size: Size.infinite,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HostBanner extends StatelessWidget {
  const _HostBanner({
    required this.character,
    required this.line,
    required this.compact,
  });

  final RobocarCharacter character;
  final String line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RobocarAvatar(character: character, size: compact ? 52 : 68),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: PoliColors.softWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PoliColors.hellyBlue, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.displayNameRu,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: compact ? 8 : 9,
                    color: PoliColors.hellyBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  line,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: compact ? 10 : 12,
                    height: 1.55,
                    color: PoliColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NextTeaserCard extends StatelessWidget {
  const _NextTeaserCard({
    required this.level,
    required this.levelLabel,
    required this.isExtra,
    required this.compact,
  });

  final LevelDefinition level;
  final String levelLabel;
  final bool isExtra;
  final bool compact;

  IconData get _icon {
    switch (level.type) {
      case LevelType.pictureQuestion:
        return Icons.image;
      case LevelType.videoQuestion:
        return Icons.videocam;
      case LevelType.audioQuestion:
        return Icons.music_note;
      case LevelType.minigame:
        return Icons.sports_esports;
    }
  }

  String get _typeLabel => LevelDefinition.typeLabel(level.type).toUpperCase();

  String get _teaser {
    if (isExtra) return 'Секретная миссия · гость из всего пула';
    final title = level.title.trim();
    return title.isEmpty ? levelLabel : title;
  }

  @override
  Widget build(BuildContext context) {
    final accent = isExtra ? PoliColors.hellyBlue : PoliColors.panelBorder;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: PoliColors.panelDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 3),
      ),
      child: Row(
        children: [
          Icon(_icon, color: PoliColors.robocarRed, size: compact ? 28 : 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExtra ? 'ДАЛЬШЕ · ЭКСТРА' : 'ДАЛЬШЕ · $levelLabel',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: compact ? 8 : 9,
                    color: PoliColors.robocarRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_typeLabel · $_teaser',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: compact ? 8 : 9,
                    height: 1.5,
                    color: PoliColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestReactionStrip extends StatelessWidget {
  const _GuestReactionStrip({
    required this.controller,
    required this.guests,
    required this.lastPlayer,
    required this.bounce,
    required this.compact,
  });

  final GameController controller;
  final List<String> guests;
  final String? lastPlayer;
  final Animation<double> bounce;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (guests.isEmpty) return const SizedBox.shrink();
    final size = compact ? 40.0 : 48.0;
    return AnimatedBuilder(
      animation: bounce,
      builder: (context, _) {
        return SizedBox(
          height: size + 18,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: guests.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final name = guests[i];
              final isLast = name == lastPlayer;
              final t = isLast ? bounce.value : 0.0;
              final scale = 1.0 + 0.14 * math.sin(t * math.pi);
              return Transform.translate(
                offset: Offset(0, isLast ? -6 * math.sin(t * math.pi) : 0),
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RobocarAvatar(
                        character: controller.characterForGuest(name),
                        size: size,
                      ),
                      if (isLast)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: PoliColors.mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rnd = math.Random(7);
    final colors = [
      PoliColors.robocarRed,
      PoliColors.amberYellow,
      PoliColors.hellyBlue,
      PoliColors.mint,
      const Color(0xFFAB47BC),
    ];
    for (var i = 0; i < 42; i++) {
      final x = rnd.nextDouble() * size.width;
      final startY = -20.0 - rnd.nextDouble() * 40;
      final y = startY + (size.height * 0.75) * progress + rnd.nextDouble() * 40;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1.0 - progress).clamp(0.0, 1.0),
        );
      final w = 5.0 + rnd.nextDouble() * 6;
      final h = 3.0 + rnd.nextDouble() * 4;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6 + i);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
