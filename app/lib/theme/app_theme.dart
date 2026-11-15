import 'package:material_ui/material_ui.dart';

/// Poli Robocar–inspired retro palette (original, not licensed art).
class PoliColors {
  static const Color asphalt = Color(0xFF12161F);
  static const Color night = Color(0xFF0B1020);
  static const Color road = Color(0xFF1C2433);
  static const Color robocarRed = Color(0xFFE63946);
  static const Color beaconYellow = Color(0xFFFFD166);
  static const Color rescueBlue = Color(0xFF4CC9F0);
  static const Color steel = Color(0xFF8D99AE);
  static const Color cream = Color(0xFFF8F4EC);
  static const Color focus = Color(0xFFFFD166);
  static const Color dimLetter = Color(0xFF3A4154);
  static const Color litLetter = Color(0xFFFFD166);
}

class AppTheme {
  static ThemeData get dark {
    const font = 'PressStart2P';
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: font,
      scaffoldBackgroundColor: PoliColors.asphalt,
      colorScheme: const ColorScheme.dark(
        primary: PoliColors.robocarRed,
        secondary: PoliColors.beaconYellow,
        surface: PoliColors.road,
        onPrimary: PoliColors.cream,
        onSecondary: PoliColors.night,
        onSurface: PoliColors.cream,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: font,
        bodyColor: PoliColors.cream,
        displayColor: PoliColors.cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PoliColors.night,
        foregroundColor: PoliColors.cream,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PoliColors.road,
        hintStyle: TextStyle(
          color: PoliColors.steel.withValues(alpha: 0.8),
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: PoliColors.steel, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: PoliColors.beaconYellow, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PoliColors.robocarRed,
          foregroundColor: PoliColors.cream,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(fontFamily: font, fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}
