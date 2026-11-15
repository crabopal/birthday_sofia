import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/controllers/game_controller.dart';
import 'package:sonya_birthday/models/game_state.dart';
import 'package:sonya_birthday/models/level.dart';
import 'package:sonya_birthday/services/music_service.dart';
import 'package:sonya_birthday/services/voice_service.dart';

void main() {
  test('host line celebrates just-lit letter and greets on start', () async {
    final voice = VoiceService()..disableForTests();
    final music = MusicService()..disableForTests();
    final controller = GameController(voice: voice, music: music);
    controller.debugSetPack(
      LevelsPack(
        title: 't',
        voiceLines: const {},
        levels: [
          LevelDefinition(
            id: 'L1',
            letterIndex: 0,
            type: LevelType.pictureQuestion,
            title: 'Буква С',
            question: 'q',
            answer: 'a',
            acceptedAnswers: const ['a'],
            ready: true,
          ),
          LevelDefinition(
            id: 'L2',
            letterIndex: 1,
            type: LevelType.pictureQuestion,
            title: 'Буква Д',
            question: 'q',
            answer: 'a',
            acceptedAnswers: const ['a'],
            ready: true,
          ),
        ],
      ),
    );

    controller.addGuest('Аня');
    controller.addGuest('Боря');
    controller.startGame();
    expect(controller.progressHostLine(), contains('поздравление'));

    controller.finishSpin('Аня');
    await controller.completeCurrentLevel();
    controller.advanceAfterCorrect();
    expect(controller.snapshot.phase, GamePhase.progress);
    expect(controller.snapshot.justLitLetter, 0);
    expect(controller.snapshot.lastPlayer, 'Аня');
    expect(controller.progressHostLine(), contains('«С»'));
  });
}
