class EvolutionSystem {
  // Evolution chains: base -> stage1 -> stage2
  static const Map<String, List<String>> evolutionChains = {
    // Starter evolutions
    'bulbasaur': ['ivysaur', 'venusaur'],
    'ivysaur': ['venusaur'],
    'charmander': ['charmeleon', 'charizard'],
    'charmeleon': ['charizard'],
    'squirtle': ['wartortle', 'blastoise'],
    'wartortle': ['blastoise'],

    // Common evolutions
    'pidgey': ['pidgeotto', 'pidgeot'],
    'pidgeotto': ['pidgeot'],
    'rattata': ['raticate'],
    'caterpie': ['metapod', 'butterfree'],
    'metapod': ['butterfree'],
    'weedle': ['kakuna', 'beedrill'],
    'kakuna': ['beedrill'],
    'magikarp': ['gyarados'],
    'eevee': ['vaporeon'], // Simplified - just one evolution path
    'poliwag': ['poliwhirl', 'poliwrath'],
    'poliwhirl': ['poliwrath'],
    'machop': ['machoke', 'machamp'],
    'machoke': ['machamp'],
    'geodude': ['graveler', 'golem'],
    'graveler': ['golem'],
    'gastly': ['haunter', 'gengar'],
    'haunter': ['gengar'],
    'abra': ['kadabra', 'alakazam'],
    'kadabra': ['alakazam'],
    'oddish': ['gloom', 'vileplume'],
    'gloom': ['vileplume'],
    'bellsprout': ['weepinbell', 'victreebel'],
    'weepinbell': ['victreebel'],
    'dratini': ['dragonair', 'dragonite'],
    'dragonair': ['dragonite'],
  };

  // Level requirements for evolution
  static const Map<String, int> evolutionLevels = {
    'bulbasaur': 16,
    'ivysaur': 32,
    'charmander': 16,
    'charmeleon': 36,
    'squirtle': 16,
    'wartortle': 36,
    'pidgey': 18,
    'pidgeotto': 36,
    'rattata': 20,
    'caterpie': 7,
    'metapod': 10,
    'weedle': 7,
    'kakuna': 10,
    'magikarp': 20,
    'eevee': 25,
    'poliwag': 25,
    'poliwhirl': 36,
    'machop': 28,
    'machoke': 36,
    'geodude': 25,
    'graveler': 36,
    'gastly': 25,
    'haunter': 36,
    'abra': 16,
    'kadabra': 36,
    'oddish': 21,
    'gloom': 36,
    'bellsprout': 21,
    'weepinbell': 36,
    'dratini': 30,
    'dragonair': 55,
  };

  static String? getNextEvolution(String pokemonName, int currentLevel) {
    final chain = evolutionChains[pokemonName.toLowerCase()];
    if (chain == null || chain.isEmpty) return null;

    // Minimum level 5 required for any evolution
    if (currentLevel < 5) return null;

    final requiredLevel = evolutionLevels[pokemonName.toLowerCase()] ?? 999;
    if (currentLevel >= requiredLevel) {
      return chain[0]; // Return next evolution
    }
    return null;
  }

  static bool canEvolve(String pokemonName, int currentLevel) {
    // Check minimum level 5 requirement
    if (currentLevel < 5) return false;
    return getNextEvolution(pokemonName, currentLevel) != null;
  }

  static int getEvolutionLevel(String pokemonName) {
    return evolutionLevels[pokemonName.toLowerCase()] ?? 999;
  }

  static bool isEvolved(String pokemonName) {
    // Check if this Pokemon evolves FROM something
    for (var entry in evolutionChains.entries) {
      if (entry.value.contains(pokemonName.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
