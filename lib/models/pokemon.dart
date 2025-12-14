import 'pokemon_ability.dart';

class Pokemon {
  final String name;
  final String spriteUrl;
  final List<String> types;
  final List<PokemonAbility> abilities;
  final Map<String, int> stats; // stat name -> base_stat

  Pokemon({
    required this.name,
    required this.spriteUrl,
    required this.types,
    required this.abilities,
    required this.stats,
  });

  factory Pokemon.fromApi({required Map<String, dynamic> json, required List<PokemonAbility> abilities}) {
    final name = json['name'] ?? '';
    final spriteUrl = json['sprites'] != null ? json['sprites']['front_default'] ?? '' : '';

    final types = <String>[];
    if (json['types'] != null) {
      for (final t in json['types']) {
        if (t['type'] != null && t['type']['name'] != null) {
          types.add(t['type']['name']);
        }
      }
    }

    final stats = <String, int>{};
    if (json['stats'] != null) {
      for (final s in json['stats']) {
        final statName = s['stat'] != null ? s['stat']['name'] ?? '' : '';
        final base = s['base_stat'] ?? 0;
        if (statName.isNotEmpty) stats[statName] = base as int;
      }
    }

    return Pokemon(
      name: name,
      spriteUrl: spriteUrl ?? '',
      types: types,
      abilities: abilities,
      stats: stats,
    );
  }
}
