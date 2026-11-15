import 'dart:math';

/// Fair rotation: everyone plays once before the circle resets.
class FairQueue {
  FairQueue({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<String> _pool = [];
  final List<String> _remaining = [];

  List<String> get pool => List.unmodifiable(_pool);
  List<String> get remaining => List.unmodifiable(_remaining);

  void setGuests(List<String> guests) {
    _pool
      ..clear()
      ..addAll(guests.where((g) => g.trim().isNotEmpty));
    _reshuffle();
  }

  void _reshuffle() {
    _remaining
      ..clear()
      ..addAll(_pool);
    _remaining.shuffle(_random);
  }

  /// Names currently on the wheel. If the circle just ended, reshuffles first.
  List<String> peekWheelNames() {
    if (_pool.isEmpty) return const [];
    if (_remaining.isEmpty) {
      _reshuffle();
    }
    return List<String>.from(_remaining);
  }

  /// Full guest pool (for secret «экстра» levels).
  List<String> peekAllNames() {
    if (_pool.isEmpty) return const [];
    return List<String>.from(_pool);
  }

  /// Picks next guest and removes them until the circle is empty.
  String next() {
    if (_pool.isEmpty) {
      throw StateError('FairQueue has no guests');
    }
    if (_remaining.isEmpty) {
      _reshuffle();
    }
    return _remaining.removeAt(0);
  }

  /// Random guest from the whole pool; does not change the fair circle.
  String nextFromPool() {
    if (_pool.isEmpty) {
      throw StateError('FairQueue has no guests');
    }
    return _pool[_random.nextInt(_pool.length)];
  }
}
