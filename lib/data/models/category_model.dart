import 'package:flutter/material.dart';

enum CategoryType { income, expense, both }

class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final CategoryType type;
  final bool isCustom;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    required this.type,
    this.isCustom = false,
  });

  IconData get icon {
    switch (id) {
      case 'salary':
        return Icons.account_balance_wallet;
      case 'freelance':
        return Icons.laptop_mac;
      case 'bonus':
        return Icons.stars;
      case 'gift':
        return Icons.card_giftcard;
      case 'borrow_returned':
        return Icons.assignment_return;
      case 'other_income':
        return Icons.attach_money;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'rent':
        return Icons.home;
      case 'emi_expense':
        return Icons.credit_card;
      case 'savings_allocation':
        return Icons.savings;
      case 'gold_purchase':
        return Icons.monetization_on;
      default:
        return Icons.category;
    }
  }
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'colorValue': colorValue,
        'type': type.name,
        'isCustom': isCustom,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int? ?? Icons.category.codePoint,
      iconFontFamily: json['iconFontFamily'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFF0F766E,
      type: CategoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CategoryType.expense,
      ),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  static List<CategoryModel> get defaultCategories => [
        // Income
        const CategoryModel(
          id: 'salary',
          name: 'Salary',
          iconCodePoint: 0xe043, // account_balance_wallet
          colorValue: 0xFF10B981,
          type: CategoryType.income,
        ),
        const CategoryModel(
          id: 'freelance',
          name: 'Freelance',
          iconCodePoint: 0xe39d, // laptop_mac
          colorValue: 0xFF06B6D4,
          type: CategoryType.income,
        ),
        const CategoryModel(
          id: 'bonus',
          name: 'Bonus',
          iconCodePoint: 0xe5f9, // stars
          colorValue: 0xFF8B5CF6,
          type: CategoryType.income,
        ),
        const CategoryModel(
          id: 'gift',
          name: 'Gift',
          iconCodePoint: 0xe153, // card_giftcard
          colorValue: 0xFFEC4899,
          type: CategoryType.income,
        ),
        const CategoryModel(
          id: 'borrow_returned',
          name: 'Debt Repaid',
          iconCodePoint: 0xf0542, // assignment_return
          colorValue: 0xFF14B8A6,
          type: CategoryType.income,
        ),
        const CategoryModel(
          id: 'other_income',
          name: 'Other Income',
          iconCodePoint: 0xe040, // attach_money
          colorValue: 0xFF64748B,
          type: CategoryType.income,
        ),

        // Expense
        const CategoryModel(
          id: 'food',
          name: 'Food & Snacks',
          iconCodePoint: 0xe532, // restaurant
          colorValue: 0xFFEF4444,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'transport',
          name: 'Transportation',
          iconCodePoint: 0xe1d7, // directions_car
          colorValue: 0xFFF97316,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'shopping',
          name: 'Shopping',
          iconCodePoint: 0xe59c, // shopping_bag
          colorValue: 0xFFEC4899,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'bills',
          name: 'Bills & Utilities',
          iconCodePoint: 0xe52e, // receipt_long
          colorValue: 0xFFEAB308,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'entertainment',
          name: 'Entertainment',
          iconCodePoint: 0xe40f, // movie
          colorValue: 0xFF8B5CF6,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'health',
          name: 'Health & Medical',
          iconCodePoint: 0xe3ab, // medical_services
          colorValue: 0xFF06B6D4,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'education',
          name: 'Education',
          iconCodePoint: 0xe559, // school
          colorValue: 0xFF3B82F6,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'rent',
          name: 'Rent & Housing',
          iconCodePoint: 0xe318, // home
          colorValue: 0xFF6366F1,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'emi_expense',
          name: 'EMI / Installment',
          iconCodePoint: 0xe19f, // credit_card
          colorValue: 0xFFF97316,
          type: CategoryType.expense,
        ),
        const CategoryModel(
          id: 'savings_allocation',
          name: 'Savings Deposit',
          iconCodePoint: 0xe58b, // savings
          colorValue: 0xFF3B82F6,
          type: CategoryType.both,
        ),
        const CategoryModel(
          id: 'gold_purchase',
          name: 'Gold Investment',
          iconCodePoint: 0xe5e1, // diamond / monetization_on
          colorValue: 0xFFF59E0B,
          type: CategoryType.both,
        ),
        const CategoryModel(
          id: 'other_expense',
          name: 'Other Expense',
          iconCodePoint: 0xe3fe, // more_horiz
          colorValue: 0xFF64748B,
          type: CategoryType.expense,
        ),
      ];
}
