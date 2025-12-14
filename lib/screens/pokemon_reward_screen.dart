import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bloc/progress_bloc.dart';

class PokemonRewardScreen extends StatefulWidget {
  const PokemonRewardScreen({super.key});

  @override
  State<PokemonRewardScreen> createState() => _PokemonRewardScreenState();
}

class _PokemonRewardScreenState extends State<PokemonRewardScreen> {
  List<String> rewardOptions = [];
  String? selectedPokemon;
  bool _loading = true;

  // Pokemon ID ranges by rarity tier - dynamically fetched from API
  static const Map<String, List<int>> rarityRanges = {
    'common': [
      16,
      17,
      19,
      20,
      21,
      41,
      13,
      10,
      43,
      46,
      60,
      69,
      72,
      74,
      88,
      90,
      96,
      98,
      118,
      129,
    ],
    'uncommon': [
      11,
      23,
      27,
      35,
      37,
      39,
      48,
      50,
      52,
      54,
      56,
      58,
      63,
      66,
      77,
      79,
      81,
      84,
      86,
      92,
      95,
      100,
      102,
      108,
      109,
      116,
      120,
    ],
    'rare': [
      25,
      67,
      75,
      93,
      64,
      106,
      107,
      113,
      114,
      115,
      122,
      123,
      124,
      125,
      126,
      127,
      128,
    ],
    'epic': [
      59,
      62,
      65,
      68,
      71,
      76,
      80,
      82,
      83,
      85,
      87,
      89,
      91,
      94,
      99,
      103,
      105,
      112,
      119,
      121,
      130,
      131,
      132,
      133,
      134,
      135,
      136,
      137,
      138,
      139,
      140,
      141,
      142,
      143,
      147,
      148,
    ],
    'legendary': [144, 145, 146, 149, 150, 151],
  };

  @override
  void initState() {
    super.initState();
    _generateRewardOptions();
  }

  Future<void> _generateRewardOptions() async {
    final random = Random();
    final progress = context.read<ProgressBloc>().state;
    final wins = progress.wins;

    // Determine reward tier based on total wins
    List<int> pokemonIds;
    if (wins < 5) {
      pokemonIds = rarityRanges['common']!;
    } else if (wins < 10) {
      pokemonIds = [...rarityRanges['common']!, ...rarityRanges['uncommon']!];
    } else if (wins < 15) {
      pokemonIds = [...rarityRanges['uncommon']!, ...rarityRanges['rare']!];
    } else if (wins < 25) {
      pokemonIds = [...rarityRanges['rare']!, ...rarityRanges['epic']!];
    } else {
      pokemonIds = [...rarityRanges['epic']!, ...rarityRanges['legendary']!];
    }

    // Select 3 random Pokemon IDs
    final selectedIds = <int>[];
    final availableIds = List<int>.from(pokemonIds);

    for (int i = 0; i < 3 && availableIds.isNotEmpty; i++) {
      final index = random.nextInt(availableIds.length);
      selectedIds.add(availableIds[index]);
      availableIds.removeAt(index);
    }

    // Fetch Pokemon names from API
    final names = <String>[];
    for (final id in selectedIds) {
      try {
        final response = await http.get(
          Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          names.add(data['name'] as String);
        }
      } catch (e) {
        debugPrint('Error fetching Pokemon $id: $e');
      }
    }

    if (mounted) {
      setState(() {
        rewardOptions = names;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Pokémon!', style: TextStyle(fontSize: 14)),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose Your Reward!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick 1 of 3 Pokémon',
                    style: TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: rewardOptions.isEmpty
                        ? const Center(child: Text('No Pokemon available'))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  childAspectRatio: 2.5,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: rewardOptions.length,
                            itemBuilder: (context, index) {
                              final pokemon = rewardOptions[index];
                              final isSelected = selectedPokemon == pokemon;

                              return Card(
                                elevation: isSelected ? 8 : 2,
                                color: isSelected
                                    ? Colors.amber.shade100
                                    : Colors.white,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedPokemon = pokemon;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 32,
                                          ),
                                        if (!isSelected)
                                          const Icon(
                                            Icons.catching_pokemon,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            pokemon.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: selectedPokemon == null
                        ? null
                        : () {
                            context.read<ProgressBloc>().add(
                              AddPokemon(selectedPokemon!),
                            );
                            Navigator.of(context).pop(true);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'CLAIM POKÉMON',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
