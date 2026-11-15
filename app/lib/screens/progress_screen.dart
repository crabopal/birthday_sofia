import 'package:material_ui/material_ui.dart';

import '../controllers/game_controller.dart';
import '../models/phrase.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_progress.dart';
import '../widgets/pixel_scaffold.dart';
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
        child: PixelPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LetterProgressView(
                completedLetters: snap.completedLetters,
                currentLetterIndex: letterIndex,
              ),
              const SizedBox(height: 24),
              Text(
                'Уровень: буква «$letter»',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: PoliColors.ink,
                ),
              ),
              if (level != null) ...[
                const SizedBox(height: 12),
                Text(
                  level.title,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    color: PoliColors.inkSoft,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              TvButton(
                label: 'ДАЛЬШЕ — КРУГ',
                autofocus: true,
                onPressed: () => controller.continueFromProgress(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
