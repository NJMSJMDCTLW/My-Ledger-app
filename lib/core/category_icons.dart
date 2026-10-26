import 'package:flutter/material.dart';
import 'package:hello_ledger/data/app_database.dart';

/// 新增、編輯分類時可以挑的推薦圖示。資料庫裡存的是這裡的 key（例如 'flight'），
/// 所以日後換圖示樣式不會影響舊資料；但已經在用的 key 不要改名。
const Map<String, IconData> recommendedIcons = {
  // 飲食
  'restaurant': Icons.restaurant,
  'coffee': Icons.local_cafe,
  'fastfood': Icons.fastfood,
  'grocery': Icons.local_grocery_store,
  'cake': Icons.cake,
  // 交通與旅行
  'bus': Icons.directions_bus,
  'car': Icons.directions_car,
  'train': Icons.train,
  'gas': Icons.local_gas_station,
  'flight': Icons.flight,
  'luggage': Icons.luggage,
  'beach': Icons.beach_access,
  'hotel': Icons.hotel,
  // 購物與娛樂
  'shopping': Icons.shopping_bag_outlined,
  'clothes': Icons.checkroom,
  'games': Icons.sports_esports,
  'movie': Icons.movie_outlined,
  'music': Icons.music_note,
  'celebration': Icons.celebration,
  'fitness': Icons.fitness_center,
  'spa': Icons.spa_outlined,
  // 居家與帳單
  'home': Icons.home_outlined,
  'bolt': Icons.bolt,
  'wifi': Icons.wifi,
  'phone': Icons.phone_android,
  'build': Icons.build_outlined,
  'pets': Icons.pets,
  'child': Icons.child_care,
  // 健康與學習
  'medical': Icons.medical_services_outlined,
  'school': Icons.school_outlined,
  'book': Icons.menu_book,
  // 金錢
  'payments': Icons.payments_outlined,
  'work': Icons.work_outline,
  'savings': Icons.savings_outlined,
  'trending_up': Icons.trending_up,
  'gift': Icons.card_giftcard,
  'volunteer': Icons.volunteer_activism,
  'favorite': Icons.favorite_border,
  'more': Icons.more_horiz,
};

/// 預設類別（還沒有存圖示 key 的舊資料）用名稱對應到圖示 key。
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

/// 這個類別實際使用的圖示 key。
String categoryIconKey(Category category) =>
    category.icon ?? _defaultKeyByName[category.name] ?? 'more';

/// 類別的圖示。[category] 是 null 代表「未分類」。
IconData categoryIcon(Category? category) {
  if (category == null) return Icons.help_outline;
  return recommendedIcons[categoryIconKey(category)] ?? Icons.label_outline;
}
