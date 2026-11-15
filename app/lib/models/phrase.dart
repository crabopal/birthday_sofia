/// Progress phrase from the party mockup: three visual lines.
class PhraseLayout {
  static const List<String> lines = [
    'С ДНЕМ',
    'РОЖДЕНИЯ,',
    'СОНЯ',
  ];

  /// Letter-only sequence (spaces and comma are decorative).
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
    'С',
    'О',
    'Н',
    'Я',
  ];

  static int get letterCount => letters.length;

  /// Maps each character in [lines] to a letter index, or null for decoration.
  static List<List<int?>> get letterIndexGrid {
    var letterIndex = 0;
    return lines.map((line) {
      return line.split('').map((ch) {
        if (ch == ' ' || ch == ',') return null;
        final idx = letterIndex;
        letterIndex++;
        return idx;
      }).toList();
    }).toList();
  }
}
