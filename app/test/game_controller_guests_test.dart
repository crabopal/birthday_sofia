import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/controllers/game_controller.dart';
import 'package:sonya_birthday/services/voice_service.dart';

void main() {
  test('adding multiple guests keeps all names', () {
    final voice = VoiceService()..disableForTests();
    final controller = GameController(voice: voice);
    controller.addGuest('Аня');
    controller.addGuest('Боря');
    controller.addGuest('Вика');
    expect(controller.snapshot.guests, ['Аня', 'Боря', 'Вика']);
  });

  test('duplicate names are ignored', () {
    final voice = VoiceService()..disableForTests();
    final controller = GameController(voice: voice);
    controller.addGuest('Аня');
    controller.addGuest('аня');
    expect(controller.snapshot.guests, ['Аня']);
  });
}
