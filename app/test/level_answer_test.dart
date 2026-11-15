import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/models/level.dart';

void main() {
  test('answer matching is case and space insensitive', () {
    const level = LevelDefinition(
      id: 't',
      letterIndex: 0,
      type: LevelType.pictureQuestion,
      title: 't',
      question: 'q',
      answer: 'Красный',
      acceptedAnswers: ['красный', 'red'],
    );

    expect(level.matchesAnswer('  КРАСНЫЙ '), isTrue);
    expect(level.matchesAnswer('Red'), isTrue);
    expect(level.matchesAnswer('синий'), isFalse);
  });
}
