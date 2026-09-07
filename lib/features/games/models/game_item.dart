// ==============================================================================
// NIRVANA - GameItem Model
// Description: Offline bundled visual items for Remember Objects and Grocery Memory
// ==============================================================================

import 'package:flutter/material.dart';

class GameItem {
  final String id;
  final String name;
  final String emoji;
  final IconData fallbackIcon;
  final Color tintColor;
  final String category;

  const GameItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.fallbackIcon,
    required this.tintColor,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Default curated catalogue of familiar everyday items
  static const List<GameItem> defaultEverydayItems = [
    GameItem(
      id: 'item_apple',
      name: 'Fresh Apple',
      emoji: '🍎',
      fallbackIcon: Icons.apple,
      tintColor: Color(0xFFD32F2F),
      category: 'fruit',
    ),
    GameItem(
      id: 'item_key',
      name: 'House Key',
      emoji: '🔑',
      fallbackIcon: Icons.vpn_key_rounded,
      tintColor: Color(0xFFF57C00),
      category: 'household',
    ),
    GameItem(
      id: 'item_cup',
      name: 'Tea Cup',
      emoji: '☕',
      fallbackIcon: Icons.local_cafe_rounded,
      tintColor: Color(0xFF795548),
      category: 'kitchen',
    ),
    GameItem(
      id: 'item_book',
      name: 'Story Book',
      emoji: '📖',
      fallbackIcon: Icons.menu_book_rounded,
      tintColor: Color(0xFF1976D2),
      category: 'leisure',
    ),
    GameItem(
      id: 'item_glasses',
      name: 'Reading Glasses',
      emoji: '👓',
      fallbackIcon: Icons.visibility_rounded,
      tintColor: Color(0xFF455A64),
      category: 'personal',
    ),
    GameItem(
      id: 'item_flower',
      name: 'Garden Rose',
      emoji: '🌹',
      fallbackIcon: Icons.local_florist_rounded,
      tintColor: Color(0xFFE91E63),
      category: 'garden',
    ),
    GameItem(
      id: 'item_clock',
      name: 'Wall Clock',
      emoji: '⏰',
      fallbackIcon: Icons.access_time_filled_rounded,
      tintColor: Color(0xFF00897B),
      category: 'household',
    ),
    GameItem(
      id: 'item_hat',
      name: 'Sun Hat',
      emoji: '👒',
      fallbackIcon: Icons.beach_access_rounded,
      tintColor: Color(0xFF8D6E63),
      category: 'clothing',
    ),
    GameItem(
      id: 'item_camera',
      name: 'Photo Camera',
      emoji: '📷',
      fallbackIcon: Icons.camera_alt_rounded,
      tintColor: Color(0xFF5E35B1),
      category: 'leisure',
    ),
    GameItem(
      id: 'item_umbrella',
      name: 'Blue Umbrella',
      emoji: '☂️',
      fallbackIcon: Icons.umbrella_rounded,
      tintColor: Color(0xFF0288D1),
      category: 'clothing',
    ),
  ];

  /// Default curated catalogue of familiar groceries
  static const List<GameItem> defaultGroceryItems = [
    GameItem(
      id: 'groc_bread',
      name: 'Whole Wheat Bread',
      emoji: '🍞',
      fallbackIcon: Icons.bakery_dining_rounded,
      tintColor: Color(0xFF8D6E63),
      category: 'bakery',
    ),
    GameItem(
      id: 'groc_milk',
      name: 'Fresh Milk',
      emoji: '🥛',
      fallbackIcon: Icons.local_drink_rounded,
      tintColor: Color(0xFF0288D1),
      category: 'dairy',
    ),
    GameItem(
      id: 'groc_bananas',
      name: 'Ripe Bananas',
      emoji: '🍌',
      fallbackIcon: Icons.eco_rounded,
      tintColor: Color(0xFFFBC02D),
      category: 'produce',
    ),
    GameItem(
      id: 'groc_eggs',
      name: 'Farm Eggs',
      emoji: '🥚',
      fallbackIcon: Icons.egg_rounded,
      tintColor: Color(0xFFFFB74D),
      category: 'dairy',
    ),
    GameItem(
      id: 'groc_tea',
      name: 'Green Tea Box',
      emoji: '🍵',
      fallbackIcon: Icons.emoji_food_beverage_rounded,
      tintColor: Color(0xFF388E3C),
      category: 'pantry',
    ),
    GameItem(
      id: 'groc_honey',
      name: 'Pure Honey',
      emoji: '🍯',
      fallbackIcon: Icons.breakfast_dining_rounded,
      tintColor: Color(0xFFFFA000),
      category: 'pantry',
    ),
    GameItem(
      id: 'groc_tomatoes',
      name: 'Red Tomatoes',
      emoji: '🍅',
      fallbackIcon: Icons.circle,
      tintColor: Color(0xFFE53935),
      category: 'produce',
    ),
    GameItem(
      id: 'groc_cheese',
      name: 'Cheddar Cheese',
      emoji: '🧀',
      fallbackIcon: Icons.lunch_dining_rounded,
      tintColor: Color(0xFFFFB300),
      category: 'dairy',
    ),
    GameItem(
      id: 'groc_oranges',
      name: 'Sweet Oranges',
      emoji: '🍊',
      fallbackIcon: Icons.circle,
      tintColor: Color(0xFFFB8C00),
      category: 'produce',
    ),
    GameItem(
      id: 'groc_potatoes',
      name: 'Golden Potatoes',
      emoji: '🥔',
      fallbackIcon: Icons.crop_square_rounded,
      tintColor: Color(0xFF8D6E63),
      category: 'produce',
    ),
  ];
}
