class SavingGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String category;
  final String? description;
  final int colorValue;

  const SavingGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.category,
    this.description,
    this.colorValue = 0xFF3B82F6,
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  bool get isAchieved => currentAmount >= targetAmount;

  SavingGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? description,
    int? colorValue,
  }) {
    return SavingGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate?.toIso8601String(),
        'category': category,
        'description': description,
        'colorValue': colorValue,
      };

  factory SavingGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingGoalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate'] as String) : null,
      category: json['category'] as String? ?? 'General Savings',
      description: json['description'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFF3B82F6,
    );
  }
}

class SavingRecordModel {
  final String id;
  final String? goalId;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final String? transactionId;

  const SavingRecordModel({
    required this.id,
    this.goalId,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.transactionId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'transactionId': transactionId,
      };

  factory SavingRecordModel.fromJson(Map<String, dynamic> json) {
    return SavingRecordModel(
      id: json['id'] as String,
      goalId: json['goalId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String? ?? 'Savings',
      description: json['description'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }
}
