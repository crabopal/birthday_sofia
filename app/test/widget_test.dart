import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/controllers/game_controller.dart';
import 'package:sonya_birthday/main.dart';
import 'package:sonya_birthday/models/level.dart';
import 'package:sonya_birthday/services/music_service.dart';
import 'package:sonya_birthday/services/voice_service.dart';

void main() {
  testWidgets('splash shows start button', (tester) async {
    final controller = GameController(
      voice: VoiceService()..disableForTests(),
      music: MusicService()..disableForTests(),
    );
    await tester.pumpWidget(SonyaBirthdayApp(controller: controller));
    // Splash runs OTA check; settle with a timeout-friendly pump loop.
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('СТАРТ').evaluate().isNotEmpty) break;
    }
    expect(find.text('СТАРТ'), findsOneWidget);
    expect(find.text('РЕДАКТОР'), findsOneWidget);
    expect(find.textContaining('СОНЯ'), findsOneWidget);
  });

  test('demo pack json shape via LevelDefinition', () {
    final level = LevelDefinition.fromJson({
      'id': 'L1',
      'letterIndex': 0,
      'type': 'picture_question',
      'title': 'Буква С',
      'question': 'q',
      'answer': 'a',
      'acceptedAnswers': ['a'],
      'imageAsset': 'assets/images/demo_car.png',
    });
    expect(level.type, LevelType.pictureQuestion);
  });
}
