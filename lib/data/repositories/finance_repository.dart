import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/data/local/local_storage_service.dart';
import 'package:finance_tracker/data/models/app_settings_model.dart';
import 'package:finance_tracker/data/models/budget_model.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/models/emi_model.dart';
import 'package:finance_tracker/data/models/gold_model.dart';
import 'package:finance_tracker/data/models/recurring_model.dart';
import 'package:finance_tracker/data/models/saving_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';

class FinanceRepository extends GetxController {
  final LocalStorageService _storage = Get.find<LocalStorageService>();
  final _uuid = const Uuid();

  // Observable reactive collections
  final transactions = <TransactionModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final emiPlans = <EMIPlanModel>[].obs;
  final savingGoals = <SavingGoalModel>[].obs;
  final savingsRecords = <SavingRecordModel>[].obs;
  final goldInvestments = <GoldInvestmentModel>[].obs;
  final budgets = <BudgetModel>[].obs;
  final recurringRules = <RecurringRuleModel>[].obs;
  final settings = const AppSettingsModel().obs;

  // Selected filter state for dashboard & reports
  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  void loadAllData() {
    settings.value = _storage.loadSettings();
    categories.value = _storage.loadCategories();
    transactions.value = _storage.loadTransactions();
    emiPlans.value = _storage.loadEmiPlans();
    savingGoals.value = _storage.loadSavingGoals();
    savingsRecords.value = _storage.loadSavingsRecords();
    goldInvestments.value = _storage.loadGoldInvestments();
    budgets.value = _storage.loadBudgets();
    recurringRules.value = _storage.loadRecurringRules();

    if (!settings.value.hasInitializedDefaults && transactions.isEmpty) {
      _seedDefaultSampleData();
    }

    // Process recurring transactions
    processRecurringRules();
  }

  // --- Seed realistic starter data for Artha ---
  void _seedDefaultSampleData() {
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);

    // 1. Recurring Monthly Salary
    final salaryRuleId = _uuid.v4();
    final salaryRule = RecurringRuleModel(
      id: salaryRuleId,
      title: 'Monthly Salary',
      amount: 50000.0,
      type: TransactionType.income,
      frequency: RecurringFrequency.monthly,
      startDate: firstDayCurrentMonth,
      categoryId: 'salary',
      description: 'Primary Employment Salary',
      lastGeneratedDate: firstDayCurrentMonth,
      isActive: true,
    );
    recurringRules.add(salaryRule);
    _storage.saveRecurringRules(recurringRules);

    // 2. Initial Salary Transaction
    final salaryTx = TransactionModel(
      id: _uuid.v4(),
      title: 'Monthly Salary',
      amount: 50000.0,
      date: firstDayCurrentMonth,
      type: TransactionType.income,
      categoryId: 'salary',
      notes: 'September Salary Received',
      sourceId: salaryRuleId,
      createdAt: firstDayCurrentMonth,
    );

    // 3. Other Income
    final borrowedReturnTx = TransactionModel(
      id: _uuid.v4(),
      title: 'Friend Returned Borrowed Money',
      amount: 2000.0,
      date: firstDayCurrentMonth.add(const Duration(days: 1)),
      type: TransactionType.income,
      categoryId: 'borrow_returned',
      notes: 'Rohan repaid cash loan',
      createdAt: firstDayCurrentMonth.add(const Duration(days: 1)),
    );

    // 4. Everyday Expenses
    final snackTx = TransactionModel(
      id: _uuid.v4(),
      title: 'Tea & Snacks',
      amount: 30.0,
      date: now,
      type: TransactionType.expense,
      categoryId: 'food',
      notes: 'Evening snacks',
      createdAt: now,
    );

    final groceryTx = TransactionModel(
      id: _uuid.v4(),
      title: 'Monthly Groceries',
      amount: 3470.0,
      date: firstDayCurrentMonth.add(const Duration(days: 2)),
      type: TransactionType.expense,
      categoryId: 'food',
      notes: 'Supermarket supplies',
      createdAt: firstDayCurrentMonth.add(const Duration(days: 2)),
    );

