import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class ParticipantWheel extends StatelessWidget {
  const ParticipantWheel({
    super.key,
    required this.names,
    required this.rotationTurns,
    this.winner,
  });

  final List<String> names;
  final double rotationTurns;
  final String? winner;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotationTurns * 2 * pi,
            child: CustomPaint(
              painter: _WheelPainter(names: names),
              child: const SizedBox.expand(),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 48, color: PoliColors.beaconYellow),
          if (winner != null)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: PoliColors.night.withValues(alpha: 0.9),
                  border: Border.all(color: PoliColors.beaconYellow, width: 2),
                ),
                child: Text(
                  winner!,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 14,
                    color: PoliColors.beaconYellow,
                  ),
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
        ..strokeWidth = 2
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
        ..color = PoliColors.beaconYellow,
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

/// Spins the wheel so the pointer (top) lands on [targetIndex].
Future<void> animateWheelToIndex({
  required AnimationController controller,
  required ValueNotifier<double> turns,
  required int targetIndex,
  required int segmentCount,
}) async {
  final n = max(segmentCount, 1);
  final segment = 1.0 / n;
  // Pointer is at top; segment 0 center is at top initially.
  final targetCenter = targetIndex * segment;
  final extraSpins = 4 + Random().nextInt(2);
  final endTurns = extraSpins + (1 - targetCenter);
  final anim = Tween<double>(begin: turns.value, end: turns.value + endTurns)
      .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  void listener() => turns.value = anim.value;
  anim.addListener(listener);
  controller
    ..duration = const Duration(milliseconds: 3200)
    ..reset();
  await controller.forward();
  anim.removeListener(listener);
}
