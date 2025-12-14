import 'package:equatable/equatable.dart';
import 'battle_pokemon.dart';

enum BattlePhase { selecting, playerTurn, enemyTurn, victory, defeat }

class BattleState extends Equatable {
  final BattlePokemon? playerPokemon;
  final BattlePokemon? enemyPokemon;
  final BattlePhase phase;
  final String battleLog;
  final int difficulty; // 1-5, affects enemy stats
  final int rewardCoins;

  const BattleState({
    this.playerPokemon,
    this.enemyPokemon,
    this.phase = BattlePhase.selecting,
    this.battleLog = '',
    this.difficulty = 1,
    this.rewardCoins = 10,
  });

  BattleState copyWith({
    BattlePokemon? playerPokemon,
    BattlePokemon? enemyPokemon,
    BattlePhase? phase,
    String? battleLog,
    int? difficulty,
    int? rewardCoins,
  }) {
    return BattleState(
      playerPokemon: playerPokemon ?? this.playerPokemon,
      enemyPokemon: enemyPokemon ?? this.enemyPokemon,
      phase: phase ?? this.phase,
      battleLog: battleLog ?? this.battleLog,
      difficulty: difficulty ?? this.difficulty,
      rewardCoins: rewardCoins ?? this.rewardCoins,
    );
  }

  @override
  List<Object?> get props => [
    playerPokemon,
    enemyPokemon,
    phase,
    battleLog,
    difficulty,
  ];
}