    // 5. EMI Plan (12-month phone EMI of ₹36,000 -> ₹3,000/month)
    final emiPlanId = _uuid.v4();
    final emiSchedule = EMIPlanModel.generatePaymentSchedule(
      emiPlanId: emiPlanId,
      startDate: firstDayCurrentMonth,
      numberOfInstallments: 12,
      monthlyAmount: 3000.0,
    );

    // Mark 1st payment as paid
    final emiPaymentTxId = _uuid.v4();
    final updatedSchedule = emiSchedule.map((p) {
      if (p.installmentNumber == 1) {
        return p.copyWith(
          status: EMIPaymentStatus.paid,
          paidDate: firstDayCurrentMonth,
          transactionId: emiPaymentTxId,
        );
      }
      return p;
    }).toList();

    final emiPlan = EMIPlanModel(
      id: emiPlanId,
      purchaseName: 'Smartphone (12-Mo EMI)',
      totalAmount: 36000.0,
      numberOfInstallments: 12,
      startDate: firstDayCurrentMonth,
      monthlyEmiAmount: 3000.0,
      category: 'emi_expense',
      notes: '0% Interest online purchase',
      payments: updatedSchedule,
      createdAt: firstDayCurrentMonth,
    );
    emiPlans.add(emiPlan);
    _storage.saveEmiPlans(emiPlans);

    final emiTx = TransactionModel(
      id: emiPaymentTxId,
      title: 'EMI 1/12: Smartphone',
      amount: 3000.0,
      date: firstDayCurrentMonth,
      type: TransactionType.emi,
      categoryId: 'emi_expense',
      sourceId: emiPlanId,
      notes: 'Installment 1 of 12 paid',
      createdAt: firstDayCurrentMonth,
    );

    // 6. Savings Goal & Record
    final goalId = _uuid.v4();
    final savingGoal = SavingGoalModel(
      id: goalId,
      name: 'Emergency Fund',
      targetAmount: 100000.0,
      currentAmount: 35000.0,
      targetDate: DateTime(now.year + 1, now.month, 1),
      category: 'Emergency',
      colorValue: 0xFF3B82F6,
    );
    savingGoals.add(savingGoal);
    _storage.saveSavingGoals(savingGoals);

    final savingTxId = _uuid.v4();
    final savingRecord = SavingRecordModel(
      id: _uuid.v4(),
      goalId: goalId,
      amount: 5000.0,
      date: firstDayCurrentMonth.add(const Duration(days: 3)),
      category: 'Emergency Fund',
      description: 'Monthly emergency fund contribution',
      transactionId: savingTxId,
    );
    savingsRecords.add(savingRecord);
    _storage.saveSavingsRecords(savingsRecords);

    final savingTx = TransactionModel(
      id: savingTxId,
      title: 'Emergency Fund Contribution',
      amount: 5000.0,
      date: firstDayCurrentMonth.add(const Duration(days: 3)),
      type: TransactionType.saving,
      categoryId: 'savings_allocation',
      sourceId: goalId,
      notes: 'Added to Emergency Fund Goal',
      createdAt: firstDayCurrentMonth.add(const Duration(days: 3)),
    );

    // 7. Gold Investment (₹5,000 for 1.5 grams)
    final goldTxId = _uuid.v4();
    final goldInv = GoldInvestmentModel(
      id: _uuid.v4(),
      amountInr: 5000.0,
      quantityInGrams: 1.5,
      inputUnit: GoldUnit.gram,
      inputQuantity: 1.5,
      purchaseDate: firstDayCurrentMonth.add(const Duration(days: 4)),
      ratePerGram: 5000.0 / 1.5,
      notes: 'Digital 24K Gold purchase',
      transactionId: goldTxId,
    );
    goldInvestments.add(goldInv);
    _storage.saveGoldInvestments(goldInvestments);

