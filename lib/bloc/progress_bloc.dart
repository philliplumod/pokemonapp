import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/game_progress.dart';

// Events
abstract class ProgressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SelectStarter extends ProgressEvent {
  final String pokemonName;
  SelectStarter(this.pokemonName);
  @override
  List<Object?> get props => [pokemonName];
}

class RecordBattleResult extends ProgressEvent {
  final bool won;
  final int remainingHp;
  final int expGained;
  final String? opponentName; // Track opponent to avoid repeats

  RecordBattleResult(
    this.won, {
    this.remainingHp = 0,
    this.expGained = 50,
    this.opponentName,
  });

  @override
  List<Object?> get props => [won, remainingHp, expGained, opponentName];
}

class AddPokemon extends ProgressEvent {
  final String pokemonName;
  AddPokemon(this.pokemonName);
  @override
  List<Object?> get props => [pokemonName];
}

class EvolvePokemon extends ProgressEvent {
  final String oldName;
  final String newName;
  EvolvePokemon(this.oldName, this.newName);
  @override
  List<Object?> get props => [oldName, newName];
}

class SwitchActivePokemon extends ProgressEvent {
  final String pokemonName;
  SwitchActivePokemon(this.pokemonName);
  @override
  List<Object?> get props => [pokemonName];
}

class UpdateBattleHp extends ProgressEvent {
  final int hp;
  UpdateBattleHp(this.hp);
  @override
  List<Object?> get props => [hp];
}

class ResetProgress extends ProgressEvent {}

// BLoC
class ProgressBloc extends HydratedBloc<ProgressEvent, GameProgress> {
  ProgressBloc() : super(const GameProgress()) {
    on<SelectStarter>(_onSelectStarter);
    on<RecordBattleResult>(_onRecordBattleResult);
    on<AddPokemon>(_onAddPokemon);
    on<SwitchActivePokemon>(_onSwitchActivePokemon);
    on<UpdateBattleHp>(_onUpdateBattleHp);
    on<EvolvePokemon>(_onEvolvePokemon);
    on<ResetProgress>(_onResetProgress);
  }

  void _onSelectStarter(SelectStarter event, Emitter<GameProgress> emit) {
    final expMap = <String, int>{event.pokemonName: 0};
    final levelMap = <String, int>{event.pokemonName: 1};

    emit(
      state.copyWith(
        hasSelectedStarter: true,
        pokemonCollection: [event.pokemonName],
        activePokemon: event.pokemonName,
        pokemonExp: expMap,
        pokemonLevel: levelMap,
      ),
    );
  }

  void _onRecordBattleResult(
    RecordBattleResult event,
    Emitter<GameProgress> emit,
  ) {
    final newTotalBattles = state.totalBattles + 1;
    final newWins = event.won ? state.wins + 1 : state.wins;
    final newConsecutiveWins = event.won ? state.consecutiveWins + 1 : 0;
    final newBestStreak = newConsecutiveWins > state.bestStreak
        ? newConsecutiveWins
        : state.bestStreak;

    // Track recent opponents (keep last 5)
    List<String> updatedOpponents = List.from(state.recentOpponents);
    if (event.opponentName != null && event.opponentName!.isNotEmpty) {
      updatedOpponents.add(event.opponentName!);
      if (updatedOpponents.length > 5) {
        updatedOpponents = updatedOpponents.sublist(
          updatedOpponents.length - 5,
        );
      }
    }

    // Award EXP and handle battle results
    Map<String, int> newExp = Map.from(state.pokemonExp);
    Map<String, int> newLevel = Map.from(state.pokemonLevel);

    if (state.activePokemon != null) {
      final activePokemon = state.activePokemon!;
      final currentExp = state.getExp(activePokemon);

      if (event.won) {
        // Win: Award full EXP
        final gainedExp = event.expGained;
        newExp[activePokemon] = currentExp + gainedExp;
      } else {
        // Loss: Award reduced EXP (25% of normal)
        final reducedExp = (event.expGained * 0.25).round();
        newExp[activePokemon] = currentExp + reducedExp;
      }

      // Check for level up
      while (newExp[activePokemon]! >= state.expToNextLevel(activePokemon)) {
        newExp[activePokemon] =
            newExp[activePokemon]! - state.expToNextLevel(activePokemon);
        newLevel[activePokemon] = (newLevel[activePokemon] ?? 1) + 1;
      }
    }

    emit(
      state.copyWith(
        totalBattles: newTotalBattles,
        wins: newWins,
        consecutiveWins: newConsecutiveWins,
        bestStreak: newBestStreak,
        currentBattleHp: event.won ? event.remainingHp : 0,
        pokemonExp: newExp,
        pokemonLevel: newLevel,
        recentOpponents: updatedOpponents,
      ),
    );
  }

  void _onAddPokemon(AddPokemon event, Emitter<GameProgress> emit) {
    if (!state.pokemonCollection.contains(event.pokemonName)) {
      final updatedList = [...state.pokemonCollection, event.pokemonName];
      final newExp = Map<String, int>.from(state.pokemonExp);
      final newLevel = Map<String, int>.from(state.pokemonLevel);

      newExp[event.pokemonName] = 0;
      newLevel[event.pokemonName] = 1;

      emit(
        state.copyWith(
          pokemonCollection: updatedList,
          consecutiveWins: 0,
          pokemonExp: newExp,
          pokemonLevel: newLevel,
        ),
      );
    }
  }

  void _onEvolvePokemon(EvolvePokemon event, Emitter<GameProgress> emit) {
    final collection = List<String>.from(state.pokemonCollection);
    final index = collection.indexOf(event.oldName);

    if (index != -1) {
      collection[index] = event.newName;

      final newExp = Map<String, int>.from(state.pokemonExp);
      final newLevel = Map<String, int>.from(state.pokemonLevel);

      // Transfer progress to evolved form
      newExp[event.newName] = newExp[event.oldName] ?? 0;
      newLevel[event.newName] = newLevel[event.oldName] ?? 1;
      newExp.remove(event.oldName);
      newLevel.remove(event.oldName);

      emit(
        state.copyWith(
          pokemonCollection: collection,
          activePokemon: state.activePokemon == event.oldName
              ? event.newName
              : state.activePokemon,
          pokemonExp: newExp,
          pokemonLevel: newLevel,
        ),
      );
    }
  }

  void _onSwitchActivePokemon(
    SwitchActivePokemon event,
    Emitter<GameProgress> emit,
  ) {
    if (state.pokemonCollection.contains(event.pokemonName)) {
      emit(
        state.copyWith(
          activePokemon: event.pokemonName,
          currentBattleHp: 0, // Reset HP when switching
        ),
      );
    }
  }

  void _onUpdateBattleHp(UpdateBattleHp event, Emitter<GameProgress> emit) {
    emit(state.copyWith(currentBattleHp: event.hp));
  }

  void _onResetProgress(ResetProgress event, Emitter<GameProgress> emit) {
    emit(const GameProgress());
  }

  @override
  GameProgress? fromJson(Map<String, dynamic> json) {
    try {
      return GameProgress.fromJson(json);
    } catch (_) {
      return const GameProgress();
    }
  }

  @override
  Map<String, dynamic>? toJson(GameProgress state) {
    return state.toJson();
  }
}
