import 'package:equatable/equatable.dart';

class GameProgress extends Equatable {
  final bool hasSelectedStarter;
  final int totalBattles;
  final int wins;
  final int consecutiveWins; // For tracking 3-win rewards
  final int bestStreak;
  final List<String> pokemonCollection;
  final String? activePokemon;
  final int currentBattleHp; // HP carries over between battles
  final Map<String, int> pokemonExp; // EXP per Pokemon
  final Map<String, int> pokemonLevel; // Level per Pokemon
  final List<String> recentOpponents; // Track last 5 opponents to avoid repeats

  const GameProgress({
    this.hasSelectedStarter = false,
    this.totalBattles = 0,
    this.wins = 0,
    this.consecutiveWins = 0,
    this.bestStreak = 0,
    this.pokemonCollection = const [],
    this.activePokemon,
    this.currentBattleHp = 0,
    this.pokemonExp = const {},
    this.pokemonLevel = const {},
    this.recentOpponents = const [],
  });

  GameProgress copyWith({
    bool? hasSelectedStarter,
    int? totalBattles,
    int? wins,
    int? consecutiveWins,
    int? bestStreak,
    List<String>? pokemonCollection,
    String? activePokemon,
    int? currentBattleHp,
    Map<String, int>? pokemonExp,
    Map<String, int>? pokemonLevel,
    List<String>? recentOpponents,
  }) {
    return GameProgress(
      hasSelectedStarter: hasSelectedStarter ?? this.hasSelectedStarter,
      totalBattles: totalBattles ?? this.totalBattles,
      wins: wins ?? this.wins,
      consecutiveWins: consecutiveWins ?? this.consecutiveWins,
      bestStreak: bestStreak ?? this.bestStreak,
      pokemonCollection: pokemonCollection ?? this.pokemonCollection,
      activePokemon: activePokemon ?? this.activePokemon,
      currentBattleHp: currentBattleHp ?? this.currentBattleHp,
      pokemonExp: pokemonExp ?? this.pokemonExp,
      pokemonLevel: pokemonLevel ?? this.pokemonLevel,
      recentOpponents: recentOpponents ?? this.recentOpponents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasSelectedStarter': hasSelectedStarter,
      'totalBattles': totalBattles,
      'wins': wins,
      'consecutiveWins': consecutiveWins,
      'pokemonExp': pokemonExp,
      'pokemonLevel': pokemonLevel,
      'bestStreak': bestStreak,
      'pokemonCollection': pokemonCollection,
      'activePokemon': activePokemon,
      'currentBattleHp': currentBattleHp,
      'recentOpponents': recentOpponents,
    };
  }

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      hasSelectedStarter: json['hasSelectedStarter'] ?? false,
      totalBattles: json['totalBattles'] ?? 0,
      wins: json['wins'] ?? 0,
      consecutiveWins: json['consecutiveWins'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      pokemonCollection: List<String>.from(json['pokemonCollection'] ?? []),
      pokemonExp: Map<String, int>.from(json['pokemonExp'] ?? {}),
      pokemonLevel: Map<String, int>.from(json['pokemonLevel'] ?? {}),
      activePokemon: json['activePokemon'],
      currentBattleHp: json['currentBattleHp'] ?? 0,
      recentOpponents: List<String>.from(json['recentOpponents'] ?? []),
    );
  }

  double get winRate => totalBattles > 0 ? (wins / totalBattles) * 100 : 0;

  int get winsUntilReward => consecutiveWins < 3 ? 3 - consecutiveWins : 0;

  int get currentDifficulty {
    if (wins <= 2) return 1; // Easy
    if (wins <= 5) return 2; // Medium
    if (wins <= 10) return 3; // Hard
    if (wins <= 15) return 4; // Expert
    return 5; // Master
  }

  int getLevel(String pokemonName) => pokemonLevel[pokemonName] ?? 1;
  int getExp(String pokemonName) => pokemonExp[pokemonName] ?? 0;
  int expToNextLevel(String pokemonName) {
    final level = getLevel(pokemonName);
    return (level * 100 * 1.2).round(); // Exponential growth
  }

  // Calculate stat multiplier based on level
  double getStatMultiplier(String pokemonName) {
    final level = getLevel(pokemonName);
    return 1.0 + ((level - 1) * 0.1); // 10% increase per level
  }

  @override
  List<Object?> get props => [
    hasSelectedStarter,
    totalBattles,
    wins,
    consecutiveWins,
    bestStreak,
    pokemonCollection,
    activePokemon,
    currentBattleHp,
    pokemonExp,
    pokemonLevel,
    recentOpponents,
  ];
}
