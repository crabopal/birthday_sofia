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

/// Core four always in the pool, in this order when guest count ≤ 4.
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

/// Assign characters to [guests].
///
/// • ≤4 guests → fixed core order: Поли, Рой, Эмбер, Хэлли.
/// • >4 guests → pool = core four + random extras; then shuffled onto guests.
Map<String, String> assignRobocarsToGuests(
  List<String> guests, {
  Random? random,
}) {
  final rng = random ?? Random();
  final n = guests.length;
  if (n == 0) return {};

  final List<RobocarCharacter> chosen;
  if (n <= kCoreRobocars.length) {
    chosen = kCoreRobocars.take(n).toList();
  } else {
    final extras = List<RobocarCharacter>.from(kExtraRobocars)..shuffle(rng);
    final need = n - kCoreRobocars.length;
    chosen = [
      ...kCoreRobocars,
      ...extras.take(need.clamp(0, extras.length)),
    ];
    var i = 0;
    while (chosen.length < n) {
      chosen.add(extras[i % extras.length]);
      i++;
    }
    chosen.shuffle(rng);
  }

  final map = <String, String>{};
  for (var i = 0; i < n; i++) {
    map[guests[i]] = chosen[i].id;
  }
  return map;
}
