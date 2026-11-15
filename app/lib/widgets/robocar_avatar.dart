import 'package:material_ui/material_ui.dart';

import '../models/robocar_character.dart';
import '../theme/app_theme.dart';
import 'char_portrait_frame.dart';

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
    return CharPortraitFrame(
      size: size,
      borderWidth: 2,
      radiusFactor: 0.18,
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
