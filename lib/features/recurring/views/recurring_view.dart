import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/models/recurring_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class RecurringView extends StatelessWidget {
  const RecurringView({super.key});

  void _showNewRuleDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final uuid = const Uuid();

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType ruleType = TransactionType.income;
    RecurringFrequency frequency = RecurringFrequency.monthly;
    String selectedCat = 'salary';
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final categories = repo.categories
              .where((c) =>
                  c.type == CategoryType.both ||
                  (ruleType == TransactionType.income && c.type == CategoryType.income) ||
                  (ruleType == TransactionType.expense && c.type == CategoryType.expense))
              .toList();

          return AlertDialog(
            title: const Text('New Recurring Rule'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(value: TransactionType.income, label: Text('Income')),
                        ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                      ],
                      selected: {ruleType},
                      onSelectionChanged: (val) {
                        setState(() {
                          ruleType = val.first;
                          selectedCat = ruleType == TransactionType.income ? 'salary' : 'rent';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Rule Title',
                        hintText: ruleType == TransactionType.income
                            ? 'e.g. Monthly Salary'
                            : 'e.g. House Rent, WiFi, Netflix',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixText: '${repo.settings.value.currencySymbol} ',
                        labelText: 'Recurring Amount',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RecurringFrequency>(
                      isExpanded: true,
                      value: frequency,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: RecurringFrequency.values
                          .map((f) => DropdownMenuItem(value: f, child: Text(f.label,overflow: TextOverflow.ellipsis,)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => frequency = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: categories.any((c) => c.id == selectedCat) ? selectedCat : categories.first.id,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCat = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Effective Start Date',
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(DateFormatter.formatShort(startDate)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ruleType == TransactionType.income ? AppColors.income : AppColors.expense,
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (title.isEmpty || amount <= 0) return;

                  final rule = RecurringRuleModel(
                    id: uuid.v4(),
                    title: title,
                    amount: amount,
                    type: ruleType,
                    frequency: frequency,
                    startDate: startDate,
                    categoryId: selectedCat,
                    lastGeneratedDate: startDate,
                    isActive: true,
                  );

                  await repo.addRecurringRule(rule);
                  Navigator.pop(ctx);
                },
                child: const Text('Create Rule'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Run Auto-Check Now',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              repo.processRecurringRules();
              Get.snackbar(
                'Auto-Check Complete',
                'Recurring transactions evaluated. No duplicates generated.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          IconButton(
            tooltip: 'Add Rule',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showNewRuleDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final rules = repo.recurringRules;

        if (rules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.repeat, size: 64, color: AppColors.lightTextMuted),
                const SizedBox(height: 16),
                const Text('No Recurring Rules Configured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                const Text('Set up monthly salary, subscriptions, or rent for automatic logging.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showNewRuleDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create First Recurring Rule'),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView.builder(
              padding: context.pagePadding,
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                final category = repo.getCategoryById(rule.categoryId);
                final isIncome = rule.type == TransactionType.income;
                final color = isIncome ? AppColors.income : AppColors.expense;
                final isSmall = context.isMobileSmall;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(category.icon, color: color, size: 20),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rule.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(rule.amount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: isSmall ? 14 : 15),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${rule.frequency.label} • Category: ${category.name}',
                          style: TextStyle(fontSize: isSmall ? 11 : 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Started: ${DateFormatter.formatShort(rule.startDate)} ${rule.lastGeneratedDate != null ? '• Last run: ${DateFormatter.formatShort(rule.lastGeneratedDate!)}' : ''}',
                          style: TextStyle(fontSize: isSmall ? 10 : 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: rule.isActive,
                      activeColor: color,
                      onChanged: (val) {
                        repo.updateRecurringRule(rule.copyWith(isActive: val));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_recurring',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Rule',
        onPressed: () => _showNewRuleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
