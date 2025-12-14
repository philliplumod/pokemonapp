import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dynamic evolution system that fetches real evolution chains from PokeAPI
class DynamicEvolutionSystem {
  static final DynamicEvolutionSystem instance = DynamicEvolutionSystem._();
  DynamicEvolutionSystem._();

  final Map<String, EvolutionChainData> _cache = {};

  /// Get evolution chain data for a Pokemon
  Future<EvolutionChainData?> getEvolutionChain(String pokemonName) async {
    final key = pokemonName.toLowerCase();

    // Return from cache if available
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      // Fetch Pokemon data to get species URL
      final pokemonUri = Uri.parse('https://pokeapi.co/api/v2/pokemon/$key');
      final pokemonRes = await http.get(pokemonUri);

      if (pokemonRes.statusCode != 200) return null;

      final pokemonJson = jsonDecode(pokemonRes.body);
      final speciesUrl = pokemonJson['species']['url'];

      // Fetch species data to get evolution chain URL
      final speciesRes = await http.get(Uri.parse(speciesUrl));
      if (speciesRes.statusCode != 200) return null;

      final speciesJson = jsonDecode(speciesRes.body);
      final evolutionChainUrl = speciesJson['evolution_chain']['url'];

      // Fetch evolution chain
      final chainRes = await http.get(Uri.parse(evolutionChainUrl));
      if (chainRes.statusCode != 200) return null;

      final chainJson = jsonDecode(chainRes.body);

      // Parse evolution chain
      final chainData = _parseEvolutionChain(chainJson['chain'], key);

      if (chainData != null) {
        _cache[key] = chainData;
      }

      return chainData;
    } catch (e) {
      print('Error fetching evolution chain for $pokemonName: $e');
      return null;
    }
  }

  /// Parse evolution chain and find next evolution for target Pokemon
  EvolutionChainData? _parseEvolutionChain(
    Map<String, dynamic> chainNode,
    String targetName,
  ) {
    final currentName = chainNode['species']['name'] as String;

    // Check if this is our target Pokemon
    if (currentName == targetName) {
      final evolvesTo = chainNode['evolves_to'] as List?;

      if (evolvesTo == null || evolvesTo.isEmpty) {
        // This Pokemon doesn't evolve
        return EvolutionChainData(
          pokemonName: targetName,
          nextEvolution: null,
          evolutionLevel: null,
          canEvolve: false,
        );
      }

      // Get first evolution option (simplified - doesn't handle branching)
      final firstEvolution = evolvesTo[0];
      final nextName = firstEvolution['species']['name'] as String;

      // Get evolution trigger details
      final evolutionDetails = firstEvolution['evolution_details'] as List?;
      int? minLevel;

      if (evolutionDetails != null && evolutionDetails.isNotEmpty) {
        final details = evolutionDetails[0];
        minLevel = details['min_level'] as int?;
      }

      return EvolutionChainData(
        pokemonName: targetName,
        nextEvolution: nextName,
        evolutionLevel: minLevel,
        canEvolve: true,
      );
    }

    // Search in evolved forms
    final evolvesTo = chainNode['evolves_to'] as List?;
    if (evolvesTo != null) {
      for (final evolution in evolvesTo) {
        final result = _parseEvolutionChain(evolution, targetName);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /// Check if Pokemon can evolve at current level
  Future<bool> canEvolveAt(String pokemonName, int currentLevel) async {
    final chain = await getEvolutionChain(pokemonName);
    if (chain == null || !chain.canEvolve) return false;

    // Minimum level 5 requirement
    if (currentLevel < 5) return false;

    // Check if meets evolution level requirement
    if (chain.evolutionLevel != null) {
      return currentLevel >= chain.evolutionLevel!;
    }

    // If no level requirement, can evolve at level 5+
    return true;
  }

  /// Get next evolution name if Pokemon can evolve
  Future<String?> getNextEvolution(String pokemonName, int currentLevel) async {
    final chain = await getEvolutionChain(pokemonName);
    if (chain == null || !chain.canEvolve) return null;

    // Minimum level 5 requirement
    if (currentLevel < 5) return null;

    // Check if meets evolution level requirement
    if (chain.evolutionLevel != null) {
      if (currentLevel >= chain.evolutionLevel!) {
        return chain.nextEvolution;
      }
      return null;
    }

    // If no level requirement, can evolve at level 5+
    return chain.nextEvolution;
  }

  /// Get evolution level requirement
  Future<int?> getEvolutionLevel(String pokemonName) async {
    final chain = await getEvolutionChain(pokemonName);
    return chain?.evolutionLevel;
  }

  void clearCache() {
    _cache.clear();
  }
}

class EvolutionChainData {
  final String pokemonName;
  final String? nextEvolution;
  final int? evolutionLevel;
  final bool canEvolve;

  const EvolutionChainData({
    required this.pokemonName,
    required this.nextEvolution,
    required this.evolutionLevel,
    required this.canEvolve,
  });
}
