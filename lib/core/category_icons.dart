import 'package:flutter/material.dart';

/// 預設類別對應的簡單圖示。找不到（例如之後自訂的類別）就用通用圖示。
IconData categoryIcon(String? name) {
  return switch (name) {
    null => Icons.help_outline,
    '餐飲' => Icons.restaurant,
    '交通' => Icons.directions_bus,
    '購物' => Icons.shopping_bag_outlined,
    '娛樂' => Icons.sports_esports,
    '居住' => Icons.home_outlined,
    '醫療' => Icons.medical_services_outlined,
    '教育' => Icons.school_outlined,
    '薪水' => Icons.payments_outlined,
    '獎金' => Icons.card_giftcard,
    '其他' => Icons.more_horiz,
    _ => Icons.label_outline,
  };
}
