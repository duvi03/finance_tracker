enum TransactionType {
  income,
  expense,
  saving,
  gold,
  emi,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.saving:
        return 'Saving';
      case TransactionType.gold:
        return 'Gold Investment';
      case TransactionType.emi:
        return 'EMI Payment';
    }
  }

  bool get isIncome => this == TransactionType.income;
  bool get isDeductionFromCash => this != TransactionType.income;
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String categoryId;
  final String? notes;
  final String? sourceId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.categoryId,
    this.notes,
    this.sourceId,
    required this.createdAt,
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? categoryId,
    String? notes,
    String? sourceId,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.name,
        'categoryId': categoryId,
        'notes': notes,
        'sourceId': sourceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      notes: json['notes'] as String?,
      sourceId: json['sourceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['date'] as String),
    );
  }
}
