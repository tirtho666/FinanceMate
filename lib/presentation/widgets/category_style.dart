import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

@immutable
class CategoryStyle {
  const CategoryStyle({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  static const List<String> allCategories = <String>[
    'Groceries',
    'Dining Out',
    'Transportation',
    'Shopping',
    'Rent & Utilities',
    'Bills',
    'Health',
    'Education',
    'Entertainment',
    'Travel',
    'Salary',
    'Gifts',
  ];

  static CategoryStyle forName(String category) {
    switch (category.trim().toLowerCase()) {
      case 'groceries':
        return const CategoryStyle(
          icon: Icons.shopping_cart_outlined,
          background: Color(0xFF66BB6A),
          foreground: Color(0xFFFFFFFF),
        );
      case 'dining out':
        return const CategoryStyle(
          icon: Icons.restaurant_outlined,
          background: Color(0xFFFF8A65),
          foreground: Color(0xFFFFFFFF),
        );
      case 'transportation':
        return const CategoryStyle(
          icon: Icons.directions_car_outlined,
          background: Color(0xFF42A5F5),
          foreground: Color(0xFFFFFFFF),
        );
      case 'shopping':
        return const CategoryStyle(
          icon: Icons.shopping_bag_outlined,
          background: Color(0xFFEF5350),
          foreground: Color(0xFFFFFFFF),
        );
      case 'rent & utilities':
        return const CategoryStyle(
          icon: Icons.home_outlined,
          background: Color(0xFFAB47BC),
          foreground: Color(0xFFFFFFFF),
        );
      case 'bills':
        return const CategoryStyle(
          icon: Icons.lightbulb_outline,
          background: Color(0xFFFFCA28),
          foreground: Color(0xFFFFFFFF),
        );
      case 'health':
        return const CategoryStyle(
          icon: Icons.medical_services_outlined,
          background: Color(0xFF26A69A),
          foreground: Color(0xFFFFFFFF),
        );
      case 'education':
        return const CategoryStyle(
          icon: Icons.menu_book_outlined,
          background: Color(0xFF757575),
          foreground: Color(0xFFFFFFFF),
        );
      case 'entertainment':
        return const CategoryStyle(
          icon: Icons.movie_outlined,
          background: Color(0xFF8D6E63),
          foreground: Color(0xFFFFFFFF),
        );
      case 'travel':
        return const CategoryStyle(
          icon: Icons.flight_outlined,
          background: Color(0xFF26C6DA),
          foreground: Color(0xFFFFFFFF),
        );
      case 'salary':
        return const CategoryStyle(
          icon: Icons.payments_outlined,
          background: Color(0xFFEC407A),
          foreground: Color(0xFFFFFFFF),
        );
      case 'gifts':
        return const CategoryStyle(
          icon: Icons.card_giftcard_outlined,
          background: Color(0xFFC62828),
          foreground: Color(0xFFFFFFFF),
        );
      case 'food':
        return const CategoryStyle(
          icon: Icons.restaurant_outlined,
          background: Color(0xFFFFE4C7),
          foreground: Color(0xFFE8A03C),
        );
      case 'transport':
        return const CategoryStyle(
          icon: Icons.directions_bus_outlined,
          background: Color(0xFFD9ECFB),
          foreground: Color(0xFF3D8BD4),
        );
      case 'fuel':
        return const CategoryStyle(
          icon: Icons.local_gas_station_outlined,
          background: Color(0xFFFFE4C7),
          foreground: Color(0xFFE8A03C),
        );
      case 'rent':
        return const CategoryStyle(
          icon: Icons.home_outlined,
          background: Color(0xFFFFE4C7),
          foreground: Color(0xFFE8A03C),
        );
      default:
        return const CategoryStyle(
          icon: Icons.category_outlined,
          background: Color(0xFFD6E4EF),
          foreground: AppPalette.primary,
        );
    }
  }
}
