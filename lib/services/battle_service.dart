import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/battle_pokemon.dart';
import 'pokemon_matchmaking_service.dart';

class BattleService {
  final _random = Random();
  final _matchmakingService = PokemonMatchmakingService.instance;

  /// Get a fair opponent matched to player's level and stats
  /// Avoids recent opponents and ensures fair matchmaking
  Future<BattlePokemon> getFairOpponent({
    required int playerLevel,
    required int playerBaseStats,
    required List<String> recentOpponents,
  }) async {
    final maxAttempts = 20;
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      // Get pool of basic Pokemon (not evolved forms)
      final basicPool = _matchmakingService.getBasicPokemonPool(151);

      // Filter out recent opponents
      final availablePool = basicPool.where((id) {
        final name = _getPokemonNameFromId(id);
        return !recentOpponents.contains(name);
      }).toList();

      if (availablePool.isEmpty) {
        // If we've fought everyone, clear the recent list
        final pokemonId = basicPool[_random.nextInt(basicPool.length)];
        return await _fetchPokemonById(pokemonId, playerLevel);
      }

      // Try random Pokemon from available pool
      final randomId = availablePool[_random.nextInt(availablePool.length)];
      final pokemon = await _fetchPokemonById(randomId, playerLevel);

      // Check if stats are fairly matched
      final enemyBaseStats = _calculateBaseStatsTotal(pokemon);
      final isFair = _matchmakingService.areFairlyMatched(
        playerBaseStats,
        enemyBaseStats,
        playerLevel,
        _calculateEnemyLevel(playerLevel),
      );

      if (isFair) {
        return pokemon;
      }
    }

    // Fallback: return any basic Pokemon
    final basicPool = _matchmakingService.getBasicPokemonPool(151);
    final fallbackId = basicPool[_random.nextInt(basicPool.length)];
    return await _fetchPokemonById(fallbackId, playerLevel);
  }

  /// Calculate enemy level based on player level with slight variance
  int _calculateEnemyLevel(int playerLevel) {
    // Enemy is within ±1 level of player
    final variance = _random.nextInt(3) - 1; // -1, 0, or +1
    return max(1, playerLevel + variance);
  }

  /// Calculate total base stats from BattlePokemon
  int _calculateBaseStatsTotal(BattlePokemon pokemon) {
    return pokemon.maxHp + pokemon.attack + pokemon.defense + pokemon.speed;
  }

  /// Simple ID to name mapping for filtering (approximate)
  String _getPokemonNameFromId(int id) {
    // This is a fallback - in production, you'd maintain a proper mapping
    return 'pokemon-$id';
  }

  /// Fetch Pokemon by ID and scale stats to level
  Future<BattlePokemon> _fetchPokemonById(
    int pokemonId,
    int playerLevel,
  ) async {
    try {
      final uri = Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokemonId');
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        return _getDefaultOpponent();
      }

      final json = jsonDecode(res.body);
      final name = json['name'] ?? 'unknown';
      final spriteUrl = json['sprites']?['front_default'] ?? '';

      final types = <String>[];
      if (json['types'] != null) {
        for (final t in json['types']) {
          types.add(t['type']['name']);
        }
      }

      // Get enemy level (close to player level)
      final enemyLevel = _calculateEnemyLevel(playerLevel);
      final levelMultiplier = 1.0 + ((enemyLevel - 1) * 0.1); // 10% per level

      final stats = <String, int>{};
      if (json['stats'] != null) {
        for (final s in json['stats']) {
          final statName = s['stat']['name'];
          final baseStat = s['base_stat'];
          stats[statName] = (baseStat * levelMultiplier).round();
        }
      }

      final moves = await _getMovesForPokemon(json, types);

      return BattlePokemon.fromStats(
        name: name,
        spriteUrl: spriteUrl,
        types: types,
        stats: stats,
        moves: moves,
        isPlayerPokemon: false,
      );
    } catch (e) {
      return _getDefaultOpponent();
    }
  }

  Future<List<PokemonMove>> _getMovesForPokemon(
    Map<String, dynamic> pokemonJson,
    List<String> types,
  ) async {
    final moves = <PokemonMove>[];

    // Get some moves from the Pokemon's move list
    if (pokemonJson['moves'] != null && pokemonJson['moves'].isNotEmpty) {
      final moveList = pokemonJson['moves'] as List;
      final selectedMoves = <dynamic>[];

      // Try to get 4 different moves
      for (
        int i = 0;
        i < min(moveList.length, 10) && selectedMoves.length < 4;
        i++
      ) {
        selectedMoves.add(moveList[_random.nextInt(moveList.length)]);
      }

      for (final moveData in selectedMoves) {
        final moveUrl = moveData['move']['url'];
        try {
          final moveDetails = await _fetchMoveDetails(moveUrl);
          if (moveDetails != null) {
            moves.add(moveDetails);
          }
        } catch (e) {
          // Continue if move fetch fails
        }
      }
    }

    // If we don't have enough moves, add default moves based on type
    while (moves.length < 4) {
      moves.add(_getDefaultMove(types.isNotEmpty ? types[0] : 'normal'));
    }

    return moves;
  }

  Future<PokemonMove?> _fetchMoveDetails(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      final power = json['power'] ?? 50;

      // Skip status moves (no power)
      if (power == null) return null;

      return PokemonMove(
        name: json['name'] ?? 'tackle',
        type: json['type']?['name'] ?? 'normal',
        power: power,
        category: json['damage_class']?['name'] ?? 'physical',
      );
    } catch (e) {
      return null;
    }
  }

  PokemonMove _getDefaultMove(String type) {
    return PokemonMove(
      name: 'tackle',
      type: type,
      power: 40,
      category: 'physical',
    );
  }

  BattlePokemon _getDefaultOpponent() {
    return const BattlePokemon(
      name: 'rattata',
      spriteUrl: '',
      types: ['normal'],
      maxHp: 30,
      currentHp: 30,
      attack: 30,
      defense: 30,
      speed: 25,
      moves: [
        PokemonMove(
          name: 'tackle',
          type: 'normal',
          power: 40,
          category: 'physical',
        ),
        PokemonMove(
          name: 'quick-attack',
          type: 'normal',
          power: 40,
          category: 'physical',
        ),
      ],
      isPlayerPokemon: false,
    );
  }

  int calculateDamage({
    required BattlePokemon attacker,
    required BattlePokemon defender,
    required PokemonMove move,
    required double typeMultiplier,
  }) {
    // Simplified Pokemon damage formula
    final attackStat = move.category == 'physical'
        ? attacker.attack
        : attacker.attack;
    final defenseStat = move.category == 'physical'
        ? defender.defense
        : defender.defense;

    final baseDamage =
        ((2 * 50 / 5 + 2) * move.power * attackStat / defenseStat / 50 + 2);
    final randomFactor = 0.85 + _random.nextDouble() * 0.15; // 0.85 to 1.0

    final damage = (baseDamage * typeMultiplier * randomFactor).round();
    return max(1, damage); // Minimum 1 damage
  }
}
