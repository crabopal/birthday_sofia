import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/controllers/game_controller.dart';
import 'package:sonya_birthday/main.dart';
import 'package:sonya_birthday/models/level.dart';

void main() {
  testWidgets('splash shows start button', (tester) async {
    final controller = GameController();
    // Inject empty pack so we don't need asset bundle in this smoke test path
    // after going past splash; splash itself does not need pack.
    await tester.pumpWidget(SonyaBirthdayApp(controller: controller));
    await tester.pumpAndSettle();
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
