import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/data/models/saving_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class SavingsView extends StatelessWidget {
  final bool hideAppBar;

  const SavingsView({super.key, this.hideAppBar = false});

  void _showNewGoalDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final uuid = const Uuid();

    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final initialAmountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g. Emergency Fund, Car, Vacation',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${repo.settings.value.currencySymbol} ',
                labelText: 'Target Amount',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: initialAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${repo.settings.value.currencySymbol} ',
                labelText: 'Initial Balance (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.savings),
            onPressed: () async {
              final name = nameController.text.trim();
              final target = double.tryParse(targetController.text.trim()) ?? 0;
              final initial = double.tryParse(initialAmountController.text.trim()) ?? 0;

              if (name.isEmpty || target <= 0) return;

              final goal = SavingGoalModel(
                id: uuid.v4(),
                name: name,
                targetAmount: target,
                currentAmount: initial,
                category: name,
                colorValue: 0xFF3B82F6,
              );
              await repo.addSavingGoal(goal);
              Navigator.pop(ctx);
            },
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context, SavingGoalModel goal) {
    final repo = Get.find<FinanceRepository>();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deposit to ${goal.name}'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '${repo.settings.value.currencySymbol} ',
            labelText: 'Deposit Amount',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.savings),
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) return;

              await repo.addSavingDeposit(
                goalId: goal.id,
                amount: amount,
                date: DateTime.now(),
                category: goal.name,
                description: 'Deposit into ${goal.name}',
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Deposit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('Savings & Goals', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  tooltip: 'New Goal',
                  icon: const Icon(Icons.add, color: AppColors.savings),
                  onPressed: () => _showNewGoalDialog(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Obx(() {
        final goals = repo.savingGoals;
        final monthSavings = repo.getTotalSavingsAllocated(month: now.month, year: now.year);
        final monthIncome = repo.getTotalIncome(month: now.month, year: now.year);
        final savingsRate = monthIncome > 0 ? (monthSavings / monthIncome * 100) : 0.0;
        final totalAccumulated = repo.totalSavingsAccumulated;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Top Savings Metrics Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                          : [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Savings in Goals',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalAccumulated),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${savingsRate.toStringAsFixed(1)}% of Income',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'This Month Saved: ${CurrencyFormatter.format(monthSavings)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            '${goals.length} Active Goals',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Goals List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Savings Goals',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Goal'),
                      onPressed: () => _showNewGoalDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (goals.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.savings_outlined, size: 48, color: AppColors.lightTextMuted),
                            const SizedBox(height: 12),
                            const Text('No savings goals set', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text(
                              'Create goals like "Emergency Fund" or "Vacation" to track your progress.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...goals.map((goal) {
                    final progress = goal.progressPercentage;
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.savings.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.flag, color: AppColors.savings, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      goal.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () => repo.deleteSavingGoal(goal.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.savings),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                color: goal.isAchieved ? AppColors.success : AppColors.savings,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remaining: ${CurrencyFormatter.format(goal.remainingAmount)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.savings,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () => _showDepositDialog(context, goal),
                                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                  label: const Text('Deposit', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ),
                              ],
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
        backgroundColor: AppColors.savings,
        foregroundColor: Colors.white,
        tooltip: 'New Goal',
        onPressed: () => _showNewGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
