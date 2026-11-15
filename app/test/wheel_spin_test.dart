import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/wheel/wheel_spin.dart';

void main() {
  test('landing stays inside target segment, away from borders', () {
    final rng = Random(7);
    for (final n in [2, 3, 5, 8]) {
      for (var index = 0; index < n; index++) {
        for (var trial = 0; trial < 40; trial++) {
          final plan = planWheelSpin(
            currentTurns: trial * 0.17,
            targetIndex: index,
            segmentCount: n,
            random: rng,
          );
          // Reconstruct where the top pointer hits on the wheel.
          final endFrac = plan.endTurns - plan.endTurns.floorToDouble();
          // Point under the top after rotation R: (-R) mod 1
          final underPointer = (1.0 - endFrac) % 1.0;
          final segment = 1.0 / n;
          final segStart = index * segment;
          final segEnd = (index + 1) * segment;
          expect(
            underPointer,
            greaterThan(segStart),
            reason: 'n=$n i=$index under=$underPointer',
          );
          expect(
            underPointer,
            lessThan(segEnd),
            reason: 'n=$n i=$index under=$underPointer',
          );
          // Not glued to the black divider.
          expect(underPointer - segStart, greaterThan(0.02));
          expect(segEnd - underPointer, greaterThan(0.02));
        }
      }
    }
  });

  test('two-guest wheel uses several distinct stop slots', () {
    final rng = Random(42);
    final slots = <int>{};
    for (var i = 0; i < 60; i++) {
      final plan = planWheelSpin(
        currentTurns: 0,
        targetIndex: 0,
        segmentCount: 2,
        random: rng,
      );
      // Map within-segment fraction to a coarse slot.
      slots.add((plan.landingWithinSegment * 12).floor());
    }
    expect(slots.length, greaterThanOrEqualTo(3));
  });
}
