import 'package:material_ui/material_ui.dart';

/// Bright daytime rescue-city palette (original art / kids rescue-cartoon mood).
class PoliColors {
  static const Color skyTop = Color(0xFF6BB8F0);
  static const Color skyBottom = Color(0xFFE8F6FF);
  static const Color panel = Color(0xFFFFF9EC);
  static const Color panelDeep = Color(0xFFFFF0D0);
  static const Color panelBorder = Color(0xFFFFC44D);
  static const Color ink = Color(0xFF1F2A37);
  static const Color inkSoft = Color(0xFF4A5564);
  static const Color robocarRed = Color(0xFFE53935);
  static const Color amberYellow = Color(0xFFFFC107);
  static const Color hellyBlue = Color(0xFF1E88E5);
  static const Color mint = Color(0xFF43A047);
  static const Color softWhite = Color(0xFFFFFDF8);
  static const Color focusRing = Color(0xFFFF8A00);
  static const Color letterDone = Color(0xFF43A047);
  static const Color letterTodo = Color(0xFFB0BEC5);
  static const Color letterActive = Color(0xFFE53935);

  // Aliases used across screens (kept for call-site stability).
  static const Color cream = ink;
  static const Color steel = inkSoft;
  static const Color beaconYellow = amberYellow;
  static const Color rescueBlue = hellyBlue;
  static const Color road = Color(0xFFFFE082);
  static const Color focus = focusRing;
  static const Color dimLetter = letterTodo;
  static const Color litLetter = letterDone;
  static const Color night = Color(0xFF263238);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: PoliColors.robocarRed,
        brightness: Brightness.light,
        primary: PoliColors.robocarRed,
        secondary: PoliColors.amberYellow,
        tertiary: PoliColors.hellyBlue,
        surface: PoliColors.panel,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: PoliColors.skyBottom,
      textTheme: base.textTheme.apply(
        bodyColor: PoliColors.ink,
        displayColor: PoliColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: PoliColors.ink,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PoliColors.robocarRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFB71C1C), width: 3),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PoliColors.ink,
          side: const BorderSide(color: PoliColors.panelBorder, width: 3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PoliColors.softWhite,
        hintStyle: const TextStyle(color: PoliColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PoliColors.panelBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PoliColors.focusRing, width: 3),
        ),
      ),
    );
  }

  /// Kept for any leftover references; maps to the bright theme.
  static ThemeData get dark => light;
}
