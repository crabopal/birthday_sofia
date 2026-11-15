/// Progress phrase from the party mockup: three visual lines.
class PhraseLayout {
  static const List<String> lines = [
    'С ДНЕМ',
    'РОЖДЕНИЯ,',
    'СОНЯ',
  ];

  /// Playable slots in order. Spaces stay decorative; comma is a real slot
  /// (secret «экстра» mini-game).
  static const List<String> letters = [
    'С',
    'Д',
    'Н',
    'Е',
    'М',
    'Р',
    'О',
    'Ж',
    'Д',
    'Е',
    'Н',
    'И',
    'Я',
    ',',
    'С',
    'О',
    'Н',
    'Я',
  ];

  /// Letter index of the comma / secret extra level.
  static const int commaLetterIndex = 13;

  static int get letterCount => letters.length;

  static bool isExtraLetter(int index) => index == commaLetterIndex;

  static String displayTitleForLetter(int index) {
    if (index < 0 || index >= letters.length) return '?';
    final ch = letters[index];
    if (ch == ',') return 'Экстра · запятая';
    return 'Буква $ch';
  }

  /// Maps each character in [lines] to a letter index, or null for decoration.
  static List<List<int?>> get letterIndexGrid {
    var letterIndex = 0;
    return lines.map((line) {
      return line.split('').map((ch) {
        if (ch == ' ') return null;
        final idx = letterIndex;
        letterIndex++;
        return idx;
      }).toList();
    }).toList();
  }
}
