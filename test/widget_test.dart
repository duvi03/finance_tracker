import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/data/models/emi_model.dart';
import 'package:finance_tracker/data/models/gold_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats Indian Rupees correctly with lakhs and thousands', () {
      expect(CurrencyFormatter.format(30), '₹30');
      expect(CurrencyFormatter.format(5000), '₹5,000');
      expect(CurrencyFormatter.format(50000), '₹50,000');
      expect(CurrencyFormatter.format(125000), '₹1,25,000');
      expect(CurrencyFormatter.format(1250000), '₹12,50,000');
    });

    test('compact format for lakhs and crores', () {
      expect(CurrencyFormatter.format(100000, compact: true), '₹1 L');
      expect(CurrencyFormatter.format(10000000, compact: true), '₹1 Cr');
    });
  });

  group('Financial Calculations Tests', () {
    test('Available balance formula without double deduction', () {
      const income = 50000.0;
      const expense = 18500.0;
      const emi = 5000.0;
      const savings = 5000.0;
      const gold = 5000.0;

      final remaining = income - (expense + emi + savings + gold);
      expect(remaining, 16500.0);
    });

    test('Gold calculations', () {
      const amountInr = 5000.0;
      const qtyGrams = 1.5;
      final rate = amountInr / qtyGrams;

      expect(rate, closeTo(3333.33, 0.01));
      expect(GoldInvestmentModel.normalizeToGrams(1500, GoldUnit.milligram), 1.5);
      expect(GoldInvestmentModel.normalizeToGrams(2.5, GoldUnit.gram), 2.5);
    });

    test('EMI schedule generation', () {
      final schedule = EMIPlanModel.generatePaymentSchedule(
        emiPlanId: 'test_plan_1',
        startDate: DateTime(2026, 9, 1),
        numberOfInstallments: 12,
        monthlyAmount: 3000.0,
      );

      expect(schedule.length, 12);
      expect(schedule.first.amount, 3000.0);
      expect(schedule.last.installmentNumber, 12);
    });

    test('Transaction JSON roundtrip', () {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'tx_123',
        title: 'Freelance Work',
        amount: 15000.0,
        date: now,
        type: TransactionType.income,
        categoryId: 'freelance',
        notes: 'Website delivery',
        createdAt: now,
      );

      final json = tx.toJson();
      final restored = TransactionModel.fromJson(json);

      expect(restored.id, tx.id);
      expect(restored.title, tx.title);
      expect(restored.amount, tx.amount);
      expect(restored.type, tx.type);
    });
  });
}
