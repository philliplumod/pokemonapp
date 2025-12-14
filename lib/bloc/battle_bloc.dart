import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/battle_state.dart';
import '../models/battle_pokemon.dart';
import '../services/battle_service.dart';
import '../services/type_effectiveness_service.dart';

// Events
abstract class BattleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartBattle extends BattleEvent {
  final BattlePokemon playerPokemon;
  final int playerLevel;
  final List<String> recentOpponents;

  StartBattle(
    this.playerPokemon, {
    required this.playerLevel,
    this.recentOpponents = const [],
  });

  @override
  List<Object?> get props => [playerPokemon, playerLevel, recentOpponents];
}

class SelectMove extends BattleEvent {
  final PokemonMove move;
  SelectMove(this.move);
  @override
  List<Object?> get props => [move];
}

class EnemyTurn extends BattleEvent {}

class ResetBattle extends BattleEvent {}

// BLoC
class BattleBloc extends Bloc<BattleEvent, BattleState> {
  final BattleService _battleService = BattleService();
  final TypeEffectivenessService _typeService = TypeEffectivenessService();

  BattleBloc() : super(const BattleState()) {
    on<StartBattle>(_onStartBattle);
    on<SelectMove>(_onSelectMove);
    on<EnemyTurn>(_onEnemyTurn);
    on<ResetBattle>(_onResetBattle);
  }

  Future<void> _onStartBattle(
    StartBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(
      const BattleState(
        phase: BattlePhase.selecting,
        battleLog: 'Finding a fair opponent...',
      ),
    );

    try {
      // Calculate player's base stats total for fair matchmaking
      final playerBaseStats =
          event.playerPokemon.maxHp +
          event.playerPokemon.attack +
          event.playerPokemon.defense +
          event.playerPokemon.speed;

      // Get fair opponent based on level and stats
      final enemy = await _battleService.getFairOpponent(
        playerLevel: event.playerLevel,
        playerBaseStats: playerBaseStats,
        recentOpponents: event.recentOpponents,
      );

      // Preload type effectiveness
      for (final move in event.playerPokemon.moves) {
        await _typeService.getTypeEffectiveness(move.type);
      }
      for (final move in enemy.moves) {
        await _typeService.getTypeEffectiveness(move.type);
      }

      final rewardCoins =
          10 + (event.playerLevel * 2); // Scale rewards with level

      emit(
        BattleState(
          playerPokemon: event.playerPokemon,
          enemyPokemon: enemy,
          phase: BattlePhase.playerTurn,
          battleLog: 'Battle started! A wild ${enemy.name} appeared!',
          difficulty: event.playerLevel, // Use level as difficulty
          rewardCoins: rewardCoins,
        ),
      );
    } catch (e) {
      emit(
        const BattleState(
          phase: BattlePhase.selecting,
          battleLog: 'Failed to load opponent. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSelectMove(
    SelectMove event,
    Emitter<BattleState> emit,
  ) async {
    if (state.playerPokemon == null || state.enemyPokemon == null) return;
    if (state.phase != BattlePhase.playerTurn) return;

    final player = state.playerPokemon!;
    final enemy = state.enemyPokemon!;
    final move = event.move;

    // Calculate type effectiveness
    final typeMultiplier = _typeService.calculateTypeMultiplier(
      move.type,
      enemy.types,
    );
    final damage = _battleService.calculateDamage(
      attacker: player,
      defender: enemy,
      move: move,
      typeMultiplier: typeMultiplier,
    );

    final newEnemyHp = (enemy.currentHp - damage).clamp(0, enemy.maxHp);
    final updatedEnemy = enemy.copyWith(currentHp: newEnemyHp);

    String log = '${player.name} used ${move.name}!\n';
    final effectText = _typeService.getEffectivenessText(typeMultiplier);
    if (effectText.isNotEmpty) {
      log += '$effectText\n';
    }
    log += 'Dealt $damage damage!';

    if (newEnemyHp <= 0) {
      log += '\n${enemy.name} fainted! You win!';
      emit(
        state.copyWith(
          enemyPokemon: updatedEnemy,
          phase: BattlePhase.victory,
          battleLog: log,
        ),
      );
    } else {
      emit(
        state.copyWith(
          enemyPokemon: updatedEnemy,
          phase: BattlePhase.enemyTurn,
          battleLog: log,
        ),
      );

      // Trigger enemy turn after a delay
      await Future.delayed(const Duration(milliseconds: 1500));
      add(EnemyTurn());
    }
  }

  Future<void> _onEnemyTurn(EnemyTurn event, Emitter<BattleState> emit) async {
    if (state.playerPokemon == null || state.enemyPokemon == null) return;
    if (state.phase != BattlePhase.enemyTurn) return;

    final player = state.playerPokemon!;
    final enemy = state.enemyPokemon!;

    // AI selects a random move
    final move = enemy.moves[DateTime.now().millisecond % enemy.moves.length];

    final typeMultiplier = _typeService.calculateTypeMultiplier(
      move.type,
      player.types,
    );
    final damage = _battleService.calculateDamage(
      attacker: enemy,
      defender: player,
      move: move,
      typeMultiplier: typeMultiplier,
    );

    final newPlayerHp = (player.currentHp - damage).clamp(0, player.maxHp);
    final updatedPlayer = player.copyWith(currentHp: newPlayerHp);

    String log = '${enemy.name} used ${move.name}!\n';
    final effectText = _typeService.getEffectivenessText(typeMultiplier);
    if (effectText.isNotEmpty) {
      log += '$effectText\n';
    }
    log += 'You took $damage damage!';

    if (newPlayerHp <= 0) {
      log += '\n${player.name} fainted! You lost...';
      emit(
        state.copyWith(
          playerPokemon: updatedPlayer,
          phase: BattlePhase.defeat,
          battleLog: log,
        ),
      );
    } else {
      emit(
        state.copyWith(
          playerPokemon: updatedPlayer,
          phase: BattlePhase.playerTurn,
          battleLog: log,
        ),
      );
    }
  }

  void _onResetBattle(ResetBattle event, Emitter<BattleState> emit) {
    emit(const BattleState());
  }
}
