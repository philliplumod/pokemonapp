import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/pokemon.dart';
import '../models/pokemon_ability.dart';
import '../repositories/pokemon_repository.dart';

// Events
abstract class PokedexEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPokedex extends PokedexEvent {
  final int limit;
  LoadPokedex({this.limit = 151});
  @override
  List<Object?> get props => [limit];
}

class SearchPokedex extends PokedexEvent {
  final String query;
  SearchPokedex(this.query);
  @override
  List<Object?> get props => [query];
}

class SortPokedex extends PokedexEvent {
  final PokedexSortOption sortOption;
  SortPokedex(this.sortOption);
  @override
  List<Object?> get props => [sortOption];
}

class RefreshPokedex extends PokedexEvent {}

// Sort Options
enum PokedexSortOption { defaultSort, randomized, aToZ, zToA }

// State
class PokedexState extends Equatable {
  final List<Pokemon> allPokemon;
  final List<Pokemon> filteredPokemon;
  final List<String> pokemonNames;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final PokedexSortOption sortOption;

  const PokedexState({
    this.allPokemon = const [],
    this.filteredPokemon = const [],
    this.pokemonNames = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.sortOption = PokedexSortOption.defaultSort,
  });

  PokedexState copyWith({
    List<Pokemon>? allPokemon,
    List<Pokemon>? filteredPokemon,
    List<String>? pokemonNames,
    bool? isLoading,
    String? error,
    String? searchQuery,
    PokedexSortOption? sortOption,
  }) {
    return PokedexState(
      allPokemon: allPokemon ?? this.allPokemon,
      filteredPokemon: filteredPokemon ?? this.filteredPokemon,
      pokemonNames: pokemonNames ?? this.pokemonNames,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allPokemon': allPokemon
          .map(
            (p) => {
              'name': p.name,
              'spriteUrl': p.spriteUrl,
              'types': p.types,
              'abilities': p.abilities
                  .map(
                    (a) => {
                      'name': a.name,
                      'url': a.url,
                      'effect': a.effect,
                      'shortEffect': a.shortEffect,
                    },
                  )
                  .toList(),
              'stats': p.stats,
            },
          )
          .toList(),
      'pokemonNames': pokemonNames,
      'searchQuery': searchQuery,
      'sortOption': sortOption.index,
    };
  }

  factory PokedexState.fromJson(Map<String, dynamic> json) {
    try {
      final allPokemonList =
          (json['allPokemon'] as List?)?.map((p) {
            return Pokemon(
              name: p['name'] ?? '',
              spriteUrl: p['spriteUrl'] ?? '',
              types: List<String>.from(p['types'] ?? []),
              abilities:
                  (p['abilities'] as List?)?.map((a) {
                    return PokemonAbility(
                      name: a['name'] ?? '',
                      url: a['url'] ?? '',
                      effect: a['effect'] ?? '',
                      shortEffect: a['shortEffect'] ?? '',
                    );
                  }).toList() ??
                  [],
              stats: Map<String, int>.from(p['stats'] ?? {}),
            );
          }).toList() ??
          [];

      final state = PokedexState(
        allPokemon: allPokemonList,
        filteredPokemon: allPokemonList,
        pokemonNames: List<String>.from(json['pokemonNames'] ?? []),
        searchQuery: json['searchQuery'] ?? '',
        sortOption: PokedexSortOption.values[json['sortOption'] ?? 0],
      );

      return state;
    } catch (e) {
      return const PokedexState();
    }
  }

  @override
  List<Object?> get props => [
    allPokemon,
    filteredPokemon,
    pokemonNames,
    isLoading,
    error,
    searchQuery,
    sortOption,
  ];
}

// BLoC
class PokedexBloc extends HydratedBloc<PokedexEvent, PokedexState> {
  final PokemonRepository repository;

  PokedexBloc({required this.repository}) : super(const PokedexState()) {
    on<LoadPokedex>(_onLoadPokedex);
    on<SearchPokedex>(_onSearchPokedex);
    on<SortPokedex>(_onSortPokedex);
    on<RefreshPokedex>(_onRefreshPokedex);
  }

  Future<void> _onLoadPokedex(
    LoadPokedex event,
    Emitter<PokedexState> emit,
  ) async {
    // If already loaded from cache, don't reload
    if (state.allPokemon.isNotEmpty) {
      emit(
        state.copyWith(filteredPokemon: _applyFiltersAndSort(state.allPokemon)),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final names = await repository.fetchPokemonNamesList(limit: event.limit);
      final pokemon = await repository.fetchMultiplePokemon(names);

      emit(
        state.copyWith(
          allPokemon: pokemon,
          filteredPokemon: _applyFiltersAndSort(pokemon),
          pokemonNames: names,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRefreshPokedex(
    RefreshPokedex event,
    Emitter<PokedexState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final names = state.pokemonNames.isNotEmpty
          ? state.pokemonNames
          : await repository.fetchPokemonNamesList(limit: 151);

      final pokemon = await repository.fetchMultiplePokemon(names);

      emit(
        state.copyWith(
          allPokemon: pokemon,
          filteredPokemon: _applyFiltersAndSort(pokemon),
          pokemonNames: names,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onSearchPokedex(SearchPokedex event, Emitter<PokedexState> emit) {
    final query = event.query.toLowerCase().trim();

    final filtered = query.isEmpty
        ? state.allPokemon
        : state.allPokemon.where((p) {
            final nameMatch = p.name.toLowerCase().contains(query);
            final typeMatch = p.types.any(
              (t) => t.toLowerCase().contains(query),
            );
            final abilityMatch = p.abilities.any(
              (a) => a.name.toLowerCase().contains(query),
            );
            return nameMatch || typeMatch || abilityMatch;
          }).toList();

    emit(
      state.copyWith(searchQuery: query, filteredPokemon: _applySort(filtered)),
    );
  }

  void _onSortPokedex(SortPokedex event, Emitter<PokedexState> emit) {
    emit(
      state.copyWith(
        sortOption: event.sortOption,
        filteredPokemon: _applyFiltersAndSort(state.allPokemon),
      ),
    );
  }

  List<Pokemon> _applyFiltersAndSort(List<Pokemon> pokemon) {
    final query = state.searchQuery.toLowerCase().trim();

    final filtered = query.isEmpty
        ? pokemon
        : pokemon.where((p) {
            final nameMatch = p.name.toLowerCase().contains(query);
            final typeMatch = p.types.any(
              (t) => t.toLowerCase().contains(query),
            );
            final abilityMatch = p.abilities.any(
              (a) => a.name.toLowerCase().contains(query),
            );
            return nameMatch || typeMatch || abilityMatch;
          }).toList();

    return _applySort(filtered);
  }

  List<Pokemon> _applySort(List<Pokemon> pokemon) {
    final sorted = List<Pokemon>.from(pokemon);

    switch (state.sortOption) {
      case PokedexSortOption.defaultSort:
        sorted.sort((a, b) {
          final indexA = state.pokemonNames.indexOf(a.name.toLowerCase());
          final indexB = state.pokemonNames.indexOf(b.name.toLowerCase());
          return indexA.compareTo(indexB);
        });
        break;
      case PokedexSortOption.randomized:
        sorted.shuffle();
        break;
      case PokedexSortOption.aToZ:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case PokedexSortOption.zToA:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
    }

    return sorted;
  }

  @override
  PokedexState? fromJson(Map<String, dynamic> json) {
    return PokedexState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(PokedexState state) {
    return state.toJson();
  }
}
