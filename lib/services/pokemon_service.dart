import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/pokemon_ability.dart';
import 'ability_service.dart';

class PokemonService {
  final AbilityService _abilityService = AbilityService();

  Future<Pokemon> fetchPokemon(String name) async {
    final uri = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load pokemon $name');
    }

    final Map<String, dynamic> json = jsonDecode(res.body);

    // Parse abilities: each entry has ability{name,url}
    final List<dynamic> rawAbilities = json['abilities'] ?? [];
    final List<Future<PokemonAbility>> abilityFutures = [];

    for (final a in rawAbilities) {
      final abilityInfo = a['ability'];
      if (abilityInfo != null) {
        final url = abilityInfo['url'] ?? '';
        if (url != '') {
          // Fetch ability but recover on errors so one failed ability doesn't break the whole Pokémon fetch.
          abilityFutures.add(_abilityService.fetchAbility(url).catchError((_) {
            return PokemonAbility.basic(name: abilityInfo['name'] ?? '', url: url);
          }));
        } else {
          abilityFutures.add(Future.value(PokemonAbility.basic(name: abilityInfo['name'] ?? '', url: '')));
        }
      }
    }

    final abilities = await Future.wait(abilityFutures);

    // Build Pokemon model
    return Pokemon.fromApi(json: json, abilities: abilities);
  }
}
