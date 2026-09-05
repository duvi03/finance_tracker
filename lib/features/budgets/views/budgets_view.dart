import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class BudgetsView extends StatelessWidget {
  const BudgetsView({super.key});

  void _showSetBudgetDialog(BuildContext context, {String? categoryId, double? currentLimit}) {
    final repo = Get.find<FinanceRepository>();
    final now = DateTime.now();

    final limitController = TextEditingController(
      text: currentLimit != null ? currentLimit.toStringAsFixed(0) : '',
    );
    String selectedCat = categoryId ??
        repo.categories.firstWhere((c) => c.type == CategoryType.expense).id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: repo.categories
                      .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
                      .map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 18),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '${repo.settings.value.currencySymbol} ',
                    labelText: 'Monthly Spending Limit',
                    hintText: 'e.g. 5000',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final limit = double.tryParse(limitController.text.trim()) ?? 0;
                if (limit <= 0) return;

                await repo.setBudget(
                  categoryId: selectedCat,
                  monthlyLimit: limit,
                  month: now.month,
                  year: now.year,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Add Budget',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showSetBudgetDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final currentBudgets = repo.budgets
            .where((b) => b.month == now.month && b.year == now.year)
            .toList();

        final totalBudget = currentBudgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
        final totalSpentOnBudgeted = currentBudgets.fold(0.0, (sum, b) {
          return sum + repo.getCategorySpending(b.categoryId, now.month, now.year);
        });

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: context.pagePadding,
              children: [
                // Overview card
                Container(
                  padding: EdgeInsets.all(context.isMobileSmall ? 12 : 18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Budgeted vs Spent', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${CurrencyFormatter.format(totalSpentOnBudgeted)} / ${CurrencyFormatter.format(totalBudget)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.isMobileSmall ? 17 : 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        totalBudget > 0
                            ? '${(totalSpentOnBudgeted / totalBudget * 100).toStringAsFixed(0)}% used'
                            : '0%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalSpentOnBudgeted > totalBudget ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Active Category Budgets',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobileSmall ? 15 : 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: context.isMobileSmall ? const EdgeInsets.symmetric(horizontal: 4) : null,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Budget'),
                      onPressed: () => _showSetBudgetDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (currentBudgets.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline, size: 48, color: AppColors.lightTextMuted),
                            const SizedBox(height: 12),
                            const Text('No budgets configured', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Set monthly spending limits for categories like Food, Transport, etc.'),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...currentBudgets.map((b) {
                    final category = repo.getCategoryById(b.categoryId);
                    final spent = repo.getCategorySpending(b.categoryId, now.month, now.year);
                    final limit = b.monthlyLimit;
                    final ratio = limit > 0 ? (spent / limit) : 0.0;
                    final remaining = limit - spent;

                    Color statusColor = AppColors.success;
                    if (ratio >= 1.0) {
                      statusColor = AppColors.danger;
                    } else if (ratio >= 0.8) {
                      statusColor = AppColors.warning;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: category.color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(category.icon, color: category.color, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _showSetBudgetDialog(
                                        context,
                                        categoryId: b.categoryId,
                                        currentLimit: b.monthlyLimit,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => repo.deleteBudget(b.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Spent: ${CurrencyFormatter.format(spent)} of ${CurrencyFormatter.format(limit)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(ratio * 100).toInt()}%',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              remaining >= 0
                                  ? 'Remaining: ${CurrencyFormatter.format(remaining)}'
                                  : 'Over budget by ${CurrencyFormatter.format(remaining.abs())}!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: remaining < 0 ? FontWeight.bold : FontWeight.normal,
                                color: remaining < 0 ? AppColors.danger : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_budgets',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Budget',
        onPressed: () => _showSetBudgetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
