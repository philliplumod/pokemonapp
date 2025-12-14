class PokemonAbility {
  final String name;
  final String url;
  final String shortEffect;
  final String effect;

  PokemonAbility({
    required this.name,
    required this.url,
    required this.shortEffect,
    required this.effect,
  });

  factory PokemonAbility.fromApi({required Map<String, dynamic> json}) {
    // json is the ability API response
    String shortEff = '';
    String eff = '';
    if (json['effect_entries'] != null) {
      for (final entry in json['effect_entries']) {
        if (entry['language'] != null && entry['language']['name'] == 'en') {
          shortEff = entry['short_effect'] ?? '';
          eff = entry['effect'] ?? '';
          break;
        }
      }
    }

    return PokemonAbility(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      shortEffect: shortEff,
      effect: eff,
    );
  }

  // Fallback constructor if only name and url are known
  factory PokemonAbility.basic({required String name, required String url}) {
    return PokemonAbility(name: name, url: url, shortEffect: '', effect: '');
  }
}
