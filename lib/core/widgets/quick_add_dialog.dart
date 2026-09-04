import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/models/emi_model.dart';
import 'package:finance_tracker/data/models/gold_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class QuickAddModal extends StatefulWidget {
  final TransactionType initialType;

  const QuickAddModal({super.key, this.initialType = TransactionType.expense});

  static Future<void> show(BuildContext context, {TransactionType initialType = TransactionType.expense}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: QuickAddModal(initialType: initialType),
      ),
    );
  }

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> with SingleTickerProviderStateMixin {
  final FinanceRepository repo = Get.find<FinanceRepository>();
  final _uuid = const Uuid();

  late TabController _tabController;
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  // EMI specific
  final _emiMonthsController = TextEditingController(text: '12');

  // Gold specific
  final _goldQuantityController = TextEditingController();
  GoldUnit _goldUnit = GoldUnit.gram;

  // Savings specific
  String? _selectedSavingGoalId;

  late TransactionType _currentType;
  late String _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    final initialIndex = _getTabIndexForType(_currentType);
    _tabController = TabController(length: 5, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentType = _getTypeForTabIndex(_tabController.index);
        _updateDefaultCategory();
      });
    });

    _updateDefaultCategory();
  }

  int _getTabIndexForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return 0;
      case TransactionType.income:
        return 1;
      case TransactionType.emi:
        return 2;
      case TransactionType.saving:
        return 3;
      case TransactionType.gold:
        return 4;
    }
  }

  TransactionType _getTypeForTabIndex(int index) {
    switch (index) {
      case 0:
        return TransactionType.expense;
      case 1:
        return TransactionType.income;
      case 2:
        return TransactionType.emi;
      case 3:
        return TransactionType.saving;
      case 4:
        return TransactionType.gold;
      default:
        return TransactionType.expense;
    }
  }

  void _updateDefaultCategory() {
    if (_currentType == TransactionType.income) {
      _selectedCategoryId = 'salary';
    } else if (_currentType == TransactionType.expense) {
      _selectedCategoryId = 'food';
    } else if (_currentType == TransactionType.emi) {
      _selectedCategoryId = 'emi_expense';
    } else if (_currentType == TransactionType.saving) {
      _selectedCategoryId = 'savings_allocation';
    } else {
      _selectedCategoryId = 'gold_purchase';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _emiMonthsController.dispose();
    _goldQuantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid positive amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _currentType.displayName;
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    if (_currentType == TransactionType.emi) {
      final months = int.tryParse(_emiMonthsController.text.trim()) ?? 12;
      if (months <= 0) return;

      final monthlyAmount = amount / months;
      final planId = _uuid.v4();
      final schedule = EMIPlanModel.generatePaymentSchedule(
        emiPlanId: planId,
        startDate: _selectedDate,
        numberOfInstallments: months,
        monthlyAmount: monthlyAmount,
      );

      final plan = EMIPlanModel(
        id: planId,
        purchaseName: title,
        totalAmount: amount,
        numberOfInstallments: months,
        startDate: _selectedDate,
        monthlyEmiAmount: monthlyAmount,
        category: _selectedCategoryId,
        notes: notes,
        payments: schedule,
        createdAt: DateTime.now(),
      );
      await repo.addEmiPlan(plan);
    } else if (_currentType == TransactionType.gold) {
      final qty = double.tryParse(_goldQuantityController.text.trim());
      if (qty == null || qty <= 0) {
        Get.snackbar(
          'Invalid Quantity',
          'Please enter gold quantity (e.g. 1.5 grams)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
        );
        return;
      }
      await repo.addGoldInvestment(
        amountInr: amount,
        quantity: qty,
        unit: _goldUnit,
        date: _selectedDate,
        notes: notes,
      );
    } else if (_currentType == TransactionType.saving) {
      await repo.addSavingDeposit(
        goalId: _selectedSavingGoalId,
        amount: amount,
        date: _selectedDate,
        category: title,
        description: notes,
      );
    } else {
      // Regular Income or Expense
      final tx = TransactionModel(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        date: _selectedDate,
        type: _currentType,
        categoryId: _selectedCategoryId,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await repo.addTransaction(tx);
    }

    Navigator.of(context).pop();
    Get.snackbar(
      'Recorded Successfully',
      '${_currentType.displayName} of ${repo.settings.value.currencySymbol}$amount recorded',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    final categoriesForType = repo.categories
        .where((c) =>
            c.type == CategoryType.both ||
            (_currentType == TransactionType.income && c.type == CategoryType.income) ||
            (_currentType != TransactionType.income && c.type == CategoryType.expense))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar for types
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Expense'),
                Tab(text: 'Income'),
                Tab(text: 'New EMI'),
                Tab(text: 'Savings'),
                Tab(text: 'Gold'),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${repo.settings.value.currencySymbol} ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                hintText: '0.00',
                labelText: _currentType == TransactionType.emi ? 'Total Purchase Cost' : 'Amount',
              ),
            ),
            const SizedBox(height: 14),

            // Title / Description
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _currentType == TransactionType.emi
                    ? 'Purchase Name (e.g. Phone, Laptop)'
                    : 'Title / Description (e.g. Snacks, Salary)',
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 14),

            // Specific fields based on type
            if (_currentType == TransactionType.emi) ...[
              TextField(
                controller: _emiMonthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Months / Installments',
                  prefixIcon: Icon(Icons.calendar_month),
                  helperText: 'e.g. 3, 6, 12, 24 months',
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_currentType == TransactionType.gold) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _goldQuantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Gold Quantity',
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<GoldUnit>(
                      value: _goldUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: GoldUnit.gram, child: Text('Grams (g)')),
                        DropdownMenuItem(value: GoldUnit.milligram, child: Text('Milligrams (mg)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _goldUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            if (_currentType == TransactionType.saving && repo.savingGoals.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _selectedSavingGoalId,
                decoration: const InputDecoration(
                  labelText: 'Link to Goal (Optional)',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('General Savings (No Goal)')),
                  ...repo.savingGoals.map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Text('${g.name} (${(g.progressPercentage * 100).toInt()}%)'),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedSavingGoalId = val),
              ),
              const SizedBox(height: 14),
            ],

            // Category Selector
            if (categoriesForType.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: categoriesForType.any((c) => c.id == _selectedCategoryId)
                    ? _selectedCategoryId
                    : categoriesForType.first.id,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categoriesForType.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategoryId = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // Date picker row
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Date: ${DateFormatter.formatShort(_selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Additional Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes / Remarks (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              child: Text(
                'Record ${_currentType.displayName}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
