enum GoldUnit {
  gram,
  milligram,
}

extension GoldUnitExtension on GoldUnit {
  String get label {
    switch (this) {
      case GoldUnit.gram:
        return 'g';
      case GoldUnit.milligram:
        return 'mg';
    }
  }
}

enum GoldEntryType {
  buy,
  sell,
}

extension GoldEntryTypeExtension on GoldEntryType {
  String get displayName {
    switch (this) {
      case GoldEntryType.buy:
        return 'Buy Gold';
      case GoldEntryType.sell:
        return 'Sell Gold';
    }
  }

  bool get isBuy => this == GoldEntryType.buy;
  bool get isSell => this == GoldEntryType.sell;
}

class GoldInvestmentModel {
  final String id;
  final num amountInr;
  final num quantityInGrams;
  final GoldUnit inputUnit;
  final num inputQuantity;
  final DateTime purchaseDate;
  final num ratePerGram;
  final String? notes;
  final String? transactionId;
  final GoldEntryType type;
  final num? realizedProfitLoss;

  const GoldInvestmentModel({
    required this.id,
    required this.amountInr,
    required this.quantityInGrams,
    required this.inputUnit,
    required this.inputQuantity,
    required this.purchaseDate,
    required this.ratePerGram,
    this.notes,
    this.transactionId,
    this.type = GoldEntryType.buy,
    this.realizedProfitLoss,
  });

  GoldInvestmentModel copyWith({
    String? id,
    num? amountInr,
    double? quantityInGrams,
    GoldUnit? inputUnit,
    double? inputQuantity,
    DateTime? purchaseDate,
    double? ratePerGram,
    String? notes,
    String? transactionId,
    GoldEntryType? type,
    num? realizedProfitLoss,
  }) {
    return GoldInvestmentModel(
      id: id ?? this.id,
      amountInr: amountInr ?? this.amountInr,
      quantityInGrams: quantityInGrams ?? this.quantityInGrams,
      inputUnit: inputUnit ?? this.inputUnit,
      inputQuantity: inputQuantity ?? this.inputQuantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      ratePerGram: ratePerGram ?? this.ratePerGram,
      notes: notes ?? this.notes,
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      realizedProfitLoss: realizedProfitLoss ?? this.realizedProfitLoss,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountInr': amountInr,
        'quantityInGrams': quantityInGrams,
        'inputUnit': inputUnit.name,
        'inputQuantity': inputQuantity,
        'purchaseDate': purchaseDate.toIso8601String(),
        'ratePerGram': ratePerGram,
        'notes': notes,
        'transactionId': transactionId,
        'type': type.name,
        'realizedProfitLoss': realizedProfitLoss,
      };

  factory GoldInvestmentModel.fromJson(Map<String, dynamic> json) {
    final unit = GoldUnit.values.firstWhere(
      (e) => e.name == json['inputUnit'],
      orElse: () => GoldUnit.gram,
    );
    final type = json['type'] != null
        ? GoldEntryType.values.firstWhere(
            (e) => e.name == json['type'],
            orElse: () => GoldEntryType.buy,
          )
        : GoldEntryType.buy;

    return GoldInvestmentModel(
      id: json['id'] as String,
      amountInr: json['amountInr'] as num,
      quantityInGrams: json['quantityInGrams'] as num,
      inputUnit: unit,
      inputQuantity: (json['inputQuantity'] as num?)?.toDouble() ??
          json['quantityInGrams'] as num,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      ratePerGram: json['ratePerGram'] as num,
      notes: json['notes'] as String?,
      transactionId: json['transactionId'] as String?,
      type: type,
      realizedProfitLoss: json['realizedProfitLoss'] as num?,
    );
  }

  static num normalizeToGrams(num quantity, GoldUnit unit) {
    if (unit == GoldUnit.milligram) {
      return quantity / 1000.0;
    }
    return quantity;
  }

  bool get isBuy => type == GoldEntryType.buy;
  bool get isSell => type == GoldEntryType.sell;
  num get amount => amountInr;
  num get grams => quantityInGrams;
  DateTime get date => purchaseDate;
}

enum GoldEmiType {
  borrowLoan, // Borrow loan with interest for purchase of gold
  investmentScheme, // Gold accumulation / jeweler chit scheme giving bonus/interest profit
}

extension GoldEmiTypeExtension on GoldEmiType {
  String get displayName {
    switch (this) {
      case GoldEmiType.borrowLoan:
        return 'Gold Borrow Loan';
      case GoldEmiType.investmentScheme:
        return 'Gold Savings Scheme';
    }
  }