    final goldTx = TransactionModel(
      id: goldTxId,
      title: 'Gold Purchase (1.5g)',
      amount: 5000.0,
      date: firstDayCurrentMonth.add(const Duration(days: 4)),
      type: TransactionType.gold,
      categoryId: 'gold_purchase',
      sourceId: goldInv.id,
      notes: 'Digital gold purchase @ ₹3,333.33/g',
      createdAt: firstDayCurrentMonth.add(const Duration(days: 4)),
    );

    // 8. Sample Budgets
    budgets.addAll([
      BudgetModel(
        id: _uuid.v4(),
        categoryId: 'food',
        monthlyLimit: 6000.0,
        month: now.month,
        year: now.year,
      ),
      BudgetModel(
        id: _uuid.v4(),
        categoryId: 'transport',
        monthlyLimit: 3000.0,
        month: now.month,
        year: now.year,
      ),
      BudgetModel(
        id: _uuid.v4(),
        categoryId: 'shopping',
        monthlyLimit: 5000.0,
        month: now.month,
        year: now.year,
      ),
      BudgetModel(
        id: _uuid.v4(),
        categoryId: 'entertainment',
        monthlyLimit: 2000.0,
        month: now.month,
        year: now.year,
      ),
    ]);
    _storage.saveBudgets(budgets);

    // Add all transactions to list & save
    transactions.addAll([
      salaryTx,
      borrowedReturnTx,
      snackTx,
      groceryTx,
      emiTx,
      savingTx,
      goldTx,
    ]);
    _storage.saveTransactions(transactions);

