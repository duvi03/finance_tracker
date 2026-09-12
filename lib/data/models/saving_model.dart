class SavingGoalModel {
  final String id;
  final String name;
  final num targetAmount;
  final num currentAmount;
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

  num get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  num get remainingAmount => (targetAmount - currentAmount) < 0 ? 0 : (targetAmount - currentAmount);

  bool get isAchieved => currentAmount >= targetAmount;

  SavingGoalModel copyWith({
    String? id,
    String? name,
    num? targetAmount,
    num? currentAmount,
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
      targetAmount: json['targetAmount'] as num,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate'] as String) : null,
      category: json['category'] as String? ?? 'General Savings',
      description: json['description'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFF3B82F6,
    );
  }
}

enum SavingRecordType {
  deposit,
  withdrawal,
}

extension SavingRecordTypeExtension on SavingRecordType {
  String get displayName {
    switch (this) {
      case SavingRecordType.deposit:
        return 'Deposit';
      case SavingRecordType.withdrawal:
        return 'Withdrawal';
    }
  }

  bool get isDeposit => this == SavingRecordType.deposit;
  bool get isWithdrawal => this == SavingRecordType.withdrawal;
}

class SavingRecordModel {
  final String id;
  final String? goalId;
  final num amount;
  final DateTime date;
  final String category;
  final String? description;
  final String? transactionId;
  final SavingRecordType type;

  const SavingRecordModel({
    required this.id,
    this.goalId,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.transactionId,
    this.type = SavingRecordType.deposit,
  });

  SavingRecordModel copyWith({
    String? id,
    String? goalId,
    num? amount,
    DateTime? date,
    String? category,
    String? description,
    String? transactionId,
    SavingRecordType? type,
  }) {
    return SavingRecordModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'transactionId': transactionId,
        'type': type.name,
      };

  factory SavingRecordModel.fromJson(Map<String, dynamic> json) {
    return SavingRecordModel(
      id: json['id'] as String,
      goalId: json['goalId'] as String?,
      amount: json['amount'] as num,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String? ?? 'Savings',
      description: json['description'] as String?,
      transactionId: json['transactionId'] as String?,
      type: json['type'] != null
          ? SavingRecordType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => SavingRecordType.deposit,
            )
          : SavingRecordType.deposit,
    );
  }
}
