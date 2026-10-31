import 'package:flutter/material.dart';
import 'package:hello_ledger/data/app_database.dart';

/// Recommended icons to choose from when adding or editing a category. The database stores the key here (e.g. 'flight'),
/// so changing the icon style later does not affect old data; but never rename a key that is already in use.
const Map<String, IconData> recommendedIcons = {
  // Food
  'restaurant': Icons.restaurant,
  'coffee': Icons.local_cafe,
  'fastfood': Icons.fastfood,
  'grocery': Icons.local_grocery_store,
  'cake': Icons.cake,
  // Transport and travel
  'bus': Icons.directions_bus,
  'car': Icons.directions_car,
  'train': Icons.train,
  'gas': Icons.local_gas_station,
  'flight': Icons.flight,
  'luggage': Icons.luggage,
  'beach': Icons.beach_access,
  'hotel': Icons.hotel,
  // Shopping and entertainment
  'shopping': Icons.shopping_bag_outlined,
  'clothes': Icons.checkroom,
  'games': Icons.sports_esports,
  'movie': Icons.movie_outlined,
  'music': Icons.music_note,
  'celebration': Icons.celebration,
  'fitness': Icons.fitness_center,
  'spa': Icons.spa_outlined,
  // Home and bills
  'home': Icons.home_outlined,
  'bolt': Icons.bolt,
  'wifi': Icons.wifi,
  'phone': Icons.phone_android,
  'build': Icons.build_outlined,
  'pets': Icons.pets,
  'child': Icons.child_care,
  // Health and learning
  'medical': Icons.medical_services_outlined,
  'school': Icons.school_outlined,
  'book': Icons.menu_book,
  // Money
  'payments': Icons.payments_outlined,
  'work': Icons.work_outline,
  'savings': Icons.savings_outlined,
  'trending_up': Icons.trending_up,
  'gift': Icons.card_giftcard,
  'volunteer': Icons.volunteer_activism,
  'favorite': Icons.favorite_border,
  'more': Icons.more_horiz,
};

/// Default categories (old data that has no icon key stored yet) map from their name to an icon key.
const Map<String, String> _defaultKeyByName = {
  '餐飲': 'restaurant',
  '交通': 'bus',
  '購物': 'shopping',
  '娛樂': 'games',
  '居住': 'home',
  '醫療': 'medical',
  '教育': 'school',
  '薪水': 'payments',
  '獎金': 'gift',
  '其他': 'more',
};

/// The icon key this category actually uses.
String categoryIconKey(Category category) =>
    category.icon ?? _defaultKeyByName[category.name] ?? 'more';

/// The icon for a category. A null [category] means "uncategorized".
IconData categoryIcon(Category? category) {
  if (category == null) return Icons.help_outline;
  return recommendedIcons[categoryIconKey(category)] ?? Icons.label_outline;
}