    // Mark settings as initialized
    settings.value = settings.value.copyWith(hasInitializedDefaults: true);
    _storage.saveSettings(settings.value);
  }

  // --- Transactions Management ---
  Future<void> addTransaction(TransactionModel tx) async {
    transactions.insert(0, tx);
    await _storage.saveTransactions(transactions);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final index = transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      transactions[index] = tx;
      await _storage.saveTransactions(transactions);
    }
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
    await _storage.saveTransactions(transactions);
  }

  // --- Category Management ---
  Future<void> addCategory(CategoryModel cat) async {
    categories.add(cat);
    await _storage.saveCategories(categories);
  }

  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id && c.isCustom);
    await _storage.saveCategories(categories);
  }

  CategoryModel getCategoryById(String id) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => CategoryModel(
        id: id,
        name: id,
        iconCodePoint: Icons.help_outline.codePoint,
        colorValue: 0xFF64748B,
        type: CategoryType.expense,
      ),
    );
  }

  // --- EMI Management ---
  Future<void> addEmiPlan(EMIPlanModel plan) async {
    emiPlans.add(plan);
    await _storage.saveEmiPlans(emiPlans);
  }

  Future<void> updateEmiPlan(EMIPlanModel plan) async {
    final index = emiPlans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      emiPlans[index] = plan;
      await _storage.saveEmiPlans(emiPlans);
    }
  }

  Future<void> deleteEmiPlan(String planId) async {
    emiPlans.removeWhere((p) => p.id == planId);
    await _storage.saveEmiPlans(emiPlans);
    // Remove linked transactions
    transactions.removeWhere((t) => t.sourceId == planId && t.type == TransactionType.emi);
    await _storage.saveTransactions(transactions);
  }

  Future<void> toggleEmiPaymentStatus({
    required String emiPlanId,
    required String paymentId,
  }) async {
    final planIndex = emiPlans.indexWhere((p) => p.id == emiPlanId);
    if (planIndex == -1) return;

    final plan = emiPlans[planIndex];
    final paymentIndex = plan.payments.indexWhere((p) => p.id == paymentId);
    if (paymentIndex == -1) return;

    final payment = plan.payments[paymentIndex];
    final newPayments = List<EMIPaymentModel>.from(plan.payments);

    if (payment.isPaid) {
      // Mark as Pending
      if (payment.transactionId != null) {
        await deleteTransaction(payment.transactionId!);
      }
      newPayments[paymentIndex] = payment.copyWith(
        status: EMIPaymentStatus.pending,
        paidDate: null,
        transactionId: null,
      );
    } else {
      // Mark as Paid
      final txId = _uuid.v4();
      final now = DateTime.now();
      final tx = TransactionModel(
        id: txId,
        title: 'EMI ${payment.installmentNumber}/${plan.numberOfInstallments}: ${plan.purchaseName}',
        amount: payment.amount,
        date: payment.dueDate.isBefore(now) ? payment.dueDate : now,
        type: TransactionType.emi,
        categoryId: plan.category,
        sourceId: plan.id,
        notes: 'Installment ${payment.installmentNumber} of ${plan.numberOfInstallments} for ${plan.purchaseName}',
        createdAt: now,
      );
      await addTransaction(tx);

      newPayments[paymentIndex] = payment.copyWith(
        status: EMIPaymentStatus.paid,
        paidDate: now,
        transactionId: txId,
      );
    }

    emiPlans[planIndex] = plan.copyWith(payments: newPayments);
    await _storage.saveEmiPlans(emiPlans);
  }

  // --- Savings Management ---
  Future<void> addSavingGoal(SavingGoalModel goal) async {
    savingGoals.add(goal);
    await _storage.saveSavingGoals(savingGoals);
  }

  Future<void> updateSavingGoal(SavingGoalModel goal) async {
    final index = savingGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      savingGoals[index] = goal;
      await _storage.saveSavingGoals(savingGoals);
    }
  }

  Future<void> deleteSavingGoal(String id) async {
    savingGoals.removeWhere((g) => g.id == id);
    await _storage.saveSavingGoals(savingGoals);
  }

  Future<void> addSavingDeposit({
    required String? goalId,
    required double amount,
    required DateTime date,
    required String category,
    String? description,
  }) async {
    final txId = _uuid.v4();
    final recordId = _uuid.v4();

    final record = SavingRecordModel(
      id: recordId,
      goalId: goalId,
      amount: amount,
      date: date,
      category: category,
      description: description,
      transactionId: txId,
    );
    savingsRecords.add(record);
    await _storage.saveSavingsRecords(savingsRecords);

    // Update goal currentAmount if linked
    if (goalId != null) {
      final goalIndex = savingGoals.indexWhere((g) => g.id == goalId);
      if (goalIndex != -1) {
        final goal = savingGoals[goalIndex];
        savingGoals[goalIndex] = goal.copyWith(
          currentAmount: goal.currentAmount + amount,
        );
        await _storage.saveSavingGoals(savingGoals);
      }
    }

    // Add cash deduction transaction
    final tx = TransactionModel(
      id: txId,
      title: 'Savings: $category',
      amount: amount,
      date: date,
      type: TransactionType.saving,
      categoryId: 'savings_allocation',
      sourceId: goalId,
      notes: description,
      createdAt: DateTime.now(),
    );
    await addTransaction(tx);
  }

  // --- Gold Investment Management ---
  Future<void> addGoldInvestment({
    required double amountInr,
    required double quantity,
    required GoldUnit unit,
    required DateTime date,
    String? notes,
  }) async {
    final normalizedGrams = GoldInvestmentModel.normalizeToGrams(quantity, unit);
    final ratePerGram = normalizedGrams > 0 ? amountInr / normalizedGrams : 0.0;
    final goldId = _uuid.v4();
    final txId = _uuid.v4();

    final goldInv = GoldInvestmentModel(
      id: goldId,
      amountInr: amountInr,
      quantityInGrams: normalizedGrams,
      inputUnit: unit,
      inputQuantity: quantity,
      purchaseDate: date,
      ratePerGram: ratePerGram,
      notes: notes,
      transactionId: txId,
    );
    goldInvestments.add(goldInv);
    await _storage.saveGoldInvestments(goldInvestments);

    // Add transaction to log deduction from spendable cash
    final tx = TransactionModel(
      id: txId,
      title: 'Gold Purchase (${normalizedGrams.toStringAsFixed(2)}g)',
      amount: amountInr,
      date: date,
      type: TransactionType.gold,
      categoryId: 'gold_purchase',
      sourceId: goldId,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await addTransaction(tx);
  }

  Future<void> deleteGoldInvestment(String id) async {
    final inv = goldInvestments.firstWhereOrNull((g) => g.id == id);
    if (inv != null && inv.transactionId != null) {
      await deleteTransaction(inv.transactionId!);
    }
    goldInvestments.removeWhere((g) => g.id == id);
    await _storage.saveGoldInvestments(goldInvestments);
  }

  // --- Budget Management ---
  Future<void> setBudget({
    required String categoryId,
    required double monthlyLimit,
    required int month,
    required int year,
  }) async {
    final existingIndex = budgets.indexWhere(
      (b) => b.categoryId == categoryId && b.month == month && b.year == year,
    );
    if (existingIndex != -1) {
      budgets[existingIndex] = budgets[existingIndex].copyWith(monthlyLimit: monthlyLimit);
    } else {
      budgets.add(BudgetModel(
        id: _uuid.v4(),
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        month: month,
        year: year,
      ));
    }
    await _storage.saveBudgets(budgets);
  }

  Future<void> deleteBudget(String id) async {
    budgets.removeWhere((b) => b.id == id);
    await _storage.saveBudgets(budgets);
  }

  // --- Recurring Rules Management ---
  Future<void> addRecurringRule(RecurringRuleModel rule) async {
    recurringRules.add(rule);
    await _storage.saveRecurringRules(recurringRules);
    processRecurringRules();
  }

  Future<void> updateRecurringRule(RecurringRuleModel rule) async {
    final index = recurringRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      recurringRules[index] = rule;
      await _storage.saveRecurringRules(recurringRules);
    }
  }

  Future<void> deleteRecurringRule(String id) async {
    recurringRules.removeWhere((r) => r.id == id);
    await _storage.saveRecurringRules(recurringRules);
  }

  /// Automatically generate due transactions for recurring rules (idempotent, never duplicates)
  void processRecurringRules() {
    final now = DateTime.now();
    bool hasUpdates = false;

    for (int i = 0; i < recurringRules.length; i++) {
      final rule = recurringRules[i];
      if (!rule.isActive) continue;

      if (rule.frequency == RecurringFrequency.monthly) {
        final lastGen = rule.lastGeneratedDate ?? rule.startDate;
        final isDueThisMonth =
            (now.year > lastGen.year) || (now.year == lastGen.year && now.month > lastGen.month);

        if (isDueThisMonth && now.isAfter(rule.startDate)) {
          // Generate transaction for current month
          final txDate = DateTime(now.year, now.month, rule.startDate.day.clamp(1, 28));
          final txId = '${rule.id}_${now.year}_${now.month}';

          // Ensure no duplicate exists
          final alreadyExists = transactions.any((t) => t.id == txId);
          if (!alreadyExists) {
            final tx = TransactionModel(
              id: txId,
              title: rule.title,
              amount: rule.amount,
              date: txDate,
              type: rule.type,
              categoryId: rule.categoryId,
              sourceId: rule.id,
              notes: 'Auto-recurring (${rule.title})',
              createdAt: now,
            );
            transactions.insert(0, tx);
          }

          recurringRules[i] = rule.copyWith(lastGeneratedDate: now);
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates) {
      _storage.saveTransactions(transactions);
      _storage.saveRecurringRules(recurringRules);
    }
  }

  // --- Settings & Reset ---
  Future<void> updateSettings(AppSettingsModel newSettings) async {
    settings.value = newSettings;
    await _storage.saveSettings(newSettings);
    CurrencyFormatter.defaultSymbol = newSettings.currencySymbol;
    CurrencyFormatter.defaultCode = newSettings.currencyCode;
  }

  Future<void> resetAllData() async {
    await _storage.clearAllData();
    transactions.clear();
    categories.value = CategoryModel.defaultCategories;
    emiPlans.clear();
    savingGoals.clear();
    savingsRecords.clear();
    goldInvestments.clear();
    budgets.clear();
    recurringRules.clear();
    settings.value = const AppSettingsModel(hasInitializedDefaults: true);
    await _storage.saveSettings(settings.value);
  }

  // --- Export & Restore ---
  String exportJsonBackup() {
    return _storage.exportFullBackupJson();
  }

  String exportTransactionsCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,Title,Type,Category,Amount,Notes');
    for (final tx in transactions) {
      final cat = getCategoryById(tx.categoryId).name;
      final notes = (tx.notes ?? '').replaceAll(',', ';');
      final title = tx.title.replaceAll(',', ';');
      buffer.writeln(
        '${tx.id},${tx.date.toIso8601String().split('T').first},$title,${tx.type.name},$cat,${tx.amount},$notes',
      );
    }
    return buffer.toString();
  }

  Future<bool> restoreJsonBackup(String jsonStr) async {
    final success = await _storage.restoreFullBackupJson(jsonStr);
    if (success) {
      loadAllData();
    }
    return success;
  }

  // --- Financial Calculations & Aggregations ---

  /// Total Income for a given month/year (or all-time if null)
  double getTotalIncome({int? month, int? year}) {
    return transactions
        .where((t) =>
            t.type == TransactionType.income &&
            (month == null || t.date.month == month) &&
            (year == null || t.date.year == year))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total Regular Expenses for a given month/year (excludes EMI, Saving, Gold)
  double getTotalExpenses({int? month, int? year}) {
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            (month == null || t.date.month == month) &&
            (year == null || t.date.year == year))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total EMI paid in a given month/year
  double getTotalEmiPaid({int? month, int? year}) {
    return transactions
        .where((t) =>
            t.type == TransactionType.emi &&
            (month == null || t.date.month == month) &&
            (year == null || t.date.year == year))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total Savings moved to goals/deposits in a given month/year
  double getTotalSavingsAllocated({int? month, int? year}) {
    return transactions
        .where((t) =>
            t.type == TransactionType.saving &&
            (month == null || t.date.month == month) &&
            (year == null || t.date.year == year))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total Gold investments in a given month/year
  double getTotalGoldInvested({int? month, int? year}) {
    return transactions
        .where((t) =>
            t.type == TransactionType.gold &&
            (month == null || t.date.month == month) &&
            (year == null || t.date.year == year))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total Remaining / Available Cash Balance
  /// Formula: Total Income - (Expenses + EMI + Savings + Gold)
  double getAvailableBalance({int? month, int? year}) {
    final income = getTotalIncome(month: month, year: year);
    final expense = getTotalExpenses(month: month, year: year);
    final emi = getTotalEmiPaid(month: month, year: year);
    final saving = getTotalSavingsAllocated(month: month, year: year);
    final gold = getTotalGoldInvested(month: month, year: year);

    return income - (expense + emi + saving + gold);
  }

  /// Overall cumulative cash balance since inception
  double get allTimeAvailableBalance => getAvailableBalance();

  /// Total gold accumulated in grams
  double get totalGoldGrams =>
      goldInvestments.fold(0.0, (sum, g) => sum + g.quantityInGrams);

  /// Total INR spent on gold
  double get totalGoldInvestedInr =>
      goldInvestments.fold(0.0, (sum, g) => sum + g.amountInr);

  /// Average purchase rate per gram
  double get averageGoldRatePerGram =>
      totalGoldGrams > 0 ? totalGoldInvestedInr / totalGoldGrams : 0.0;

  /// Total accumulated savings across all goals
  double get totalSavingsAccumulated =>
      savingGoals.fold(0.0, (sum, g) => sum + g.currentAmount);

  /// Estimated Net Worth = Available Cash + Total Savings in Goals + Total Gold Value
  double get totalNetWorth =>
      allTimeAvailableBalance + totalSavingsAccumulated + totalGoldInvestedInr;

  /// Get spending for a specific category in month/year
  double getCategorySpending(String categoryId, int month, int year) {
    return transactions
        .where((t) =>
            t.categoryId == categoryId &&
            t.type == TransactionType.expense &&
            t.date.month == month &&
            t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get all upcoming pending EMI installments across all plans
  List<EMIPaymentModel> get upcomingEmiPayments {
    final list = <EMIPaymentModel>[];
    for (final plan in emiPlans) {
      for (final payment in plan.payments) {
        if (!payment.isPaid) {
          list.add(payment);
        }
      }
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }
}
