import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/minigames/sonic_rescue/sonic_world.dart';

/// Headless physics twin — proves a simple right-runner can finish.
void main() {
  test('auto-runner reaches Posty cage without soft-lock', () {
    final world = SonicWorld();
    final player = SonicPlayer(x: 80, y: SonicWorld.groundY);

    const dt = 1 / 60.0;
    const maxRun = 260.0;
    const runAccel = 1400.0;
    const gravity = 980.0;
    const jumpV = -420.0;
    var won = false;
    var frames = 0;

    while (frames < 60 * 90) {
      player.vx = (player.vx + runAccel * dt).clamp(0.0, maxRun);

      final probe = player.x + 55;
      final floorHere = _floorAt(world, player.x, player.y);
      final floorAhead = _floorAt(world, probe, player.y);
      final needJump = floorHere != null && floorAhead == null;
      if (player.onGround && needJump) {
        player.vy = jumpV;
        player.onGround = false;
      }

      player.vy += gravity * dt;
      player.x += player.vx * dt;
      _resolveH(player, world);
      player.y += player.vy * dt;
      _resolveV(player, world);

      for (final c in world.checkpoints) {
        if ((Offset(player.x, player.y) - c).distance < 50) {
          player.checkpoint = c;
        }
      }
      if (player.y > SonicWorld.deathY) player.respawn();

      if (player.bounds.overlaps(world.goal.inflate(-8))) {
        won = true;
        break;
      }
      frames++;
    }

    expect(won, isTrue, reason: 'agent should finish within 90s sim time');
    expect(frames / 60.0, lessThan(45));
  });
}

double? _floorAt(SonicWorld world, double x, double y) {
  double? best;
  for (final p in world.platforms) {
    if (x < p.left || x > p.right) continue;
    // Prefer the main road / near feet, ignore high pads for "need jump".
    if ((p.top - y).abs() <= 8) {
      best = p.top;
    }
  }
  return best;
}

void _resolveH(SonicPlayer player, SonicWorld world) {
  final b = Rect.fromLTWH(player.x - 16, player.y - 34, 32, 30);
  for (final p in world.platforms) {
    if (!b.overlaps(p)) continue;
    if (player.y <= p.top + 4 && player.y >= p.top - 8) continue;
    if (player.vx > 0) player.x = p.left - 16;
    player.vx = 0;
  }
  player.x = player.x.clamp(18.0, SonicWorld.worldWidth - 18);
}

void _resolveV(SonicPlayer player, SonicWorld world) {
  player.onGround = false;
  var b = player.bounds;
  for (final p in world.platforms) {
    if (!b.overlaps(p)) continue;
    final overlapTop = b.bottom - p.top;
    if (player.vy >= 0 && overlapTop <= 24 && b.bottom <= p.top + 24) {
      player.y = p.top;
      player.vy = 0;
      player.onGround = true;
    } else if (player.vy < 0) {
      player.y = p.bottom + 36;
      player.vy = 0;
    }
    b = player.bounds;
  }
}
