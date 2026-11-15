import 'dart:math';

/// Robocar Poli cast used as guest avatars (private party, original pixel redraws).
class RobocarCharacter {
  const RobocarCharacter({
    required this.id,
    required this.displayNameRu,
    required this.assetPath,
    this.core = false,
  });

  final String id;
  final String displayNameRu;
  final String assetPath;
  final bool core;

  String labelForGuest(String guestName) => '$displayNameRu ($guestName)';
}

/// Core four always in the pool, in this order for the first four guests.
const List<RobocarCharacter> kCoreRobocars = [
  RobocarCharacter(
    id: 'poli',
    displayNameRu: 'Поли',
    assetPath: 'assets/images/chars/poli.jpg',
    core: true,
  ),
  RobocarCharacter(
    id: 'roy',
    displayNameRu: 'Рой',
    assetPath: 'assets/images/chars/roy.jpg',
    core: true,
  ),
  RobocarCharacter(
    id: 'amber',
    displayNameRu: 'Эмбер',
    assetPath: 'assets/images/chars/amber.jpg',
    core: true,
  ),
  RobocarCharacter(
    id: 'helly',
    displayNameRu: 'Хэлли',
    assetPath: 'assets/images/chars/helly.jpg',
    core: true,
  ),
];

const List<RobocarCharacter> kExtraRobocars = [
  RobocarCharacter(
    id: 'cleany',
    displayNameRu: 'Клини',
    assetPath: 'assets/images/chars/cleany.jpg',
  ),
  RobocarCharacter(
    id: 'posty',
    displayNameRu: 'Пости',
    assetPath: 'assets/images/chars/posty.jpg',
  ),
  RobocarCharacter(
    id: 'spooky',
    displayNameRu: 'Спуки',
    assetPath: 'assets/images/chars/spooky.jpg',
  ),
  RobocarCharacter(
    id: 'capi',
    displayNameRu: 'Кэпи',
    assetPath: 'assets/images/chars/capi.jpg',
  ),
  RobocarCharacter(
    id: 'bruner',
    displayNameRu: 'Брунер',
    assetPath: 'assets/images/chars/bruner.jpg',
  ),
  RobocarCharacter(
    id: 'micky',
    displayNameRu: 'Микки',
    assetPath: 'assets/images/chars/micky.jpg',
  ),
  RobocarCharacter(
    id: 'dumpoo',
    displayNameRu: 'Дампу',
    assetPath: 'assets/images/chars/dumpoo.jpg',
  ),
  RobocarCharacter(
    id: 'max',
    displayNameRu: 'Макс',
    assetPath: 'assets/images/chars/max.jpg',
  ),
  RobocarCharacter(
    id: 'poke',
    displayNameRu: 'Пок',
    assetPath: 'assets/images/chars/poke.jpg',
  ),
];

List<RobocarCharacter> get kAllRobocars => [...kCoreRobocars, ...kExtraRobocars];

RobocarCharacter? robocarById(String id) {
  for (final c in kAllRobocars) {
    if (c.id == id) return c;
  }
  return null;
}

/// Assign characters to [guests] without reshuffling existing ones.
///
/// • Guests already in [existing] keep the same character id.
/// • First four *new* slots (guest index 0..3 with no prior id) get the
///   fixed core order: Поли → Рой → Эмбер → Хэлли (if still free).
/// • Later new guests pick a random unused character from the full pool.
/// • Characters never repeat while still assigned to a current guest.
Map<String, String> assignRobocarsToGuests(
  List<String> guests, {
  Map<String, String>? existing,
  Random? random,
}) {
  final rng = random ?? Random();
  final map = <String, String>{};
  final used = <String>{};

  // Keep sticky assignments for guests that are still present.
  for (final guest in guests) {
    final prev = existing?[guest];
    if (prev != null && robocarById(prev) != null && !used.contains(prev)) {
      map[guest] = prev;
      used.add(prev);
    }
  }

  for (var i = 0; i < guests.length; i++) {
    final guest = guests[i];
    if (map.containsKey(guest)) continue;

    String? pick;
    if (i < kCoreRobocars.length) {
      final coreId = kCoreRobocars[i].id;
      if (!used.contains(coreId)) pick = coreId;
    }
    pick ??= _pickUnused(used, rng);
    if (pick == null) continue;

    map[guest] = pick;
    used.add(pick);
  }

  return map;
}

String? _pickUnused(Set<String> used, Random rng) {
  final free = kAllRobocars.where((c) => !used.contains(c.id)).toList();
  if (free.isEmpty) return null;
  // Prefer extras when available so late guests feel like "bonus" cast.
  final extrasFree = free.where((c) => !c.core).toList();
  final pool = extrasFree.isNotEmpty ? extrasFree : free;
  return pool[rng.nextInt(pool.length)].id;
}
