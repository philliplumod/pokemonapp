import 'package:flutter/material.dart';

class TypeUtils {
  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return Colors.brown.shade300;
      case 'fire':
        return Colors.red.shade400;
      case 'water':
        return Colors.blue.shade400;
      case 'electric':
        return Colors.yellow.shade600;
      case 'grass':
        return Colors.green.shade600;
      case 'ice':
        return Colors.cyan.shade200;
      case 'fighting':
        return Colors.orange.shade700;
      case 'poison':
        return Colors.purple.shade400;
      case 'ground':
        return Colors.brown.shade500;
      case 'flying':
        return Colors.indigo.shade200;
      case 'psychic':
        return Colors.pink.shade300;
      case 'bug':
        return Colors.lightGreen.shade600;
      case 'rock':
        return Colors.grey.shade600;
      case 'ghost':
        return Colors.deepPurple.shade400;
      case 'dragon':
        return Colors.indigo.shade700;
      case 'dark':
        return Colors.grey.shade800;
      case 'steel':
        return Colors.blueGrey.shade300;
      case 'fairy':
        return Colors.pink.shade200;
      default:
        return Colors.grey.shade400;
    }
  }

  static Color readableTextColor(Color background) {
    // computeLuminance returns 0..1 where higher means lighter color
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

// Legacy function support (for backward compatibility)
Color typeColor(String type) => TypeUtils.getTypeColor(type);
Color readableTextColor(Color background) =>
    TypeUtils.readableTextColor(background);