  String get shortLabel {
    switch (this) {
      case GoldEmiType.borrowLoan:
        return 'Borrow (Interest)';
      case GoldEmiType.investmentScheme:
        return 'Investment (Bonus)';
    }
  }

  bool get isBorrowLoan => this == GoldEmiType.borrowLoan;
  bool get isInvestmentScheme => this == GoldEmiType.investmentScheme;
}

class GoldEmiPaymentModel {
  final String id;
  final String planId;
  final int installmentNumber;
  final num amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;
  final String? transactionId;

  const GoldEmiPaymentModel({
    required this.id,
    required this.planId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
    this.transactionId,
  });

  GoldEmiPaymentModel copyWith({
    String? id,
    String? planId,
    int? installmentNumber,
    num? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isPaid,
    String? transactionId,
  }) {
    return GoldEmiPaymentModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'installmentNumber': installmentNumber,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'paidDate': paidDate?.toIso8601String(),
        'isPaid': isPaid,
        'transactionId': transactionId,
      };

  factory GoldEmiPaymentModel.fromJson(Map<String, dynamic> json) {
    return GoldEmiPaymentModel(
      id: json['id'] as String,
      planId: json['planId'] as String,
      installmentNumber: json['installmentNumber'] as int,
      amount: json['amount'] as num,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      isPaid: json['isPaid'] as bool? ?? false,
      transactionId: json['transactionId'] as String?,
    );
  }
}

class GoldEmiPlanModel {
  final String id;
  final String planName;
  final GoldEmiType type;
  final num principalOrTargetAmount;
  final int numberOfInstallments;
  final DateTime startDate;
  final num monthlyInstallmentAmount;
  final num rateOrBonusPercent;
  final num extraBenefitOrCostAmount;
  final num finalMaturityValue;
  final String? jewelerOrBank;
  final String? notes;
  final List<GoldEmiPaymentModel> payments;
  final DateTime createdAt;

  const GoldEmiPlanModel({
    required this.id,
    required this.planName,
    required this.type,
    required this.principalOrTargetAmount,
    required this.numberOfInstallments,
    required this.startDate,
    required this.monthlyInstallmentAmount,
    required this.rateOrBonusPercent,
    required this.extraBenefitOrCostAmount,
    required this.finalMaturityValue,
    this.jewelerOrBank,
    this.notes,
    required this.payments,
    required this.createdAt,
  });

  int get paidInstallments => payments.where((p) => p.isPaid).length;
  int get remainingInstallments => numberOfInstallments - paidInstallments;
  num get paidAmount => payments.where((p) => p.isPaid).fold<num>(0, (sum, p) => sum + p.amount);
  num get remainingAmount => (finalMaturityValue - paidAmount) < 0 ? 0 : (finalMaturityValue - paidAmount);
  bool get isCompleted => remainingInstallments == 0;

  String get title => planName;
  String get jewelerOrLender => jewelerOrBank ?? (isBorrowLoan ? 'Bank' : 'Jeweler');
  int get tenureMonths => numberOfInstallments;
  num get monthlyEmi => monthlyInstallmentAmount;
  num get totalPaidAmount => paidAmount;
  int get paidInstallmentsCount => paidInstallments;
  bool get isBorrowLoan => type == GoldEmiType.borrowLoan;
  bool get isInvestmentScheme => type == GoldEmiType.investmentScheme;
  num get principalAmount => principalOrTargetAmount;
  double get interestRateAnnual => rateOrBonusPercent.toDouble();
  num get totalInterestPayable => extraBenefitOrCostAmount;
  num get schemeBonusAmount => extraBenefitOrCostAmount;

