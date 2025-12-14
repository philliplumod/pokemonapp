import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/progress_bloc.dart';
import '../models/game_progress.dart';
import '../models/battle_pokemon.dart';
import '../services/pokemon_service.dart';
import 'battle_screen.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  final PokemonService _pokemonService = PokemonService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Arena', style: TextStyle(fontSize: 12)),
      ),
      body: BlocBuilder<ProgressBloc, GameProgress>(
        builder: (context, progress) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats card
                _buildStatsCard(progress),
                const SizedBox(height: 12),

                // Progress to next reward
                _buildProgressCard(progress),
                const SizedBox(height: 12),

                // Active Pokemon
                if (progress.activePokemon != null) ...[
                  _buildActivePokemonCard(progress),
                  const SizedBox(height: 12),
                ],

                // Start battle button
                ElevatedButton(
                  onPressed: progress.activePokemon == null || _isLoading
                      ? null
                      : () => _startBattle(context, progress),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          children: [
                            const Icon(Icons.flash_on, size: 24),
                            const SizedBox(height: 4),
                            const Text(
                              'START BATTLE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Difficulty: ${_getDifficultyName(progress.currentDifficulty)}',
                              style: const TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // Pokemon Collection
                _buildPokemonCollection(progress),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(GameProgress progress) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'YOUR STATS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Battles', progress.totalBattles.toString()),
                _buildStat('Wins', progress.wins.toString()),
                _buildStat(
                  'Win Rate',
                  '${progress.winRate.toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Streak', progress.consecutiveWins.toString()),
                _buildStat('Best', progress.bestStreak.toString()),
                _buildStat(
                  'Pokemon',
                  progress.pokemonCollection.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 8)),
      ],
    );
  }

  Widget _buildProgressCard(GameProgress progress) {
    final winsToReward = progress.winsUntilReward;
    final progressValue = (progress.consecutiveWins % 3) / 3.0;

    return Card(
      color: winsToReward == 0 ? Colors.amber.shade100 : null,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NEXT REWARD',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$winsToReward wins away',
                  style: TextStyle(
                    fontSize: 10,
                    color: winsToReward == 0 ? Colors.orange.shade800 : null,
                    fontWeight: winsToReward == 0 ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                winsToReward == 0 ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '3 consecutive wins = New Pokémon!',
              style: TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePokemonCard(GameProgress progress) {
    final level = progress.getLevel(progress.activePokemon!);
    final exp = progress.getExp(progress.activePokemon!);
    final expToNext = progress.expToNextLevel(progress.activePokemon!);
    final expPercent = exp / expToNext;

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'ACTIVE POKÉMON',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.catching_pokemon,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.activePokemon!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level: $level',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (progress.currentBattleHp > 0)
                        Text(
                          'HP: ${progress.currentBattleHp}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXP to Next Level',
                      style: TextStyle(fontSize: 9),
                    ),
                    Text(
                      '$exp / $expToNext',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: expPercent,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonCollection(GameProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'YOUR COLLECTION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              icon: const Icon(Icons.menu_book, size: 16),
              label: const Text('Pokédex', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: progress.pokemonCollection.length,
          itemBuilder: (context, index) {
            final pokemon = progress.pokemonCollection[index];
            final isActive = pokemon == progress.activePokemon;
            final level = progress.getLevel(pokemon);

            return Card(
              color: isActive ? Colors.blue.shade100 : null,
              child: InkWell(
                onTap: () {
                  if (!isActive) {
                    _showSwitchDialog(context, pokemon);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.star : Icons.catching_pokemon,
                      size: 32,
                      color: isActive ? Colors.amber : Colors.grey.shade700,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pokemon.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: isActive ? FontWeight.bold : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lv. $level',
                      style: const TextStyle(
                        fontSize: 7,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSwitchDialog(BuildContext context, String pokemonName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Switch to ${pokemonName.toUpperCase()}?',
          style: const TextStyle(fontSize: 14),
        ),
        content: const Text(
          'This will become your active Pokémon for battles.',
          style: TextStyle(fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressBloc>().add(
                SwitchActivePokemon(pokemonName),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Switch', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _getDifficultyName(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Easy';
    }
  }

  Future<void> _startBattle(BuildContext context, GameProgress progress) async {
    if (progress.activePokemon == null) return;

    setState(() => _isLoading = true);

    try {
      // Fetch the active Pokemon
      final pokemon = await _pokemonService.fetchPokemon(
        progress.activePokemon!,
      );

      // Generate moves
      final moves = await _generateMovesForPokemon(pokemon.types);

      // Get Pokemon level and apply stat scaling
      final activePokemonName = progress.activePokemon!;
      final statMultiplier = progress.getStatMultiplier(activePokemonName);

      // Create battle Pokemon with level-scaled stats
      final maxHp = (pokemon.stats['hp']! * statMultiplier).round();
      final currentHp = progress.currentBattleHp > 0
          ? progress.currentBattleHp
          : maxHp;

      final scaledStats = <String, int>{};
      pokemon.stats.forEach((key, value) {
        scaledStats[key] = (value * statMultiplier).round();
      });

      final battlePokemon = BattlePokemon.fromStats(
        name: pokemon.name,
        spriteUrl: pokemon.spriteUrl,
        types: pokemon.types,
        stats: scaledStats,
        moves: moves,
        isPlayerPokemon: true,
      ).copyWith(currentHp: currentHp);

      if (mounted) {
        final playerLevel = progress.getLevel(activePokemonName);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BattleScreen(
              playerPokemon: battlePokemon,
              playerLevel: playerLevel,
              recentOpponents: progress.recentOpponents,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load Pokémon: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<PokemonMove>> _generateMovesForPokemon(List<String> types) async {
    final moves = <PokemonMove>[];

    for (final type in types) {
      moves.add(
        PokemonMove(
          name: '$type-beam',
          type: type,
          power: 60,
          category: 'special',
        ),
      );
    }

    if (moves.length < 4) {
      moves.add(
        const PokemonMove(
          name: 'tackle',
          type: 'normal',
          power: 40,
          category: 'physical',
        ),
      );
    }
    if (moves.length < 4) {
      moves.add(
        const PokemonMove(
          name: 'quick-attack',
          type: 'normal',
          power: 40,
          category: 'physical',
        ),
      );
    }

    return moves;
  }
}
