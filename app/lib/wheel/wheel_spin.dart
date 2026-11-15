import 'dart:math';

/// Wheel-of-fortune style landing: stop somewhere inside the target segment,
/// never exactly on the divider between slices.
class WheelSpinPlan {
  const WheelSpinPlan({
    required this.endTurns,
    required this.landingWithinSegment,
    required this.extraSpins,
  });

  final double endTurns;
  final double landingWithinSegment;
  final int extraSpins;
}

/// Builds a spin that brings a random interior point of [targetIndex] under
/// the top pointer (arrow at the top of the wheel).
///
/// Stop points: about [preferredStopsAroundWheel] around the full circle,
/// distributed into the winning segment (at least 3), with a margin from edges.
WheelSpinPlan planWheelSpin({
  required double currentTurns,
  required int targetIndex,
  required int segmentCount,
  Random? random,
  int minExtraSpins = 5,
  int maxExtraSpins = 7,
  int preferredStopsAroundWheel = 24,
}) {
  final rng = random ?? Random();
  final n = max(segmentCount, 1);
  final index = targetIndex.clamp(0, n - 1);
  final segment = 1.0 / n;

  // Keep clear of the black divider between slices.
  final edgeMargin = min(0.045, segment * 0.2);
  final usable = max(segment - 2 * edgeMargin, segment * 0.4);

  final stopsInSegment = max(3, (preferredStopsAroundWheel / n).ceil());
  final stopSlot = rng.nextInt(stopsInSegment);
  // Center of the chosen slot inside the usable band.
  final tWithin =
      edgeMargin + usable * ((stopSlot + 0.5) / stopsInSegment);

  // Fraction along the unrotated wheel: 0 = top, increases clockwise.
  final landingOnWheel = (index * segment + tWithin) % 1.0;

  // Clockwise rotation R moves point L to (L + R) mod 1; want that at top (0).
  final targetFrac = (1.0 - landingOnWheel) % 1.0;
  final currentFrac = currentTurns - currentTurns.floorToDouble();
  var delta = targetFrac - currentFrac;
  if (delta < 0.01) {
    // Always spin at least a little past a full turn if already aligned.
    delta += 1.0;
  }

  final extra =
      minExtraSpins + rng.nextInt(max(1, maxExtraSpins - minExtraSpins + 1));
  delta += extra;

  return WheelSpinPlan(
    endTurns: currentTurns + delta,
    landingWithinSegment: tWithin / segment,
    extraSpins: extra,
  );
}
