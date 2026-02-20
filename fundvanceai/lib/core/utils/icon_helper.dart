import 'package:flutter/material.dart';

/// Helper class for mapping category icon names to Flutter IconData
class IconHelper {
  /// Map of icon names to IconData
  static final Map<String, IconData> _iconMap = {
    // Expense Categories
    'restaurant': Icons.restaurant,
    'shopping_cart': Icons.shopping_cart,
    'receipt': Icons.receipt,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'home': Icons.home,
    'school': Icons.school,
    'face': Icons.face,
    'more_horiz': Icons.more_horiz,
    'directions_car': Icons.directions_car,
    'local_gas_station': Icons.local_gas_station,
    'medical_services': Icons.medical_services,
    'sports_esports': Icons.sports_esports,
    'flight': Icons.flight,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'fastfood': Icons.fastfood,
    'delivery_dining': Icons.delivery_dining,
    
    // Income Categories
    'work': Icons.work,
    'business': Icons.business,
    'person_add': Icons.person_add,
    'trending_up': Icons.trending_up,
    'attach_money': Icons.attach_money,
    'money': Icons.attach_money,
    'account_balance_wallet': Icons.account_balance_wallet,
    'star': Icons.star,
    'account_balance': Icons.account_balance,
    'elderly': Icons.elderly,
    'card_giftcard': Icons.card_giftcard,
    'directions_run': Icons.directions_run,
    'library_music': Icons.library_music,
    
    // Utilities
    'phone_android': Icons.phone_android,
    'wifi': Icons.wifi,
    'water_drop': Icons.water_drop,
    'bolt': Icons.bolt,
    'payment': Icons.payment,
    'savings': Icons.savings,
    'pets': Icons.pets,
    'spa': Icons.spa,
    'fitness_center': Icons.fitness_center,
    'checkroom': Icons.checkroom,
    'style': Icons.style,
    'phone': Icons.phone,
    'computer': Icons.computer,
    'apple': Icons.apple,
    'credit_card': Icons.credit_card,
    
    // Default fallback
    'category': Icons.category,
  };

  /// Get IconData from icon name string
  static IconData getIconData(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }
    return _iconMap[iconName] ?? Icons.category;
  }

  /// Get Icon widget from icon name string
  static Icon getIcon(String? iconName, {double? size, Color? color}) {
    return Icon(
      getIconData(iconName),
      size: size,
      color: color,
    );
  }

  /// Convert hex color string to Color
  static Color hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