  DateTime get endDate {
    return DateTime(startDate.year, startDate.month + numberOfInstallments - 1, startDate.day);
  }

  GoldEmiPaymentModel? get nextPendingPayment {
    final pending = payments.where((p) => !p.isPaid).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first;
  }

  GoldEmiPlanModel copyWith({
    String? id,
    String? planName,
    GoldEmiType? type,
    num? principalOrTargetAmount,
    int? numberOfInstallments,
    DateTime? startDate,
    num? monthlyInstallmentAmount,
    num? rateOrBonusPercent,
    num? extraBenefitOrCostAmount,
    num? finalMaturityValue,
    String? jewelerOrBank,
    String? notes,
    List<GoldEmiPaymentModel>? payments,
    DateTime? createdAt,
  }) {
    return GoldEmiPlanModel(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      type: type ?? this.type,
      principalOrTargetAmount: principalOrTargetAmount ?? this.principalOrTargetAmount,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      startDate: startDate ?? this.startDate,
      monthlyInstallmentAmount: monthlyInstallmentAmount ?? this.monthlyInstallmentAmount,
      rateOrBonusPercent: rateOrBonusPercent ?? this.rateOrBonusPercent,
      extraBenefitOrCostAmount: extraBenefitOrCostAmount ?? this.extraBenefitOrCostAmount,
      finalMaturityValue: finalMaturityValue ?? this.finalMaturityValue,
      jewelerOrBank: jewelerOrBank ?? this.jewelerOrBank,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'planName': planName,
        'type': type.name,
        'principalOrTargetAmount': principalOrTargetAmount,
        'numberOfInstallments': numberOfInstallments,
        'startDate': startDate.toIso8601String(),
        'monthlyInstallmentAmount': monthlyInstallmentAmount,
        'rateOrBonusPercent': rateOrBonusPercent,
        'extraBenefitOrCostAmount': extraBenefitOrCostAmount,
        'finalMaturityValue': finalMaturityValue,
        'jewelerOrBank': jewelerOrBank,
        'notes': notes,
        'payments': payments.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoldEmiPlanModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'] as List<dynamic>? ?? [];
    final type = GoldEmiType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => GoldEmiType.borrowLoan,
    );

    return GoldEmiPlanModel(
      id: json['id'] as String,
      planName: json['planName'] as String,
      type: type,
      principalOrTargetAmount: json['principalOrTargetAmount'] as num,
      numberOfInstallments: json['numberOfInstallments'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      monthlyInstallmentAmount: json['monthlyInstallmentAmount'] as num,
      rateOrBonusPercent: json['rateOrBonusPercent'] as num,
      extraBenefitOrCostAmount: json['extraBenefitOrCostAmount'] as num,
      finalMaturityValue: json['finalMaturityValue'] as num,
      jewelerOrBank: json['jewelerOrBank'] as String?,
      notes: json['notes'] as String?,
      payments: rawPayments.map((p) => GoldEmiPaymentModel.fromJson(p as Map<String, dynamic>)).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['startDate'] as String),
    );
  }

  static List<GoldEmiPaymentModel> generateSchedule({
    required String planId,
    required DateTime startDate,
    required int numberOfInstallments,
    required num monthlyAmount,
  }) {
    final schedule = <GoldEmiPaymentModel>[];
    for (int i = 0; i < numberOfInstallments; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + i, startDate.day);
      schedule.add(
        GoldEmiPaymentModel(
          id: '${planId}_gold_inst_${i + 1}',
          planId: planId,
          installmentNumber: i + 1,
          amount: monthlyAmount,
          dueDate: dueDate,
          isPaid: false,
        ),
      );
    }
    return schedule;
  }
}

class GoldSipTierRow {
  final int month;
  final num monthlyInstallment;
  final double benefitPercent;
  final num benefitAmount;
  final num cumulativePaid;
  final num jewelleryValue;
  final bool isPaid;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentId;

