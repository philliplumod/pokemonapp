import 'package:equatable/equatable.dart';

class BattlePokemon extends Equatable {
  final String name;
  final String spriteUrl;
  final List<String> types;
  final int maxHp;
  final int currentHp;
  final int attack;
  final int defense;
  final int speed;
  final List<PokemonMove> moves;
  final bool isPlayerPokemon;

  const BattlePokemon({
    required this.name,
    required this.spriteUrl,
    required this.types,
    required this.maxHp,
    required this.currentHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.moves,
    this.isPlayerPokemon = false,
  });

  factory BattlePokemon.fromStats({
    required String name,
    required String spriteUrl,
    required List<String> types,
    required Map<String, int> stats,
    required List<PokemonMove> moves,
    bool isPlayerPokemon = false,
  }) {
    final hp = stats['hp'] ?? 50;
    return BattlePokemon(
      name: name,
      spriteUrl: spriteUrl,
      types: types,
      maxHp: hp,
      currentHp: hp,
      attack: stats['attack'] ?? 50,
      defense: stats['defense'] ?? 50,
      speed: stats['speed'] ?? 50,
      moves: moves,
      isPlayerPokemon: isPlayerPokemon,
    );
  }

  BattlePokemon copyWith({
    String? name,
    String? spriteUrl,
    List<String>? types,
    int? maxHp,
    int? currentHp,
    int? attack,
    int? defense,
    int? speed,
    List<PokemonMove>? moves,
    bool? isPlayerPokemon,
  }) {
    return BattlePokemon(
      name: name ?? this.name,
      spriteUrl: spriteUrl ?? this.spriteUrl,
      types: types ?? this.types,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      moves: moves ?? this.moves,
      isPlayerPokemon: isPlayerPokemon ?? this.isPlayerPokemon,
    );
  }

  double get hpPercentage => currentHp / maxHp;
  bool get isFainted => currentHp <= 0;

  // Scale stats based on level (10% increase per level)
  BattlePokemon scaleToLevel(int level) {
    if (level <= 1) return this;

    final multiplier = 1.0 + ((level - 1) * 0.1);
    final scaledMaxHp = (maxHp * multiplier).round();

    return copyWith(
      maxHp: scaledMaxHp,
      currentHp: (currentHp * multiplier).round(),
      attack: (attack * multiplier).round(),
      defense: (defense * multiplier).round(),
      speed: (speed * multiplier).round(),
    );
  }

  @override
  List<Object?> get props => [name, currentHp, maxHp, attack, defense, speed];
}

class PokemonMove extends Equatable {
  final String name;
  final String type;
  final int power;
  final String category; // 'physical' or 'special'

  const PokemonMove({
    required this.name,
    required this.type,
    required this.power,
    required this.category,
  });

  @override
  List<Object?> get props => [name, type, power, category];
}
