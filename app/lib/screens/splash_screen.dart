import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../widgets/scanlines.dart';
import '../widgets/tv_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'С ДНЕМ\nРОЖДЕНИЯ,\nСОНЯ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 36,
                    height: 1.55,
                    color: PoliColors.beaconYellow,
                    shadows: [
                      Shadow(color: PoliColors.robocarRed, offset: Offset(3, 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'пиксельная вечеринка · робокар ретро',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    color: PoliColors.steel.withValues(alpha: 0.95),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                TvButton(
                  label: 'СТАРТ',
                  autofocus: true,
                  onPressed: onStart,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Пульт: стрелки · OK · Back',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 9,
                    color: PoliColors.steel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
