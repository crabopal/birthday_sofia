import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../models/robocar_character.dart';
import '../theme/app_theme.dart';
import '../widgets/robocar_avatar.dart';
import 'wheel_spin.dart';

class ParticipantWheel extends StatelessWidget {
  const ParticipantWheel({
    super.key,
    required this.names,
    required this.rotationTurns,
    this.labels,
    this.winner,
    this.winnerAvatar,
  });

  final List<String> names;
  final List<String>? labels;
  final double rotationTurns;
  final String? winner;
  final RobocarCharacter? winnerAvatar;

  @override
  Widget build(BuildContext context) {
    final segmentLabels = labels ?? names;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotationTurns * 2 * pi,
            child: CustomPaint(
              painter: _WheelPainter(names: segmentLabels),
              child: const SizedBox.expand(),
            ),
          ),
          // Pointer at the top — classic «Поле чудес» / wheel-of-fortune.
          const Positioned(
            top: 0,
            child: Icon(
              Icons.arrow_drop_down,
              size: 56,
              color: Colors.black,
            ),
          ),
          if (winner != null)
            Positioned(
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: PoliColors.panel.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PoliColors.robocarRed, width: 3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (winnerAvatar != null) ...[
                      RobocarAvatar(character: winnerAvatar, size: 40),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      winner!,
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 11,
                        color: PoliColors.robocarRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.names});

  final List<String> names;

  static const _palette = [
    Color(0xFFE63946),
    Color(0xFF4CC9F0),
    Color(0xFFFFD166),
    Color(0xFF2A9D8F),
    Color(0xFFF4A261),
    Color(0xFF9B5DE5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final n = max(names.length, 1);
    final sweep = 2 * pi / n;

    for (var i = 0; i < n; i++) {
      // 0 at top (-pi/2), then clockwise — matches spin math in wheel_spin.dart.
      final start = -pi / 2 + i * sweep;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _palette[i % _palette.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );

      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = PoliColors.night;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        border,
      );

      if (names.isNotEmpty) {
        final mid = start + sweep / 2;
        final labelRadius = radius * 0.62;
        final pos = Offset(
          center.dx + cos(mid) * labelRadius,
          center.dy + sin(mid) * labelRadius,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: _short(names[i]),
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 10,
              color: PoliColors.night,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: radius * 0.5);
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    canvas.drawCircle(center, 18, Paint()..color = PoliColors.night);
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = PoliColors.amberYellow,
    );
  }

  String _short(String name) {
    if (name.length <= 8) return name;
    return '${name.substring(0, 7)}.';
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.names != names;
}

/// Spins so the top pointer lands inside [targetIndex], not on a divider.
Future<void> animateWheelToIndex({
  required AnimationController controller,
  required ValueNotifier<double> turns,
  required int targetIndex,
  required int segmentCount,
  Random? random,
}) async {
  final plan = planWheelSpin(
    currentTurns: turns.value,
    targetIndex: targetIndex,
    segmentCount: segmentCount,
    random: random,
  );

  final anim = Tween<double>(begin: turns.value, end: plan.endTurns).animate(
    CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
  );
  void listener() => turns.value = anim.value;
  anim.addListener(listener);
  controller
    ..duration = Duration(milliseconds: 3800 + Random().nextInt(800))
    ..reset();
  await controller.forward();
  anim.removeListener(listener);
  // Snap exactly to planned end (avoid float drift on the border).
  turns.value = plan.endTurns;
}
