import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/pokemon_ability.dart';

class AbilityService {
  Future<PokemonAbility> fetchAbility(String url) async {
    final uri = Uri.parse(url);
    // Add a short timeout to avoid hanging; let caller decide how to handle errors.
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) {
      throw Exception('Failed to load ability from $url (status ${res.statusCode})');
    }

    final Map<String, dynamic> json = jsonDecode(res.body);

    // Parse English effect entries
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

    final name = json['name'] ?? '';

    return PokemonAbility(name: name, url: url, shortEffect: shortEff, effect: eff);
  }
}