  const GoldSipTierRow({
    required this.month,
    required this.monthlyInstallment,
    required this.benefitPercent,
    required this.benefitAmount,
    required this.cumulativePaid,
    required this.jewelleryValue,
    required this.isPaid,
    required this.dueDate,
    this.paidDate,
    this.paymentId,
  });
}

class GoldSipSchemeModel {
  final String id;
  final String schemeName;
  final String jewelerName;
  final num monthlyInstallment;
  final int totalMonths;
  final int maturityWaitDays;
  final DateTime startDate;
  final Map<int, double> monthBenefitPercents;
  final List<GoldEmiPaymentModel> payments;
  final DateTime createdAt;
  final String? notes;

  static const Map<int, double> default30MonthTierSchedule = {
    1: 0.0,
    2: 0.0,
    3: 0.0,
    4: 0.0,
    5: 0.0,
    6: 20.0,
    7: 25.0,
    8: 35.0,
    9: 45.0,
    10: 55.0,
    11: 65.0,
    12: 75.0,
    13: 85.0,
    14: 100.0,
    15: 115.0,
    16: 130.0,
    17: 145.0,
    18: 170.0,
    19: 190.0,
    20: 210.0,
    21: 230.0,
    22: 250.0,
    23: 275.0,
    24: 300.0,
    25: 325.0,
    26: 350.0,
    27: 375.0,
    28: 400.0,
    29: 425.0,
    30: 450.0,
  };

  static const Map<int, double> default11MonthTierSchedule = {
    1: 0.0,
    2: 0.0,
    3: 0.0,
    4: 0.0,
    5: 0.0,
    6: 0.0,
    7: 0.0,
    8: 0.0,
    9: 0.0,
    10: 0.0,
    11: 100.0,
  };

  const GoldSipSchemeModel({
    required this.id,
    required this.schemeName,
    required this.jewelerName,
    required this.monthlyInstallment,
    this.totalMonths = 30,
    this.maturityWaitDays = 30,
    required this.startDate,
    required this.monthBenefitPercents,
    required this.payments,
    required this.createdAt,
    this.notes,
  });

  int get paidInstallmentsCount => payments.where((p) => p.isPaid).length;
  int get remainingInstallmentsCount => totalMonths - paidInstallmentsCount;
  num get totalPaidAmount => payments.where((p) => p.isPaid).fold<num>(0, (s, p) => s + p.amount);
  num get totalContractedAmount => monthlyInstallment * totalMonths;
  bool get isCompleted => remainingInstallmentsCount <= 0;

  double benefitPercentAt(int month) => monthBenefitPercents[month] ?? 0.0;

  num benefitAmountAt(int month) {
    final pct = benefitPercentAt(month);
    if (pct <= 0) return 0;
    return (monthlyInstallment * (pct / 100.0)).round();
  }

  double get currentAccruedBenefitPercent {
    if (paidInstallmentsCount <= 0) return 0.0;
    return benefitPercentAt(paidInstallmentsCount);
  }

  num get currentAccruedBenefitAmount {
    if (paidInstallmentsCount <= 0) return 0;
    return benefitAmountAt(paidInstallmentsCount);
  }

  num get currentJewelleryValue {
    if (paidInstallmentsCount <= 0) return 0;
    final bonus = currentAccruedBenefitPercent > 0 ? currentAccruedBenefitAmount : 0;
    return totalPaidAmount + bonus;
  }

  double get finalBenefitPercent => benefitPercentAt(totalMonths);
  num get finalBenefitAmount => benefitAmountAt(totalMonths);
  num get finalJewelleryValue => totalContractedAmount + finalBenefitAmount;

  DateTime get maturityDate {
    final endMonthDate = DateTime(startDate.year, startDate.month + totalMonths, startDate.day);
    return endMonthDate.add(Duration(days: maturityWaitDays));
  }

