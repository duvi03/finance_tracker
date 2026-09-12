import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class EditTransactionModal extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionModal({super.key, required this.transaction});

  static Future<void> show(BuildContext context, TransactionModel transaction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditTransactionModal(transaction: transaction),
      ),
    );
  }

  @override
  State<EditTransactionModal> createState() => _EditTransactionModalState();
}

class _EditTransactionModalState extends State<EditTransactionModal> {
  final FinanceRepository repo = Get.find<FinanceRepository>();

  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  late TransactionType _currentType;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  String? _selectedSavingGoalId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _currentType = tx.type;
    _amountController = TextEditingController(text: tx.amount.toString());
    _titleController = TextEditingController(text: tx.title);
    _notesController = TextEditingController(text: tx.notes ?? '');
    _selectedDate = tx.date;
    _selectedCategoryId = tx.categoryId;

    if (tx.type == TransactionType.saving) {
      _selectedSavingGoalId = tx.sourceId;
    }

    _validateCategoryForCurrentType();
  }

  void _validateCategoryForCurrentType() {
    final validCategories = _getCategoriesForType(_currentType);
    if (!validCategories.any((c) => c.id == _selectedCategoryId)) {
      if (validCategories.isNotEmpty) {
        _selectedCategoryId = validCategories.first.id;
      } else {
        _selectedCategoryId = _getDefaultCategoryForType(_currentType);
      }
    }
  }

  String _getDefaultCategoryForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'salary';
      case TransactionType.expense:
        return 'food';
      case TransactionType.saving:
        return 'savings_allocation';
      case TransactionType.emi:
        return 'emi_expense';
      case TransactionType.gold:
        return 'gold_purchase';
    }
  }

  List<CategoryModel> _getCategoriesForType(TransactionType type) {
    if (type == TransactionType.income) {
      return repo.categories
          .where((c) => c.type == CategoryType.income || c.type == CategoryType.both)
          .toList();
    } else if (type == TransactionType.saving) {
      return repo.categories
          .where((c) =>
              c.type == CategoryType.expense ||
              c.type == CategoryType.both ||
              c.id == 'savings_allocation')
          .toList();
    } else if (type == TransactionType.expense) {
      return repo.categories
          .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
          .toList();
    } else {
      return repo.categories.toList();
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.saving:
        return AppColors.savings;
      case TransactionType.gold:
        return AppColors.gold;
      case TransactionType.emi:
        return AppColors.emi;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid positive number for the amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar(
        'Title Required',
        'Please enter a title for the transaction',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }

    final notes = _notesController.text.trim();

    final updatedTx = widget.transaction.copyWith(
      title: title,
      amount: amount,
      date: _selectedDate,
      type: _currentType,
      categoryId: _selectedCategoryId,
      notes: notes.isNotEmpty ? notes : null,
      sourceId: _currentType == TransactionType.saving
          ? _selectedSavingGoalId
          : widget.transaction.sourceId,
    );

    await repo.updateTransaction(updatedTx);

    if (!mounted) return;
    Navigator.of(context).pop();

    Get.snackbar(
      'Transaction Updated',
      '${_currentType.displayName} of ${repo.settings.value.currencySymbol}$amount updated successfully',
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
    final activeColor = _getTypeColor(_currentType);
    final categories = _getCategoriesForType(_currentType);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_note, color: activeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Transaction',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Change details, amount, or transaction type',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Selector
                  const Text(
                    'Transaction Type',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTypeChip(TransactionType.expense, 'Expense', Icons.arrow_upward),
                        const SizedBox(width: 8),
                        _buildTypeChip(TransactionType.income, 'Income', Icons.arrow_downward),
                        const SizedBox(width: 8),
                        _buildTypeChip(TransactionType.saving, 'Saving', Icons.savings),
                        const SizedBox(width: 8),
                        _buildTypeChip(TransactionType.emi, 'EMI', Icons.credit_card),
                        const SizedBox(width: 8),
                        _buildTypeChip(TransactionType.gold, 'Gold', Icons.monetization_on),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Amount Field
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        child: Text(
                          repo.settings.value.currencySymbol,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Description',
                      prefixIcon: Icon(Icons.label_outline),
                      hintText: 'e.g. Grocery, Salary, Investment',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Dropdown
                  if (categories.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey('edit_cat_${_currentType.name}'),
                      initialValue: categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : categories.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.icon, size: 18, color: c.color),
                              const SizedBox(width: 10),
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

                  // Savings Goal Linking (if saving type)
                  if (_currentType == TransactionType.saving && repo.savingGoals.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      key: const ValueKey('edit_saving_goal'),
                      initialValue: repo.savingGoals.any((g) => g.id == _selectedSavingGoalId)
                          ? _selectedSavingGoalId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Link to Savings Goal (Optional)',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('General Savings (No Goal)'),
                        ),
                        ...repo.savingGoals.map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(
                                '${g.name} (${(g.progressPercentage * 100).toInt()}%)',
                              ),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedSavingGoalId = val),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Date Picker Row
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 20, color: activeColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transaction Date',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatShort(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: activeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes Field
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.notes),
                      hintText: 'Add additional context or notes...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(TransactionType type, String label, IconData icon) {
    final isSelected = _currentType == type;
    final typeColor = _getTypeColor(type);

    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : typeColor,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
      ),
      selectedColor: typeColor,
      backgroundColor: typeColor.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? typeColor : typeColor.withValues(alpha: 0.25),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentType = type;
            _validateCategoryForCurrentType();
          });
        }
      },
    );
  }
}
