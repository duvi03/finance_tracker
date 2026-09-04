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

class GoldInvestmentModel {
  final String id;
  final double amountInr;
  final double quantityInGrams;
  final GoldUnit inputUnit;
  final double inputQuantity;
  final DateTime purchaseDate;
  final double ratePerGram;
  final String? notes;
  final String? transactionId;

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
  });

  GoldInvestmentModel copyWith({
    String? id,
    double? amountInr,
    double? quantityInGrams,
    GoldUnit? inputUnit,
    double? inputQuantity,
    DateTime? purchaseDate,
    double? ratePerGram,
    String? notes,
    String? transactionId,
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
      };

  factory GoldInvestmentModel.fromJson(Map<String, dynamic> json) {
    final unit = GoldUnit.values.firstWhere(
      (e) => e.name == json['inputUnit'],
      orElse: () => GoldUnit.gram,
    );
    return GoldInvestmentModel(
      id: json['id'] as String,
      amountInr: (json['amountInr'] as num).toDouble(),
      quantityInGrams: (json['quantityInGrams'] as num).toDouble(),
      inputUnit: unit,
      inputQuantity: (json['inputQuantity'] as num?)?.toDouble() ??
          (json['quantityInGrams'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      ratePerGram: (json['ratePerGram'] as num).toDouble(),
      notes: json['notes'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }

  static double normalizeToGrams(double quantity, GoldUnit unit) {
    if (unit == GoldUnit.milligram) {
      return quantity / 1000.0;
    }
    return quantity;
  }
}
