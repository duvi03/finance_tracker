import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/widgets/metric_summary_card.dart';
import 'package:finance_tracker/core/widgets/quick_add_dialog.dart';
import 'package:finance_tracker/core/widgets/transaction_tile.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/features/dashboard/controllers/dashboard_controller.dart';
import 'package:finance_tracker/features/shell/views/main_shell_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Artha',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Quick Add',
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            onPressed: () => QuickAddModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final selectedDate = controller.selectedDate;
        final monthIncome = controller.monthIncome;
        final monthExpense = controller.monthExpense;
        final monthEmi = controller.monthEmi;
        final monthSavings = controller.monthSavings;
        final monthGold = controller.monthGold;
        final monthBalance = controller.monthAvailableBalance;
        final netWorth = controller.totalNetWorth;
        final recentTxs = controller.recentTransactions;
        final upcomingEmis = controller.upcomingEmis;
        final categoryMap = controller.categoryExpensesMap;

        return RefreshIndicator(
          onRefresh: () async => controller.repo.loadAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Month Navigation Header ---
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Previous Month',
                              onPressed: controller.previousMonth,
                            ),
                            InkWell(
                              onTap: controller.resetToCurrentMonth,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormatter.formatMonthYear(selectedDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Next Month',
                              onPressed: controller.nextMonth,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- Primary Available Cash & Net Worth Banner ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                              : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${DateFormatter.formatMonthYear(selectedDate)} Remaining',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Net Worth: ${CurrencyFormatter.format(netWorth, compact: true)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(monthBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          Text(
                            'Balance = Income - (Expenses + EMI + Savings + Gold)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- 5 Metric Cards Breakdown ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: MetricSummaryCard(
                                label: 'Income',
                                amount: monthIncome,
                                icon: Icons.arrow_downward,
                                color: AppColors.income,
                                onTap: () => QuickAddModal.show(context, initialType: TransactionType.income),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MetricSummaryCard(
                                label: 'Expenses',
                                amount: monthExpense,
                                icon: Icons.arrow_upward,
                                color: AppColors.expense,
                                onTap: () => QuickAddModal.show(context, initialType: TransactionType.expense),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MetricSummaryCard(
                                label: 'EMI Payments',
                                amount: monthEmi,
                                icon: Icons.credit_card,
                                color: AppColors.emi,
                                onTap: () => Get.find<MainShellController>().changeTab(2),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MetricSummaryCard(
                                label: 'Savings Deposit',
                                amount: monthSavings,
                                icon: Icons.savings,
                                color: AppColors.savings,
                                onTap: () => Get.find<MainShellController>().changeTab(3),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: MetricSummaryCard(
                                label: 'Gold Investment',
                                amount: monthGold,
                                subtitle: '${controller.repo.totalGoldGrams.toStringAsFixed(2)}g accumulated',
                                icon: Icons.monetization_on,
                                color: AppColors.gold,
                                onTap: () => Get.find<MainShellController>().changeTab(3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Upcoming EMIs Section ---
                    if (upcomingEmis.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming EMIs',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          TextButton(
                            onPressed: () => Get.find<MainShellController>().changeTab(2),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...upcomingEmis.map((payment) {
                        final plan = controller.repo.emiPlans
                            .firstWhereOrNull((p) => p.id == payment.emiPlanId);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.emi.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt, color: AppColors.emi, size: 22),
                            ),
                            title: Text(
                              plan?.purchaseName ?? 'EMI Installment',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Installment ${payment.installmentNumber} • Due ${DateFormatter.formatShort(payment.dueDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emi,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                await controller.repo.toggleEmiPaymentStatus(
                                  emiPlanId: payment.emiPlanId,
                                  paymentId: payment.id,
                                );
                              },
                              child: Text(
                                'Pay ${CurrencyFormatter.format(payment.amount)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // --- Category Spending Breakdown ---
                    if (categoryMap.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Expense Breakdown',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          TextButton(
                            onPressed: () => Get.find<MainShellController>().changeTab(4), // More/Reports
                            child: const Text('Full Reports'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: categoryMap.entries.map((entry) {
                              final percentage = monthExpense > 0 ? (entry.value / monthExpense) : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        Text(
                                          '${CurrencyFormatter.format(entry.value)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        color: AppColors.expense,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- Recent Transactions ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        TextButton(
                          onPressed: () => Get.find<MainShellController>().changeTab(1),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (recentTxs.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.lightTextMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No transactions yet',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap the + button to add your first transaction.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...recentTxs.map((tx) => TransactionTile(
                            transaction: tx,
                            onDelete: () => controller.repo.deleteTransaction(tx.id),
                          )),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => QuickAddModal.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
