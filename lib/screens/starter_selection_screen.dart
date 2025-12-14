import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/progress_bloc.dart';
import '../utils/type_utils.dart';
import 'game_menu_screen.dart';

class StarterSelectionScreen extends StatelessWidget {
  const StarterSelectionScreen({super.key});

  static const List<Map<String, dynamic>> starters = [
    {'name': 'bulbasaur', 'type': 'grass', 'description': 'The Seed Pokémon'},
    {'name': 'charmander', 'type': 'fire', 'description': 'The Lizard Pokémon'},
    {
      'name': 'squirtle',
      'type': 'water',
      'description': 'The Tiny Turtle Pokémon',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Your Starter',
          style: TextStyle(fontSize: 14),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Choose Your Partner!',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This Pokémon will be your partner in endless battles. Choose wisely!',
                      style: TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: starters.length,
                itemBuilder: (context, index) {
                  final starter = starters[index];
                  return _buildStarterCard(context, starter);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterCard(BuildContext context, Map<String, dynamic> starter) {
    final name = starter['name'] as String;
    final type = starter['type'] as String;
    final description = starter['description'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectStarter(context, name),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: TypeUtils.getTypeColor(type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TypeUtils.getTypeColor(type),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.catching_pokemon, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TypeUtils.getTypeColor(type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _selectStarter(BuildContext context, String pokemonName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Choose ${pokemonName.toUpperCase()}?',
          style: const TextStyle(fontSize: 14),
        ),
        content: const Text(
          'This will be your starting Pokémon. Are you ready to begin your journey?',
          style: TextStyle(fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressBloc>().add(SelectStarter(pokemonName));
              Navigator.pop(dialogContext);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GameMenuScreen()),
              );
            },
            child: const Text('Confirm', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
