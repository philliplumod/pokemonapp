import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to fetch and classify Pokemon evolution stages and base stats from PokeAPI
class PokemonMatchmakingService {
  static final PokemonMatchmakingService instance =
      PokemonMatchmakingService._();
  PokemonMatchmakingService._();

  final Map<String, PokemonMatchmakingData> _cache = {};

  /// Get matchmaking data for a Pokemon (evolution stage, base stats total)
  Future<PokemonMatchmakingData?> getPokemonMatchmakingData(
    String pokemonName,
  ) async {
    final key = pokemonName.toLowerCase();

    // Return from cache if available
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      // Fetch Pokemon data
      final pokemonUri = Uri.parse('https://pokeapi.co/api/v2/pokemon/$key');
      final pokemonRes = await http.get(pokemonUri);

      if (pokemonRes.statusCode != 200) return null;

      final pokemonJson = jsonDecode(pokemonRes.body);
      final speciesUrl = pokemonJson['species']['url'];

      // Calculate base stats total
      int baseStatsTotal = 0;
      if (pokemonJson['stats'] != null) {
        for (final s in pokemonJson['stats']) {
          baseStatsTotal += (s['base_stat'] as int? ?? 0);
        }
      }

      // Fetch species data to get evolution chain
      final speciesRes = await http.get(Uri.parse(speciesUrl));
      if (speciesRes.statusCode != 200) return null;

      final speciesJson = jsonDecode(speciesRes.body);
      final evolutionChainUrl = speciesJson['evolution_chain']['url'];

      // Fetch evolution chain
      final chainRes = await http.get(Uri.parse(evolutionChainUrl));
      if (chainRes.statusCode != 200) return null;

      final chainJson = jsonDecode(chainRes.body);

      // Determine evolution stage by walking the chain
      final evolutionStage = _getEvolutionStage(chainJson['chain'], key);

      final data = PokemonMatchmakingData(
        name: key,
        evolutionStage: evolutionStage,
        baseStatsTotal: baseStatsTotal,
      );

      _cache[key] = data;
      return data;
    } catch (e) {
      print('Error fetching matchmaking data for $pokemonName: $e');
      return null;
    }
  }

  /// Walk evolution chain to find Pokemon's stage (1 = basic, 2 = stage 1, 3 = stage 2/final)
  int _getEvolutionStage(Map<String, dynamic> chainNode, String targetName) {
    final currentName = chainNode['species']['name'] as String;

    if (currentName == targetName) {
      return 1; // This is the base form
    }

    final evolvesTo = chainNode['evolves_to'] as List?;
    if (evolvesTo == null || evolvesTo.isEmpty) {
      return 1; // No further evolutions, so this is base
    }

    // Check each evolution path
    for (final evolution in evolvesTo) {
      final evolvedName = evolution['species']['name'] as String;

      if (evolvedName == targetName) {
        return 2; // This is a first-stage evolution
      }

      // Check second-stage evolutions
      final secondEvolutions = evolution['evolves_to'] as List?;
      if (secondEvolutions != null) {
        for (final secondEvolution in secondEvolutions) {
          final secondEvolvedName =
              secondEvolution['species']['name'] as String;
          if (secondEvolvedName == targetName) {
            return 3; // This is a second-stage evolution
          }
        }
      }
    }

    return 1; // Default to basic if not found in chain
  }

  /// Get a list of basic (Stage 1) Pokemon IDs within a range
  /// Returns Pokemon IDs that are basic forms (not evolved)
  List<int> getBasicPokemonPool(int maxId) {
    // Known basic Pokemon from Gen 1 (ID 1-151)
    final basicPokemon = <int>[
      1,
      4,
      7,
      10,
      13,
      16,
      19,
      21,
      23,
      25,
      27,
      29,
      32,
      35,
      37,
      39,
      41,
      43,
      46,
      48,
      50,
      52,
      54,
      56,
      58,
      60,
      63,
      66,
      69,
      72,
      74,
      77,
      79,
      81,
      83,
      84,
      86,
      88,
      90,
      92,
      95,
      96,
      98,
      100,
      102,
      104,
      108,
      109,
      111,
      113,
      114,
      115,
      116,
      118,
      120,
      122,
      123,
      124,
      125,
      126,
      127,
      128,
      129,
      131,
      132,
      133,
      137,
      138,
      140,
      142,
      143,
      144,
      145,
      146,
      147,
      150,
      151,
    ];

    return basicPokemon.where((id) => id <= maxId).toList();
  }

  /// Check if two Pokemon are fairly matched based on stats
  /// Returns true if stats are within acceptable range
  bool areFairlyMatched(
    int playerStatsTotal,
    int enemyStatsTotal,
    int playerLevel,
    int enemyLevel,
  ) {
    // Scale player stats by level multiplier
    final playerScaledStats = playerStatsTotal * (1 + (playerLevel - 1) * 0.1);
    final enemyScaledStats = enemyStatsTotal * (1 + (enemyLevel - 1) * 0.1);

    // Allow enemy to be within 80%-120% of player's scaled stats
    final minAcceptable = playerScaledStats * 0.8;
    final maxAcceptable = playerScaledStats * 1.2;

    return enemyScaledStats >= minAcceptable &&
        enemyScaledStats <= maxAcceptable;
  }

  void clearCache() {
    _cache.clear();
  }
}

class PokemonMatchmakingData {
  final String name;
  final int evolutionStage; // 1 = basic, 2 = stage 1, 3 = stage 2/final
  final int baseStatsTotal;

  const PokemonMatchmakingData({
    required this.name,
    required this.evolutionStage,
    required this.baseStatsTotal,
  });

  bool get isBasicForm => evolutionStage == 1;
  bool get isFullyEvolved => evolutionStage == 3;
}
