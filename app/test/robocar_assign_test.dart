import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/models/robocar_character.dart';

void main() {
  test('≤4 guests get core order Поли→Рой→Эмбер→Хэлли', () {
    final map = assignRobocarsToGuests(['Аня', 'Боря', 'Вика', 'Глеб']);
    expect(map['Аня'], 'poli');
    expect(map['Боря'], 'roy');
    expect(map['Вика'], 'amber');
    expect(map['Глеб'], 'helly');
  });

  test('2 guests get Poli then Roy', () {
    final map = assignRobocarsToGuests(['Аня', 'Боря']);
    expect(map.values.toList(), ['poli', 'roy']);
  });

  test('>4 guests always include core four', () {
    final guests = ['A', 'B', 'C', 'D', 'E', 'F'];
    final map = assignRobocarsToGuests(guests, random: Random(42));
    final ids = map.values.toSet();
    expect(ids.contains('poli'), isTrue);
    expect(ids.contains('roy'), isTrue);
    expect(ids.contains('amber'), isTrue);
    expect(ids.contains('helly'), isTrue);
    expect(map.length, 6);
  });

  test('label format', () {
    final c = kCoreRobocars.first;
    expect(c.labelForGuest('Соня'), 'Поли (Соня)');
  });
}
