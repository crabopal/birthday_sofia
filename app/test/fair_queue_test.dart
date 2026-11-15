import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/wheel/fair_queue.dart';

void main() {
  test('everyone appears once before reshuffle', () {
    final queue = FairQueue(random: Random(1));
    queue.setGuests(['Аня', 'Боря', 'Вика']);

    final firstCircle = [queue.next(), queue.next(), queue.next()];
    expect(firstCircle.toSet(), {'Аня', 'Боря', 'Вика'});

    final second = queue.next();
    expect(['Аня', 'Боря', 'Вика'], contains(second));
  });

  test('peekWheelNames then next keeps same circle order', () {
    final queue = FairQueue(random: Random(42));
    queue.setGuests(['A', 'B', 'C', 'D']);
    final names = queue.peekWheelNames();
    expect(names.length, 4);
    final winner = queue.next();
    expect(names.contains(winner), isTrue);
    expect(queue.remaining.length, 3);
    expect(queue.remaining.contains(winner), isFalse);
  });
}
