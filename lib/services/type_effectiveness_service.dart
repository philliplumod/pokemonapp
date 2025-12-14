import 'dart:convert';
import 'package:http/http.dart' as http;

class TypeEffectivenessService {
  // Cache type effectiveness to minimize API calls
  final Map<String, Map<String, double>> _typeCache = {};

  Future<Map<String, double>> getTypeEffectiveness(String attackingType) async {
    if (_typeCache.containsKey(attackingType)) {
      return _typeCache[attackingType]!;
    }

    try {
      final uri = Uri.parse(
        'https://pokeapi.co/api/v2/type/${attackingType.toLowerCase()}',
      );
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        return _getDefaultEffectiveness();
      }

      final json = jsonDecode(res.body);
      final damageRelations = json['damage_relations'];

      final effectiveness = <String, double>{};

      // Double damage (super effective)
      if (damageRelations['double_damage_to'] != null) {
        for (var type in damageRelations['double_damage_to']) {
          effectiveness[type['name']] = 2.0;
        }
      }

      // Half damage (not very effective)
      if (damageRelations['half_damage_to'] != null) {
        for (var type in damageRelations['half_damage_to']) {
          effectiveness[type['name']] = 0.5;
        }
      }

      // No damage (immune)
      if (damageRelations['no_damage_to'] != null) {
        for (var type in damageRelations['no_damage_to']) {
          effectiveness[type['name']] = 0.0;
        }
      }

      _typeCache[attackingType] = effectiveness;
      return effectiveness;
    } catch (e) {
      return _getDefaultEffectiveness();
    }
  }

  double calculateTypeMultiplier(
    String attackType,
    List<String> defenderTypes,
  ) {
    double multiplier = 1.0;

    final effectiveness = _typeCache[attackType] ?? {};

    for (final defenderType in defenderTypes) {
      multiplier *= effectiveness[defenderType] ?? 1.0;
    }

    return multiplier;
  }

  String getEffectivenessText(double multiplier) {
    if (multiplier >= 2.0) return 'Super Effective!';
    if (multiplier > 1.0) return 'Effective!';
    if (multiplier == 0.0) return 'No Effect...';
    if (multiplier < 1.0) return 'Not very effective...';
    return '';
  }

  Map<String, double> _getDefaultEffectiveness() {
    return {};
  }

  // Preload common types
  Future<void> preloadTypes() async {
    final commonTypes = [
      'normal',
      'fire',
      'water',
      'electric',
      'grass',
      'ice',
      'fighting',
      'poison',
      'ground',
      'flying',
      'psychic',
      'bug',
      'rock',
      'ghost',
      'dragon',
      'dark',
      'steel',
      'fairy',
    ];

    for (final type in commonTypes) {
      await getTypeEffectiveness(type);
    }
  }
}
