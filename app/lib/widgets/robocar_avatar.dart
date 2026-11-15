import 'package:material_ui/material_ui.dart';

import '../models/robocar_character.dart';
import '../theme/app_theme.dart';

class RobocarAvatar extends StatelessWidget {
  const RobocarAvatar({
    super.key,
    required this.character,
    this.size = 56,
  });

  final RobocarCharacter? character;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: character == null
          ? const ColoredBox(
              color: PoliColors.panelDeep,
              child: Icon(Icons.directions_car, color: PoliColors.hellyBlue),
            )
          : Image.asset(
              character!.assetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: PoliColors.panelDeep,
                child: Icon(Icons.directions_car, color: PoliColors.robocarRed),
              ),
            ),
    );
  }
}
