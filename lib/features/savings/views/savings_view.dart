import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
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
        content: SingleChildScrollView(
          child: Column(
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
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.savings),
            onPressed: () async {
              final name = nameController.text.trim();
              final target = num.tryParse(targetController.text.trim()) ?? 0;
              final initial = num.tryParse(initialAmountController.text.trim()) ?? 0;

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
              if (ctx.mounted) Navigator.pop(ctx);
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
              final amount = num.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) return;

              await repo.addSavingDeposit(
                goalId: goal.id,
                amount: amount,
                date: DateTime.now(),
                category: goal.name,
                description: 'Deposit into ${goal.name}',
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Deposit'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, SavingGoalModel goal) {
    final repo = Get.find<FinanceRepository>();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw from ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance: ${CurrencyFormatter.format(goal.currentAmount)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '${repo.settings.value.currencySymbol} ',
                labelText: 'Withdrawal Amount',
                helperText: 'Funds will be returned to your spendable cash balance',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Notes / Reason (Optional)',
                hintText: 'e.g. Emergency or planned spend',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              final amount = num.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) return;
              if (amount > goal.currentAmount) {
                Get.snackbar('Insufficient Funds', 'Cannot withdraw more than goal balance.');
                return;
              }

              await repo.addSavingWithdrawal(
                goalId: goal.id,
                amount: amount,
                date: DateTime.now(),
                category: goal.name,
                description: noteController.text.trim().isNotEmpty
                    ? noteController.text.trim()
                    : 'Withdrawal from ${goal.name}',
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Withdrawal', style: TextStyle(color: Colors.white)),
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
        final monthDeposits = repo.getTotalSavingsAllocated(month: now.month, year: now.year);
        final monthWithdrawals = repo.getTotalSavingsWithdrawn(month: now.month, year: now.year);
        final openingSavings = repo.getSavingsOpeningBalance(now.month, now.year);
        final closingSavings = repo.getSavingsClosingBalance(now.month, now.year);
        final monthIncome = repo.getTotalIncome(month: now.month, year: now.year);
        final netSavings = monthDeposits - monthWithdrawals;
        final savingsRate = monthIncome > 0 ? (netSavings / monthIncome * 100).clamp(0.0, 100.0) : 0.0;
        final totalAccumulated = repo.totalSavingsAccumulated;
        final recentRecords = repo.savingsRecords.toList().reversed.take(15).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: context.pagePadding,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Savings in Goals',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.format(totalAccumulated),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${savingsRate.toStringAsFixed(1)}% of Income',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
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
                            'Net Saved This Month: ${CurrencyFormatter.format(netSavings)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                const SizedBox(height: 12),

                // Monthly Savings Carry-Forward Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.savings.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.sync_alt, size: 14, color: AppColors.savings),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormatter.formatMonthYear(now)} Savings Carry-Forward',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.savings.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CARRY FORWARD',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.savings),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildSavingsStatBox(
                                width: width,
                                label: 'Opening Balance',
                                amount: openingSavings,
                                color: Colors.blue.shade600,
                                icon: Icons.history_toggle_off,
                                note: 'From prior months',
                              ),
                              _buildSavingsStatBox(
                                width: width,
                                label: 'Month Deposits',
                                amount: monthDeposits,
                                color: AppColors.income,
                                icon: Icons.arrow_downward,
                                prefix: '+',
                                note: 'Allocated to goals',
                              ),
                              _buildSavingsStatBox(
                                width: width,
                                label: 'Month Withdrawals',
                                amount: monthWithdrawals,
                                color: AppColors.expense,
                                icon: Icons.arrow_upward,
                                prefix: '-',
                                note: 'Returned to cash',
                              ),
                              _buildSavingsStatBox(
                                width: width,
                                label: 'Closing Balance',
                                amount: closingSavings,
                                color: AppColors.savings,
                                icon: Icons.account_balance_wallet,
                                note: 'Carries to next month',
                              ),
                            ],
                          );
                        },
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
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.savings.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.flag, color: AppColors.savings, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          goal.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () => repo.deleteSavingGoal(goal.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                value: progress.toDouble(),
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                color: goal.isAchieved ? AppColors.success : AppColors.savings,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Remaining: ${CurrencyFormatter.format(goal.remainingAmount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (goal.currentAmount > 0) ...[
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.expense,
                                          side: BorderSide(color: AppColors.expense.withValues(alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                          minimumSize: Size.zero,
                                        ),
                                        onPressed: () => _showWithdrawDialog(context, goal),
                                        icon: const Icon(Icons.remove, size: 14),
                                        label: const Text('Withdraw', style: TextStyle(fontSize: 11)),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.savings,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Recent Savings Activity Section
                if (recentRecords.isNotEmpty) ...[
                  const Text(
                    'Recent Savings Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...recentRecords.map((rec) {
                    final isDeposit = rec.type.isDeposit;
                    final isSmall = context.isMobileSmall;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: (isDeposit ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isDeposit ? AppColors.income : AppColors.expense,
                            size: 16,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              rec.category,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (isDeposit ? AppColors.income : AppColors.expense).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rec.type.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDeposit ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${DateFormatter.formatShort(rec.date)}${rec.description != null ? ' • ${rec.description}' : ''}',
                          style: TextStyle(fontSize: isSmall ? 10.5 : 11.5, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isDeposit ? '+' : '-'}${CurrencyFormatter.format(rec.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDeposit ? AppColors.income : AppColors.expense,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                              onPressed: () => repo.deleteSavingRecord(rec.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_savings',
        backgroundColor: AppColors.savings,
        foregroundColor: Colors.white,
        tooltip: 'New Goal',
        onPressed: () => _showNewGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSavingsStatBox({
    required double width,
    required String label,
    required num amount,
    required Color color,
    required IconData icon,
    String prefix = '',
    String? note,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$prefix${CurrencyFormatter.format(amount)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 1),
              Text(
                note,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
