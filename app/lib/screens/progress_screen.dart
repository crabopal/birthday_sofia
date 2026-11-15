import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../models/phrase.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_progress.dart';
import '../widgets/scanlines.dart';
import '../widgets/tv_button.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.controller});

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
    final level = controller.currentLevel;
    final letterIndex = level?.letterIndex ?? snap.currentLevelIndex;
    final letter = letterIndex < PhraseLayout.letters.length
        ? PhraseLayout.letters[letterIndex]
        : '?';

    return PixelScaffold(
      title: 'ПРОГРЕСС',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LetterProgressView(
              completedLetters: snap.completedLetters,
              currentLetterIndex: letterIndex,
            ),
            const SizedBox(height: 28),
            Text(
              'Уровень: буква «$letter»',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 12,
                color: PoliColors.cream,
              ),
            ),
            if (level != null) ...[
              const SizedBox(height: 12),
              Text(
                level.title,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: PoliColors.steel,
                ),
              ),
            ],
            const SizedBox(height: 36),
            TvButton(
              label: 'ДАЛЬШЕ — КРУГ',
              autofocus: true,
              onPressed: () => controller.continueFromProgress(),
            ),
          ],
        ),
      ),
    );
  }
}
