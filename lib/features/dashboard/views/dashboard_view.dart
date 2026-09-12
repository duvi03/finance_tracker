import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
import 'package:finance_tracker/core/widgets/metric_summary_card.dart';
import 'package:finance_tracker/core/widgets/edit_transaction_dialog.dart';
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
                color: AppColors.primary.withValues(alpha: 0.15),
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
            onPressed: () => QuickAddModal.show(context, initialDate: controller.effectiveDateForNewEntry),
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
        final monthBalance = controller.monthRemainingBalance;
        final netWorth = controller.totalNetWorth;
        final recentTxs = controller.recentTransactions;
        final upcomingEmis = controller.upcomingEmis;
        final categoryMap = controller.categoryExpensesMap;
        final isSmall = context.isMobileSmall;

        return RefreshIndicator(
          onRefresh: () async => controller.repo.loadAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: context.pagePadding,
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

                    // --- Primary Remaining Cash & Net Worth Banner ---
                    Container(
                      padding: EdgeInsets.all(context.isMobileSmall ? 14 : (context.isMobileNarrow ? 16 : 20)),
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
                            color: AppColors.primary.withValues(alpha: 0.2),
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
                              Expanded(
                                child: Text(
                                  '${DateFormatter.formatMonthYear(selectedDate)} Remaining Balance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: context.isMobileSmall ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Net Worth: ${CurrencyFormatter.format(netWorth, compact: true)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.isMobileSmall ? 10 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.format(monthBalance),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.isMobileSmall ? 26 : 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available: ${CurrencyFormatter.format(controller.monthAvailableMoney)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: context.isMobileSmall ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Opening: ${CurrencyFormatter.format(controller.monthOpeningBalance)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: context.isMobileSmall ? 10 : 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- Monthly Carry-Forward Summary Section ---
                    _buildMonthlySummaryCard(
                      context,
                      selectedDate: selectedDate,
                      openingBalance: controller.monthOpeningBalance,
                      income: monthIncome,
                      expenses: controller.monthTotalOutflows,
                      remaining: monthBalance,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // --- 5 Metric Cards Breakdown ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 360;
                        final gap = isSmall ? 8.0 : 12.0;
                        final cardWidth = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: MetricSummaryCard(
                                label: 'Income',
                                amount: monthIncome,
                                icon: Icons.arrow_downward,
                                color: AppColors.income,
                                onTap: () => QuickAddModal.show(
                                  context,
                                  initialType: TransactionType.income,
                                  initialDate: controller.effectiveDateForNewEntry,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MetricSummaryCard(
                                label: 'Expenses',
                                amount: monthExpense,
                                icon: Icons.arrow_upward,
                                color: AppColors.expense,
                                onTap: () => QuickAddModal.show(
                                  context,
                                  initialType: TransactionType.expense,
                                  initialDate: controller.effectiveDateForNewEntry,
                                ),
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
                          Expanded(
                            child: Text(
                              'Upcoming EMIs',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 15 : 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Get.find<MainShellController>().changeTab(2),
                            style: TextButton.styleFrom(
                              padding: isSmall ? const EdgeInsets.symmetric(horizontal: 4) : null,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...upcomingEmis.map((payment) {
                        final plan = controller.repo.emiPlans
                            .firstWhereOrNull((p) => p.id == payment.emiPlanId);
                        final isSmall = context.isMobileSmall;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 14, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.emi.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt, color: AppColors.emi, size: 20),
                            ),
                            title: Text(
                              plan?.purchaseName ?? 'EMI Installment',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 13 : 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Inst. ${payment.installmentNumber} • Due ${DateFormatter.formatShort(payment.dueDate)}',
                              style: TextStyle(fontSize: isSmall ? 11 : 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emi,
                                padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 12),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () async {
                                await controller.repo.toggleEmiPaymentStatus(
                                  emiPlanId: payment.emiPlanId,
                                  paymentId: payment.id,
                                );
                              },
                              child: Text(
                                'Pay ${CurrencyFormatter.format(payment.amount)}',
                                style: TextStyle(fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.bold),
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
                          Expanded(
                            child: Text(
                              'Monthly Expense Breakdown',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 15 : 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Get.find<MainShellController>().changeTab(4), // More/Reports
                            style: TextButton.styleFrom(
                              padding: isSmall ? const EdgeInsets.symmetric(horizontal: 4) : null,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '${CurrencyFormatter.format(entry.value)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 12 : 13),
                                          ),
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
                        Expanded(
                          child: Text(
                            'Recent Transactions',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 15 : 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Get.find<MainShellController>().changeTab(1),
                          style: TextButton.styleFrom(
                            padding: isSmall ? const EdgeInsets.symmetric(horizontal: 4) : null,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
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
                            onEdit: () => EditTransactionModal.show(context, tx),
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
        heroTag: 'fab_dashboard',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => QuickAddModal.show(context, initialDate: controller.effectiveDateForNewEntry),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(
    BuildContext context, {
    required DateTime selectedDate,
    required num openingBalance,
    required num income,
    required num expenses,
    required num remaining,
    required bool isDark,
  }) {
    final isSmall = context.isMobileSmall;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assessment_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormatter.formatMonthYear(selectedDate)} Summary',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_alt, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Carry-Forward',
                      style: TextStyle(
                        fontSize: isSmall ? 9.5 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
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
                  _buildSummaryItem(
                    width: width,
                    label: 'Opening Balance',
                    amount: openingBalance,
                    color: Colors.blue.shade600,
                    icon: Icons.account_balance_outlined,
                    note: 'From previous month',
                  ),
                  _buildSummaryItem(
                    width: width,
                    label: 'Income',
                    amount: income,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                    prefix: '+',
                    note: 'Total inflow',
                  ),
                  _buildSummaryItem(
                    width: width,
                    label: 'Expenses & Outflows',
                    amount: expenses,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                    prefix: '-',
                    note: 'Spend & allocations',
                  ),
                  _buildSummaryItem(
                    width: width,
                    label: 'Remaining Balance',
                    amount: remaining,
                    color: remaining >= 0 ? AppColors.income : AppColors.expense,
                    icon: Icons.account_balance_wallet,
                    note: 'Carries to next month',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required double width,
    required String label,
    required num amount,
    required Color color,
    required IconData icon,
    required String note,
    String prefix = '',
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$prefix${CurrencyFormatter.format(amount)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
