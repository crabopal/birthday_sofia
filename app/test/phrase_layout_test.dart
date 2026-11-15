import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/models/phrase.dart';

void main() {
  test('comma is a playable letter slot before СОНЯ', () {
    expect(PhraseLayout.letterCount, 18);
    expect(PhraseLayout.letters[PhraseLayout.commaLetterIndex], ',');
    expect(PhraseLayout.letters.sublist(14), ['С', 'О', 'Н', 'Я']);
    expect(PhraseLayout.isExtraLetter(13), isTrue);
    expect(PhraseLayout.displayTitleForLetter(13), contains('Экстра'));

    final flat = PhraseLayout.letterIndexGrid
        .expand((line) => line)
        .whereType<int>()
        .toList();
    expect(flat.length, 18);
    expect(flat[13], PhraseLayout.commaLetterIndex);
  });
}
