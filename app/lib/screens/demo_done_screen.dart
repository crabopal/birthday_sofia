import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_progress.dart';
import '../widgets/scanlines.dart';
import '../widgets/tv_button.dart';

class DemoDoneScreen extends StatelessWidget {
  const DemoDoneScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _body(),
    );
  }

  Widget _body() {
    final snap = controller.snapshot;

    return PixelScaffold(
      title: 'ДЕМО ПРОЙДЕНО',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LetterProgressView(
              completedLetters: snap.completedLetters,
              currentLetterIndex: null,
              showArrow: false,
            ),
            const SizedBox(height: 28),
            const Text(
              'Три демо-уровня сыграны.\nОстальные буквы ждут контент.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 12,
                height: 1.7,
                color: PoliColors.cream,
              ),
            ),
            const SizedBox(height: 36),
            TvButton(
              label: 'СНОВА В ЛОББИ',
              autofocus: true,
              onPressed: () => controller.restart(),
            ),
          ],
        ),
      ),
    );
  }
}
