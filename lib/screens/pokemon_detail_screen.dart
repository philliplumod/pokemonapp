import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../models/pokemon_ability.dart';
import '../utils/type_utils.dart';

class PokemonDetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    final imageSize = isDesktop ? 300.0 : isTablet ? 250.0 : 200.0;
    final horizontalPadding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name.toUpperCase(), style: const TextStyle(fontFamily: 'monospace')),
        
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 202, 173, 91),
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(isTablet ? 20 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: pokemon.spriteUrl.isNotEmpty
                        ? Hero(
                            tag: 'pokemon-${pokemon.name}',
                            child: Image.network(
                              pokemon.spriteUrl,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 80),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: pokemon.types
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor(t),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Text(
                                t.toUpperCase(),
                                style: TextStyle(color: readableTextColor(typeColor(t)), fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Stats', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildStatsSection(context, isDesktop),
                  const SizedBox(height: 16),
                  Text('Abilities', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildAbilitiesSection(context, isDesktop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return isDesktop || isTablet
        ? GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
            ),
            itemCount: pokemon.stats.length,
            itemBuilder: (context, index) {
              final entry = pokemon.stats.entries.toList()[index];
              return _buildStatCard(entry.key, entry.value.toString());
            },
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pokemon.stats.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key.toUpperCase(), style: const TextStyle(fontFamily: 'monospace')),
                          Text(e.value.toString(), style: const TextStyle(fontFamily: 'monospace')),
                        ],
                      ),
                    ))
                .toList(),
          );
  }

  Widget _buildStatCard(String statName, String statValue) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 192, 158, 158),
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            statName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            statValue,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesSection(BuildContext context, bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return isDesktop || isTablet
        ? GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: pokemon.abilities.length,
            itemBuilder: (context, index) {
              return _buildAbilityCard(pokemon.abilities[index]);
            },
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pokemon.abilities
                .map((a) => _buildAbilityCard(a))
                .toList(),
          );
  }

  Widget _buildAbilityCard(PokemonAbility a) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 192, 158, 158),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Text(
              a.shortEffect.isNotEmpty
                  ? a.shortEffect
                  : (a.effect.isNotEmpty ? a.effect : 'No description available.'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
