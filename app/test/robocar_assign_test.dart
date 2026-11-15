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

  test('5th guest gets unused extra; first four stay fixed', () {
    var map = assignRobocarsToGuests(['A', 'B', 'C', 'D']);
    map = assignRobocarsToGuests(
      ['A', 'B', 'C', 'D', 'E'],
      existing: map,
      random: Random(7),
    );
    expect(map['A'], 'poli');
    expect(map['B'], 'roy');
    expect(map['C'], 'amber');
    expect(map['D'], 'helly');
    expect(map['E'], isNot(anyOf('poli', 'roy', 'amber', 'helly')));
    expect(map.values.toSet().length, 5);
  });

  test('adding guests one-by-one never reshuffles earlier assignments', () {
    Map<String, String> map = {};
    final names = ['A', 'B', 'C', 'D', 'E', 'F'];
    for (var i = 0; i < names.length; i++) {
      final next = names.sublist(0, i + 1);
      map = assignRobocarsToGuests(next, existing: map, random: Random(1));
    }
    expect(map['A'], 'poli');
    expect(map['B'], 'roy');
    expect(map['C'], 'amber');
    expect(map['D'], 'helly');
    expect(map.values.toSet().length, 6);
  });

  test('removing a guest frees character but does not reshuffle others', () {
    var map = assignRobocarsToGuests(['A', 'B', 'C', 'D', 'E'], random: Random(3));
    final keptE = map['E'];
    map = assignRobocarsToGuests(['A', 'B', 'D', 'E'], existing: map);
    expect(map['A'], 'poli');
    expect(map['B'], 'roy');
    expect(map['D'], 'helly');
    expect(map['E'], keptE);
    expect(map.containsKey('C'), isFalse);
  });

  test('no duplicate character ids among current guests', () {
    final map = assignRobocarsToGuests(
      List.generate(10, (i) => 'G$i'),
      random: Random(99),
    );
    expect(map.values.toSet().length, map.length);
  });

  test('label format', () {
    final c = kCoreRobocars.first;
    expect(c.labelForGuest('Соня'), 'Поли (Соня)');
  });
}
