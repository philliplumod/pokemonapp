import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/battle_bloc.dart';
import '../bloc/progress_bloc.dart';
import '../models/battle_state.dart';
import '../models/battle_pokemon.dart';
import '../utils/type_utils.dart';
import '../utils/dynamic_evolution_system.dart';
import 'pokemon_reward_screen.dart';

class BattleScreen extends StatelessWidget {
  final BattlePokemon playerPokemon;
  final int playerLevel;
  final List<String> recentOpponents;

  const BattleScreen({
    super.key,
    required this.playerPokemon,
    required this.playerLevel,
    this.recentOpponents = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BattleBloc()
        ..add(
          StartBattle(
            playerPokemon,
            playerLevel: playerLevel,
            recentOpponents: recentOpponents,
          ),
        ),
      child: const BattleView(),
    );
  }
}

class BattleView extends StatelessWidget {
  const BattleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle', style: TextStyle(fontSize: 14)),
      ),
      body: BlocConsumer<BattleBloc, BattleState>(
        listener: (context, state) {
          if (state.phase == BattlePhase.victory) {
            _showVictoryDialog(context, state.rewardCoins);
          } else if (state.phase == BattlePhase.defeat) {
            _showDefeatDialog(context);
          }
        },
        builder: (context, state) {
          if (state.playerPokemon == null || state.enemyPokemon == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Enemy Pokemon
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPokemonInfo(state.enemyPokemon!, isEnemy: true),
                      const SizedBox(height: 8),
                      _buildHPBar(state.enemyPokemon!),
                      const SizedBox(height: 16),
                      if (state.enemyPokemon!.spriteUrl.isNotEmpty)
                        Image.network(
                          state.enemyPokemon!.spriteUrl,
                          height: 120,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.catching_pokemon, size: 120),
                        ),
                    ],
                  ),
                ),
              ),

              // Battle Log
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    child: Text(
                      state.battleLog,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),

              // Player Pokemon
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (state.playerPokemon!.spriteUrl.isNotEmpty)
                        Image.network(
                          state.playerPokemon!.spriteUrl,
                          height: 120,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.catching_pokemon, size: 120),
                        ),
                      const SizedBox(height: 16),
                      _buildHPBar(state.playerPokemon!),
                      const SizedBox(height: 8),
                      _buildPokemonInfo(state.playerPokemon!, isEnemy: false),
                    ],
                  ),
                ),
              ),

              // Move buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: state.playerPokemon!.moves.length,
                  itemBuilder: (context, index) {
                    final move = state.playerPokemon!.moves[index];
                    final isDisabled = state.phase != BattlePhase.playerTurn;

                    return ElevatedButton(
                      onPressed: isDisabled
                          ? null
                          : () => context.read<BattleBloc>().add(
                              SelectMove(move),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TypeUtils.getTypeColor(move.type),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            move.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'PWR: ${move.power}',
                            style: const TextStyle(fontSize: 7),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPokemonInfo(BattlePokemon pokemon, {required bool isEnemy}) {
    return Row(
      mainAxisAlignment: isEnemy
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: isEnemy
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              pokemon.name.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: pokemon.types.map((type) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TypeUtils.getTypeColor(type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: const TextStyle(fontSize: 7, color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHPBar(BattlePokemon pokemon) {
    final hpPercent = pokemon.hpPercentage;
    Color hpColor = Colors.green;
    if (hpPercent < 0.25) {
      hpColor = Colors.red;
    } else if (hpPercent < 0.5) {
      hpColor = Colors.orange;
    }

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'HP:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  color: Colors.grey[300],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: hpPercent,
                  child: Container(color: hpColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${pokemon.currentHp}/${pokemon.maxHp}',
          style: const TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  Future<void> _showVictoryDialog(BuildContext context, int coins) async {
    final battleBloc = context.read<BattleBloc>();
    final progressBloc = context.read<ProgressBloc>();
    final playerPokemon = battleBloc.state.playerPokemon!;
    final enemyPokemon = battleBloc.state.enemyPokemon;
    final remainingHp = playerPokemon.currentHp;

    // Calculate EXP gained based on player level
    final progress = progressBloc.state;
    final playerLevel = progress.activePokemon != null
        ? progress.getLevel(progress.activePokemon!)
        : 1;
    final baseExp = 50;
    final expGained = (baseExp + (playerLevel - 1) * 10);

    // Record victory with EXP and opponent name
    progressBloc.add(
      RecordBattleResult(
        true,
        remainingHp: remainingHp,
        expGained: expGained,
        opponentName: enemyPokemon?.name,
      ),
    );

    // Wait a moment for state to update
    await Future.delayed(const Duration(milliseconds: 200));

    // Check if Pokemon can evolve after level up using dynamic evolution system
    final updatedProgress = progressBloc.state;
    final activePokemon = updatedProgress.activePokemon;
    String? evolutionTarget;

    if (activePokemon != null) {
      final currentLevel = updatedProgress.getLevel(activePokemon);
      final evolutionSystem = DynamicEvolutionSystem.instance;

      final canEvolve = await evolutionSystem.canEvolveAt(
        activePokemon,
        currentLevel,
      );
      if (canEvolve) {
        evolutionTarget = await evolutionSystem.getNextEvolution(
          activePokemon,
          currentLevel,
        );
      }
    }

    // Show victory dialog with evolution info
    final currentLevel = activePokemon != null
        ? updatedProgress.getLevel(activePokemon)
        : 1;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Victory!', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'HP Remaining: $remainingHp',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '+$expGained EXP',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text('Level: $currentLevel', style: const TextStyle(fontSize: 12)),
            if (evolutionTarget != null) ...[
              const SizedBox(height: 12),
              const Text(
                '✨ Ready to Evolve! ✨',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Consecutive Wins: ${updatedProgress.consecutiveWins}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              updatedProgress.consecutiveWins >= 3
                  ? 'Claim Reward!'
                  : 'Continue',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    // Show evolution dialog if applicable
    if (evolutionTarget != null && activePokemon != null) {
      await _showEvolutionDialog(context, activePokemon, evolutionTarget);
    }

    if (!context.mounted) return;

    // Check if reward is due
    final shouldShowReward = updatedProgress.consecutiveWins >= 3;

    if (shouldShowReward) {
      // Show reward screen
      final claimed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PokemonRewardScreen()),
      );

      if (claimed == true && context.mounted) {
        // Return to menu after claiming reward
        Navigator.of(context).pop();
      }
    } else {
      // Auto-proceed to next battle - HP carries over
      if (context.mounted) {
        final battleBloc = context.read<BattleBloc>();
        final currentLevel = updatedProgress.activePokemon != null
            ? updatedProgress.getLevel(updatedProgress.activePokemon!)
            : 1;

        battleBloc.add(
          StartBattle(
            playerPokemon.copyWith(currentHp: remainingHp),
            playerLevel: currentLevel,
            recentOpponents: updatedProgress.recentOpponents,
          ),
        );
      }
    }
  }

  Future<void> _showEvolutionDialog(
    BuildContext context,
    String oldName,
    String newName,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Evolution!', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 48, color: Colors.purple),
            const SizedBox(height: 16),
            Text(
              '${oldName.toUpperCase()} is evolving!',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('↓', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text(
              newName.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ProgressBloc>().add(EvolvePokemon(oldName, newName));
              Navigator.pop(dialogContext);
            },
            child: const Text('Evolve!', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDefeatDialog(BuildContext context) {
    final progressBloc = context.read<ProgressBloc>();
    final progress = progressBloc.state;
    final activePokemon = progress.activePokemon;

    // Award small EXP even on defeat
    final defeatExp = 25;

    if (activePokemon != null) {
      final currentLevel = progress.getLevel(activePokemon);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Defeat', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_dissatisfied,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your streak has ended!',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '+$defeatExp EXP (Participation)',
                style: const TextStyle(fontSize: 10, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                'Level: $currentLevel',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try again with full HP!',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<ProgressBloc>().add(
                  RecordBattleResult(false, expGained: defeatExp),
                );
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Return to menu
              },
              child: const Text('Back to Menu', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    } else {
      final enemyPokemon = context.read<BattleBloc>().state.enemyPokemon;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Defeat', style: TextStyle(fontSize: 16)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Your streak has ended!', style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              Text('Try again with full HP!', style: TextStyle(fontSize: 10)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<ProgressBloc>().add(
                  RecordBattleResult(false, opponentName: enemyPokemon?.name),
                );
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Return to menu
              },
              child: const Text('Back to Menu', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }
  }
}
