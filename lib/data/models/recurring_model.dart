import 'package:finance_tracker/data/models/transaction_model.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String get label {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}

class RecurringRuleModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type; // income or expense
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String categoryId;
  final String? description;
  final DateTime? lastGeneratedDate;
  final bool isActive;

  const RecurringRuleModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.categoryId,
    this.description,
    this.lastGeneratedDate,
    this.isActive = true,
  });

  RecurringRuleModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? description,
    DateTime? lastGeneratedDate,
    bool? isActive,
  }) {
    return RecurringRuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'categoryId': categoryId,
        'description': description,
        'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
        'isActive': isActive,
      };

  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) {
    return RecurringRuleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
      lastGeneratedDate: json['lastGeneratedDate'] != null
          ? DateTime.parse(json['lastGeneratedDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
