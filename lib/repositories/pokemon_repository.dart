import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/pokemon_ability.dart';
import '../services/ability_service.dart';

class PokemonRepository {
  final AbilityService _abilityService = AbilityService();

  Future<List<String>> fetchPokemonNamesList({int limit = 1025}) async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((p) => p['name'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch Pokemon list: $e');
    }
  }

  Future<Pokemon> fetchPokemonDetails(String name) async {
    try {
      final uri = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('Failed to load pokemon $name');
      }

      final Map<String, dynamic> json = jsonDecode(res.body);

      // Parse abilities with error handling
      final List<dynamic> rawAbilities = json['abilities'] ?? [];
      final List<Future<PokemonAbility>> abilityFutures = [];

      for (final a in rawAbilities) {
        final abilityInfo = a['ability'];
        if (abilityInfo != null) {
          final url = abilityInfo['url'] ?? '';
          if (url != '') {
            abilityFutures.add(
              _abilityService.fetchAbility(url).catchError((_) {
                return PokemonAbility.basic(
                  name: abilityInfo['name'] ?? '',
                  url: url,
                );
              }),
            );
          } else {
            abilityFutures.add(
              Future.value(
                PokemonAbility.basic(name: abilityInfo['name'] ?? '', url: ''),
              ),
            );
          }
        }
      }

      final abilities = await Future.wait(abilityFutures);

      return Pokemon.fromApi(json: json, abilities: abilities);
    } catch (e) {
      throw Exception('Failed to fetch Pokemon details for $name: $e');
    }
  }

  Future<List<Pokemon>> fetchMultiplePokemon(List<String> names) async {
    final futures = names.map((name) => fetchPokemonDetails(name)).toList();
    return await Future.wait(futures);
  }
}
