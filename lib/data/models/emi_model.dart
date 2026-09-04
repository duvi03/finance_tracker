enum EMIPaymentStatus {
  pending,
  paid,
}

class EMIPaymentModel {
  final String id;
  final String emiPlanId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final EMIPaymentStatus status;
  final String? transactionId;

  const EMIPaymentModel({
    required this.id,
    required this.emiPlanId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = EMIPaymentStatus.pending,
    this.transactionId,
  });

  bool get isPaid => status == EMIPaymentStatus.paid;

  EMIPaymentModel copyWith({
    String? id,
    String? emiPlanId,
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    EMIPaymentStatus? status,
    String? transactionId,
  }) {
    return EMIPaymentModel(
      id: id ?? this.id,
      emiPlanId: emiPlanId ?? this.emiPlanId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emiPlanId': emiPlanId,
        'installmentNumber': installmentNumber,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'paidDate': paidDate?.toIso8601String(),
        'status': status.name,
        'transactionId': transactionId,
      };

  factory EMIPaymentModel.fromJson(Map<String, dynamic> json) {
    return EMIPaymentModel(
      id: json['id'] as String,
      emiPlanId: json['emiPlanId'] as String,
      installmentNumber: json['installmentNumber'] as int,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      status: EMIPaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EMIPaymentStatus.pending,
      ),
      transactionId: json['transactionId'] as String?,
    );
  }
}

class EMIPlanModel {
  final String id;
  final String purchaseName;
  final double totalAmount;
  final int numberOfInstallments;
  final DateTime startDate;
  final double monthlyEmiAmount;
  final String category;
  final String? notes;
  final List<EMIPaymentModel> payments;
  final DateTime createdAt;

  const EMIPlanModel({
    required this.id,
    required this.purchaseName,
    required this.totalAmount,
    required this.numberOfInstallments,
    required this.startDate,
    required this.monthlyEmiAmount,
    required this.category,
    this.notes,
    required this.payments,
    required this.createdAt,
  });

  int get paidInstallments => payments.where((p) => p.isPaid).length;
  int get remainingInstallments => numberOfInstallments - paidInstallments;
  double get paidAmount => payments.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.amount);
  double get remainingAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isCompleted => remainingInstallments == 0;

  DateTime get endDate {
    return DateTime(startDate.year, startDate.month + numberOfInstallments - 1, startDate.day);
  }

  EMIPaymentModel? get nextPendingPayment {
    final pending = payments.where((p) => !p.isPaid).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first;
  }

  DateTime? get nextEmiDate => nextPendingPayment?.dueDate;

  EMIPlanModel copyWith({
    String? id,
    String? purchaseName,
    double? totalAmount,
    int? numberOfInstallments,
    DateTime? startDate,
    double? monthlyEmiAmount,
    String? category,
    String? notes,
    List<EMIPaymentModel>? payments,
    DateTime? createdAt,
  }) {
    return EMIPlanModel(
      id: id ?? this.id,
      purchaseName: purchaseName ?? this.purchaseName,
      totalAmount: totalAmount ?? this.totalAmount,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      startDate: startDate ?? this.startDate,
      monthlyEmiAmount: monthlyEmiAmount ?? this.monthlyEmiAmount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchaseName': purchaseName,
        'totalAmount': totalAmount,
        'numberOfInstallments': numberOfInstallments,
        'startDate': startDate.toIso8601String(),
        'monthlyEmiAmount': monthlyEmiAmount,
        'category': category,
        'notes': notes,
        'payments': payments.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory EMIPlanModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'] as List<dynamic>? ?? [];
    return EMIPlanModel(
      id: json['id'] as String,
      purchaseName: json['purchaseName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      numberOfInstallments: json['numberOfInstallments'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      monthlyEmiAmount: (json['monthlyEmiAmount'] as num).toDouble(),
      category: json['category'] as String? ?? 'EMI',
      notes: json['notes'] as String?,
      payments: rawPayments.map((p) => EMIPaymentModel.fromJson(p as Map<String, dynamic>)).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['startDate'] as String),
    );
  }

  static List<EMIPaymentModel> generatePaymentSchedule({
    required String emiPlanId,
    required DateTime startDate,
    required int numberOfInstallments,
    required double monthlyAmount,
  }) {
    final schedule = <EMIPaymentModel>[];
    for (int i = 0; i < numberOfInstallments; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + i, startDate.day);
      schedule.add(
        EMIPaymentModel(
          id: '${emiPlanId}_inst_${i + 1}',
          emiPlanId: emiPlanId,
          installmentNumber: i + 1,
          amount: monthlyAmount,
          dueDate: dueDate,
          status: EMIPaymentStatus.pending,
        ),
      );
    }
    return schedule;
  }
}
