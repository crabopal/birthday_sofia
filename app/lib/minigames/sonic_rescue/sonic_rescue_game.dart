import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../input/input_router.dart';
import '../../theme/app_theme.dart';
import 'sonic_world.dart';

enum SonicGamePhase { intro, playing, won }

/// Classic Sega-Sonic style side-scroller: short, forgiving, gamepad-first.
class SonicRescueGame extends StatefulWidget {
  const SonicRescueGame({
    super.key,
    required this.onWon,
    this.postyImage,
  });

  final VoidCallback onWon;
  final ui.Image? postyImage;

  @override
  State<SonicRescueGame> createState() => _SonicRescueGameState();
}

class _SonicRescueGameState extends State<SonicRescueGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final FocusNode _focus = FocusNode();
  final SonicWorld _world = SonicWorld();
  late SonicPlayer _player;

  Duration _last = Duration.zero;
  double _cameraX = 0;
  double _animT = 0;
  SonicGamePhase _phase = SonicGamePhase.intro;
  bool _wonNotified = false;

  bool _left = false;
  bool _right = false;
  bool _jumpQueued = false;

  // Forgiving Sega-like feel for non-gamers.
  static const double runAccel = 1400;
  static const double maxRun = 260;
  static const double friction = 900;
  static const double gravity = 980;
  static const double jumpV = -420;
  static const double airControl = 0.65;

  @override
  void initState() {
    super.initState();
    _player = SonicPlayer(x: 80, y: SonicWorld.groundY);
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!mounted) return;
    final clamped = dt.clamp(0.0, 1 / 30);
    if (_phase == SonicGamePhase.playing) {
      _step(clamped);
    }
    _animT += clamped;
    setState(() {});
  }

  void _start() {
    setState(() => _phase = SonicGamePhase.playing);
    _focus.requestFocus();
  }

  void _step(double dt) {
    // Horizontal
    final dir = (_right ? 1.0 : 0.0) - (_left ? 1.0 : 0.0);
    if (dir != 0) {
      _player.facingRight = dir > 0;
      final accel = _player.onGround ? runAccel : runAccel * airControl;
      _player.vx += dir * accel * dt;
      _player.vx = _player.vx.clamp(-maxRun, maxRun);
    } else if (_player.onGround) {
      if (_player.vx.abs() < 12) {
        _player.vx = 0;
      } else {
        final sign = _player.vx.sign;
        _player.vx -= sign * friction * dt;
        if (_player.vx.sign != sign) _player.vx = 0;
      }
    }

    // Jump
    if (_jumpQueued && _player.onGround) {
      _player.vy = jumpV;
      _player.onGround = false;
    }
    _jumpQueued = false;

    _player.vy += gravity * dt;

    // Move X then resolve
    _player.x += _player.vx * dt;
    _resolveHorizontal();

    // Move Y then resolve
    _player.y += _player.vy * dt;
    _resolveVertical();

    // Rings
    final body = _player.bounds;
    _world.rings.removeWhere((r) {
      final hit = (Offset(r.dx, r.dy) - body.center).distance < 28;
      if (hit) _player.rings += 1;
      return hit;
    });

    // Checkpoints
    for (final c in _world.checkpoints) {
      if ((Offset(_player.x, _player.y) - c).distance < 50) {
        _player.checkpoint = c;
      }
    }

    // Soft death
    if (_player.y > SonicWorld.deathY) {
      _player.respawn();
    }

    // Goal
    if (body.overlaps(_world.goal.inflate(-8))) {
      _phase = SonicGamePhase.won;
      if (!_wonNotified) {
        _wonNotified = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onWon();
        });
      }
    }

    // Camera follow
    final target = _player.x - 280;
    _cameraX += (target - _cameraX) * math.min(1.0, dt * 6);
    _cameraX = _cameraX.clamp(0.0, SonicWorld.worldWidth - 640);
  }

  void _resolveHorizontal() {
    // Slightly shorter hitbox so standing on a platform does not side-collide.
    final b = Rect.fromLTWH(_player.x - 16, _player.y - 34, 32, 30);
    for (final p in _world.platforms) {
      if (!b.overlaps(p)) continue;
      // Ignore floors we are standing on / landing onto.
      if (_player.y <= p.top + 4 && _player.y >= p.top - 8) continue;
      if (_player.vx > 0) {
        _player.x = p.left - 16;
      } else if (_player.vx < 0) {
        _player.x = p.right + 16;
      } else if (b.center.dx < p.center.dx) {
        _player.x = p.left - 16;
      } else {
        _player.x = p.right + 16;
      }
      _player.vx = 0;
    }
    _player.x = _player.x.clamp(18.0, SonicWorld.worldWidth - 18);
  }

  void _resolveVertical() {
    _player.onGround = false;
    var b = _player.bounds;
    for (final p in _world.platforms) {
      if (!b.overlaps(p)) continue;
      final overlapTop = b.bottom - p.top;
      final overlapBottom = p.bottom - b.top;
      if (_player.vy >= 0 && overlapTop <= 24 && b.bottom <= p.top + 24) {
        // Landing on top
        _player.y = p.top;
        _player.vy = 0;
        _player.onGround = true;
      } else if (_player.vy < 0 && overlapBottom < overlapTop) {
        // Hit ceiling
        _player.y = p.bottom + 36;
        _player.vy = 0;
      }
      b = _player.bounds;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    if (InputRouter.isLeft(key)) {
      if (isDown) _left = true;
      if (isUp) _left = false;
      return KeyEventResult.handled;
    }
    if (InputRouter.isRight(key)) {
      if (isDown) _right = true;
      if (isUp) _right = false;
      return KeyEventResult.handled;
    }
    if (InputRouter.isJump(event) && isDown && event is! KeyRepeatEvent) {
      if (_phase == SonicGamePhase.intro) {
        _start();
      } else if (_phase == SonicGamePhase.playing) {
        _jumpQueued = true;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            constraints.maxWidth / 640,
            constraints.maxHeight / 360,
          );
          final w = 640 * scale;
          final h = 360 * scale;
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _SonicPainter(
                      world: _world,
                      player: _player,
                      cameraX: _cameraX,
                      animT: _animT,
                      phase: _phase,
                      posty: widget.postyImage,
                    ),
                  ),
                  if (_phase == SonicGamePhase.intro) _introOverlay(),
                  if (_phase == SonicGamePhase.won) _winOverlay(),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Text(
                      _phase == SonicGamePhase.intro
                          ? '← → бег   ·   A / ↑ / ОК пробел прыжок'
                          : 'Кольца: ${_player.rings}   ·   Доберись до Пости!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 8 * scale.clamp(0.8, 1.4),
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
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
  }

  Widget _introOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _start,
      child: Container(
        color: const Color(0x99001833),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ЭКСТРА · СОНИК',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 16,
                color: Color(0xFF29B6F6),
                height: 1.5,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Соник оказался в городе робокаров!\nСпаси Пости из лап Эггмана.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 10,
                color: Colors.white,
                height: 1.7,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Нажми A / ОК пробел — старт',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 9,
                color: PoliColors.amberYellow,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _winOverlay() {
    return Container(
      color: const Color(0x880E3B1A),
      alignment: Alignment.center,
      child: const Text(
        'Пости спасён!',
        style: TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 18,
          color: Color(0xFFFFF59D),
        ),
      ),
    );
  }
}

class _SonicPainter extends CustomPainter {
  _SonicPainter({
    required this.world,
    required this.player,
    required this.cameraX,
    required this.animT,
    required this.phase,
    required this.posty,
  });

  final SonicWorld world;
  final SonicPlayer player;
  final double cameraX;
  final double animT;
  final SonicGamePhase phase;
  final ui.Image? posty;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 640;
    final sy = size.height / 360;
    canvas.scale(sx, sy);

    // Sky
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5BA8E8), Color(0xFFCFEFFF)],
      ).createShader(const Rect.fromLTWH(0, 0, 640, 360));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 360), sky);

    // Parallax city silhouettes
    final building = Paint()..color = const Color(0x55296BA8);
    for (var i = 0; i < 12; i++) {
      final bx = (i * 180.0 - cameraX * 0.25) % 720 - 40;
      final bh = 80.0 + (i % 4) * 28;
      canvas.drawRect(Rect.fromLTWH(bx, 360 - bh - 40, 90, bh), building);
    }

    canvas.save();
    canvas.translate(-cameraX * (640 / 640), 0);
    // Map world Y (540 design) into 360 view — keep ground near bottom.
    final yScale = 360 / SonicWorld.worldHeight;
    canvas.scale(1, yScale);

    _paintPlatforms(canvas);
    _paintRings(canvas);
    _paintGoal(canvas);
    _paintPlayer(canvas);

    canvas.restore();

    // Soft vignette frame
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 640, 360),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF1565C0),
    );
  }

  void _paintPlatforms(Canvas canvas) {
    final top = Paint()..color = const Color(0xFF66BB6A);
    final body = Paint()..color = const Color(0xFF8D6E63);
    final edge = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final p in world.platforms) {
      canvas.drawRect(p, body);
      canvas.drawRect(Rect.fromLTWH(p.left, p.top, p.width, 10), top);
      canvas.drawRect(p, edge);
      // Robocar road stripe on long ground
      if (p.width > 250 && p.top >= SonicWorld.groundY - 1) {
        final stripe = Paint()..color = const Color(0xFFFFF176);
        for (var x = p.left + 20; x < p.right - 20; x += 60) {
          canvas.drawRect(Rect.fromLTWH(x, p.top + 28, 28, 6), stripe);
        }
      }
    }
  }

  void _paintRings(Canvas canvas) {
    final bob = math.sin(animT * 6) * 3;
    for (final r in world.rings) {
      final c = Offset(r.dx, r.dy + bob);
      canvas.drawCircle(
        c,
        12,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(
        c,
        6,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
  }

  void _paintGoal(Canvas canvas) {
    final g = world.goal;
    // Eggman-ish red machine / cage
    canvas.drawRRect(
      RRect.fromRectAndRadius(g, const Radius.circular(6)),
      Paint()..color = const Color(0xFFC62828),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(g.left + 10, g.top + 16, g.width - 20, g.height - 28),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0x6633E0FF),
    );
    // Bars
    final bar = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 3;
    for (var i = 1; i <= 3; i++) {
      final x = g.left + i * g.width / 4;
      canvas.drawLine(Offset(x, g.top + 16), Offset(x, g.bottom - 12), bar);
    }
    // Eggman dome on top
    canvas.drawCircle(
      Offset(g.center.dx, g.top),
      22,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawCircle(
      Offset(g.center.dx, g.top - 2),
      12,
      Paint()..color = const Color(0xFFFFCC80),
    );
    // Posty inside
    final postyRect = Rect.fromCenter(
      center: Offset(g.center.dx, g.center.dy + 8),
      width: 48,
      height: 48,
    );
    if (posty != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        posty!.width.toDouble(),
        posty!.height.toDouble(),
      );
      canvas.drawImageRect(posty!, src, postyRect, Paint());
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(postyRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFFFEB3B),
      );
    }
    // Help label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'ПОСТИ',
        style: TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 8,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(g.center.dx - tp.width / 2, g.top - 36));
  }

  void _paintPlayer(Canvas canvas) {
    final p = player;
    final cx = p.x;
    final cy = p.y - 18;
    canvas.save();
    canvas.translate(cx, cy);
    if (!p.facingRight) canvas.scale(-1, 1);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 18), width: 28, height: 8),
      Paint()..color = const Color(0x33000000),
    );

    // Body (blue hedgehog)
    canvas.drawCircle(
      const Offset(0, 0),
      16,
      Paint()..color = const Color(0xFF1E88E5),
    );
    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 4), width: 16, height: 14),
      Paint()..color = const Color(0xFFFFF8E1),
    );
    // Spikes
    final spike = Paint()..color = const Color(0xFF1565C0);
    final path = Path()
      ..moveTo(-6, -10)
      ..lineTo(-18, -22)
      ..lineTo(-2, -14)
      ..lineTo(-10, -28)
      ..lineTo(4, -14)
      ..lineTo(2, -24)
      ..lineTo(10, -10)
      ..close();
    canvas.drawPath(path, spike);
    // Eye
    canvas.drawCircle(
      const Offset(6, -2),
      5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(7, -2),
      2.2,
      Paint()..color = Colors.black,
    );
    // Shoes
    final shoe = Paint()..color = const Color(0xFFE53935);
    final run = math.sin(animT * (p.onGround && p.vx.abs() > 20 ? 14 : 0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-6, 14 + run * 2), width: 12, height: 8),
        const Radius.circular(3),
      ),
      shoe,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(6, 14 - run * 2), width: 12, height: 8),
        const Radius.circular(3),
      ),
      shoe,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SonicPainter old) => true;
}
