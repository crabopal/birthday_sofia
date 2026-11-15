import 'dart:ui';

/// Simple AABB platformer world for the Sonic rescue mini-level.
/// Designed for ~1–2 minutes and adults with no game experience:
/// continuous ground path, optional upper pads for rings, soft pit respawn.
class SonicWorld {
  SonicWorld() {
    platforms = _buildPlatforms();
    rings = _buildRings();
    checkpoints = const [
      Offset(80, groundY),
      Offset(900, groundY),
      Offset(1700, groundY),
      Offset(2500, groundY),
    ];
  }

  static const double worldWidth = 3000;
  static const double worldHeight = 540;
  static const double groundY = 460;

  late final List<Rect> platforms;
  late final List<Offset> rings;
  late final List<Offset> checkpoints;

  /// Cage holding Posty (goal).
  final Rect goal = const Rect.fromLTWH(2780, groundY - 120, 100, 120);

  /// Soft pits: falling below this Y respawns.
  static const double deathY = 620;

  static List<Rect> _buildPlatforms() {
    return const [
      // Main walkable road — almost continuous, one tiny practice gap.
      Rect.fromLTWH(0, groundY, 1050, 80),
      // ~80px gap (easy jump at walking/run speed)
      Rect.fromLTWH(1130, groundY, 900, 80),
      // Optional upper pads (rings); ground below stays safe
      Rect.fromLTWH(1280, groundY - 80, 160, 28),
      Rect.fromLTWH(1500, groundY - 80, 160, 28),
      // Optional step pads over the road (thin — walk underneath on ground)
      Rect.fromLTWH(2050, groundY - 40, 130, 28),
      Rect.fromLTWH(2160, groundY - 80, 150, 28),
      // Road continues under/after the pads
      Rect.fromLTWH(2100, groundY, 900, 80),
    ];
  }

  static List<Offset> _buildRings() {
    return const [
      Offset(200, groundY - 50),
      Offset(340, groundY - 50),
      Offset(480, groundY - 50),
      Offset(720, groundY - 50),
      Offset(1080, groundY - 50),
      Offset(1360, groundY - 130),
      Offset(1580, groundY - 130),
      Offset(1800, groundY - 50),
      Offset(2220, groundY - 120),
      Offset(2500, groundY - 50),
      Offset(2650, groundY - 50),
    ];
  }
}

class SonicPlayer {
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  bool onGround = false;
  bool facingRight = true;
  int rings = 0;
  Offset checkpoint;

  SonicPlayer({required this.x, required this.y})
      : checkpoint = Offset(x, y);

  Rect get bounds => Rect.fromLTWH(x - 18, y - 36, 36, 36);

  void respawn() {
    x = checkpoint.dx;
    y = checkpoint.dy;
    vx = 0;
    vy = 0;
    onGround = false;
  }
}