  List<GoldSipTierRow> buildTierSchedule() {
    final rows = <GoldSipTierRow>[];
    for (int m = 1; m <= totalMonths; m++) {
      final cumPaid = monthlyInstallment * m;
      final pct = benefitPercentAt(m);
      final benefit = benefitAmountAt(m);
      final jVal = pct > 0 ? (cumPaid + benefit) : cumPaid;
      
      GoldEmiPaymentModel? payment;
      if (m - 1 < payments.length) {
        payment = payments[m - 1];
      }
      final dueDate = payment?.dueDate ?? DateTime(startDate.year, startDate.month + m - 1, startDate.day);

      rows.add(
        GoldSipTierRow(
          month: m,
          monthlyInstallment: monthlyInstallment,
          benefitPercent: pct,
          benefitAmount: benefit,
          cumulativePaid: cumPaid,
          jewelleryValue: jVal,
          isPaid: payment?.isPaid ?? false,
          dueDate: dueDate,
          paidDate: payment?.paidDate,
          paymentId: payment?.id,
        ),
      );
    }
    return rows;
  }

  GoldSipSchemeModel copyWith({
    String? id,
    String? schemeName,
    String? jewelerName,
    num? monthlyInstallment,
    int? totalMonths,
    int? maturityWaitDays,
    DateTime? startDate,
    Map<int, double>? monthBenefitPercents,
    List<GoldEmiPaymentModel>? payments,
    DateTime? createdAt,
    String? notes,
  }) {
    return GoldSipSchemeModel(
      id: id ?? this.id,
      schemeName: schemeName ?? this.schemeName,
      jewelerName: jewelerName ?? this.jewelerName,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      totalMonths: totalMonths ?? this.totalMonths,
      maturityWaitDays: maturityWaitDays ?? this.maturityWaitDays,
      startDate: startDate ?? this.startDate,
      monthBenefitPercents: monthBenefitPercents ?? this.monthBenefitPercents,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schemeName': schemeName,
        'jewelerName': jewelerName,
        'monthlyInstallment': monthlyInstallment,
        'totalMonths': totalMonths,
        'maturityWaitDays': maturityWaitDays,
        'startDate': startDate.toIso8601String(),
        'monthBenefitPercents': monthBenefitPercents.map((k, v) => MapEntry(k.toString(), v)),
        'payments': payments.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory GoldSipSchemeModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'] as List<dynamic>? ?? [];
    final rawPercents = json['monthBenefitPercents'] as Map<String, dynamic>? ?? {};
    final parsedPercents = <int, double>{};
    rawPercents.forEach((k, v) {
      final keyInt = int.tryParse(k);
      if (keyInt != null) {
        parsedPercents[keyInt] = (v as num).toDouble();
      }
    });

    return GoldSipSchemeModel(
      id: json['id'] as String,
      schemeName: json['schemeName'] as String,
      jewelerName: json['jewelerName'] as String,
      monthlyInstallment: json['monthlyInstallment'] as num,
      totalMonths: json['totalMonths'] as int? ?? 30,
      maturityWaitDays: json['maturityWaitDays'] as int? ?? 30,
      startDate: DateTime.parse(json['startDate'] as String),
      monthBenefitPercents: parsedPercents.isNotEmpty ? parsedPercents : default30MonthTierSchedule,
      payments: rawPayments.map((p) => GoldEmiPaymentModel.fromJson(p as Map<String, dynamic>)).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['startDate'] as String),
      notes: json['notes'] as String?,
    );
  }

  static List<GoldEmiPaymentModel> generateSchedule({
    required String schemeId,
    required DateTime startDate,
    required int numberOfInstallments,
    required num monthlyAmount,
  }) {
    final schedule = <GoldEmiPaymentModel>[];
    for (int i = 0; i < numberOfInstallments; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + i, startDate.day);
      schedule.add(
        GoldEmiPaymentModel(
          id: '${schemeId}_goldsip_${i + 1}',
          planId: schemeId,
          installmentNumber: i + 1,
          amount: monthlyAmount,
          dueDate: dueDate,
          isPaid: false,
        ),
      );
    }
    return schedule;
  }
}

