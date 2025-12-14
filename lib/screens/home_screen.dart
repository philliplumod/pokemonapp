import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pokedex_bloc.dart';
import '../models/pokemon.dart';
import '../utils/type_utils.dart';
import '../utils/dark_mode.dart';
import 'pokemon_detail_screen.dart';

enum SortOption { defaultSort, randomized, aToZ, zToA }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<PokedexBloc>().add(SearchPokedex(_searchController.text));
  }

  void _setSortOption(PokedexSortOption option) {
    context.read<PokedexBloc>().add(SortPokedex(option));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon App Wiki'),
        actions: [
          // Sort dropdown
          PopupMenuButton<PokedexSortOption>(
            onSelected: _setSortOption,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<PokedexSortOption>>[
                  const PopupMenuItem<PokedexSortOption>(
                    value: PokedexSortOption.defaultSort,
                    child: Text('Default'),
                  ),
                  const PopupMenuItem<PokedexSortOption>(
                    value: PokedexSortOption.randomized,
                    child: Text('Randomized'),
                  ),
                  const PopupMenuItem<PokedexSortOption>(
                    value: PokedexSortOption.aToZ,
                    child: Text('A-Z'),
                  ),
                  const PopupMenuItem<PokedexSortOption>(
                    value: PokedexSortOption.zToA,
                    child: Text('Z-A'),
                  ),
                ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Icon(Icons.sort)),
            ),
          ),
          // Dark mode toggle
          ValueListenableBuilder(
            valueListenable: DarkModeController.instance.mode,
            builder: (context, ThemeMode mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Switch to light' : 'Switch to dark',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => DarkModeController.instance.toggle(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or type (e.g. "fire")',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<PokedexBloc, PokedexState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<PokedexBloc>().add(RefreshPokedex()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildListView(state.filteredPokemon);
        },
      ),
    );
  }

  Widget _buildListView(List<Pokemon> pokemonList) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Determine grid layout based on screen size
    int crossAxisCount;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final widget = crossAxisCount == 1
        ? _buildListViewList(pokemonList)
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isDesktop ? 1.2 : 1.0,
            ),
            itemCount: pokemonList.length,
            itemBuilder: (context, index) {
              final p = pokemonList[index];
              return _buildPokemonCard(p);
            },
          );

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PokedexBloc>().add(RefreshPokedex());
      },
      child: widget,
    );
  }

  Widget _buildListViewList(List<Pokemon> pokemonList) {
    final listView = ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        final p = pokemonList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: p.spriteUrl.isNotEmpty
                ? Hero(
                    tag: 'pokemon-${p.name}',
                    child: Image.network(
                      p.spriteUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.broken_image),
                    ),
                  )
                : const SizedBox(width: 56, height: 56),
            title: Text(
              p.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Wrap(
              spacing: 8,
              children: p.types
                  .map(
                    (t) => Chip(
                      backgroundColor: typeColor(t),
                      label: Text(
                        t.toUpperCase(),
                        style: TextStyle(
                          color: readableTextColor(typeColor(t)),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PokemonDetailScreen(pokemon: p),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        );
      },
    );

    return listView;
  }

  Widget _buildPokemonCard(Pokemon p) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PokemonDetailScreen(pokemon: p)),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 12 : 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (p.spriteUrl.isNotEmpty)
                Hero(
                  tag: 'pokemon-${p.name}',
                  child: Image.network(
                    p.spriteUrl,
                    width: isDesktop ? 100 : 80,
                    height: isDesktop ? 100 : 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                p.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isDesktop ? 14 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: p.types
                    .map(
                      (t) => Chip(
                        backgroundColor: typeColor(t),
                        padding: EdgeInsets.zero,
                        label: Text(
                          t.toUpperCase(),
                          style: TextStyle(
                            color: readableTextColor(typeColor(t)),
                            fontWeight: FontWeight.w600,
                            fontSize: isDesktop ? 10 : 9,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
