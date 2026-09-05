import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final FinanceRepository repo = Get.find<FinanceRepository>();
  final int _selectedMonthsBack = 6;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {

        // Expense category distribution for current month
        final expenseMap = <String, double>{};
        for (final tx in repo.transactions) {
          if (tx.type == TransactionType.expense &&
              tx.date.month == now.month &&
              tx.date.year == now.year) {
            final cat = repo.getCategoryById(tx.categoryId).name;
            expenseMap[cat] = (expenseMap[cat] ?? 0.0) + tx.amount;
          }
        }

        // Prepare pie chart sections
        final pieSections = <PieChartSectionData>[];
        final colors = [
          AppColors.expense,
          AppColors.emi,
          AppColors.primary,
          AppColors.savings,
          Colors.purple,
          Colors.teal,
          Colors.amber,
          Colors.indigo,
        ];
        int colorIdx = 0;
        final totalExpense = expenseMap.values.fold(0.0, (s, v) => s + v);

        expenseMap.forEach((category, amount) {
          final pct = totalExpense > 0 ? (amount / totalExpense * 100) : 0.0;
          final color = colors[colorIdx % colors.length];
          colorIdx++;
          pieSections.add(
            PieChartSectionData(
              value: amount,
              title: '${pct.toStringAsFixed(0)}%',
              color: color,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        });

        // Prepare monthly comparison bar data for last 6 months
        final monthlyBars = <BarChartGroupData>[];
        for (int i = _selectedMonthsBack - 1; i >= 0; i--) {
          final target = DateTime(now.year, now.month - i, 1);
          final inc = repo.getTotalIncome(month: target.month, year: target.year);
          final exp = repo.getTotalExpenses(month: target.month, year: target.year) +
              repo.getTotalEmiPaid(month: target.month, year: target.year);

          monthlyBars.add(
            BarChartGroupData(
              x: _selectedMonthsBack - 1 - i,
              barRods: [
                BarChartRodData(
                  toY: inc,
                  color: AppColors.income,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: exp,
                  color: AppColors.expense,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: context.pagePadding,
              children: [
                // Top Net Wealth Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Wealth Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text('Available Cash Balance')),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(repo.allTimeAvailableBalance),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text('Accumulated Savings Goals')),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(repo.totalSavingsAccumulated),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.savings),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Physical & Digital Gold (${repo.totalGoldGrams.toStringAsFixed(2)}g)', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(repo.totalGoldInvestedInr),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Estimated Total Net Worth',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(repo.totalNetWorth),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Income vs Expenses Monthly Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            const Text(
                              'Income vs Outflow',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 10, height: 10, color: AppColors.income),
                                const SizedBox(width: 4),
                                const Text('Income', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 12),
                                Container(width: 10, height: 10, color: AppColors.expense),
                                const SizedBox(width: 4),
                                const Text('Outflow', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: monthlyBars,
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final idx = val.toInt();
                                      final target = DateTime(now.year, now.month - (_selectedMonthsBack - 1 - idx), 1);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          DateFormatter.formatMonthYear(target).substring(0, 3),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Expense Donut Chart
                if (pieSections.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Breakdown (${DateFormatter.formatMonthYear(now)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: pieSections,
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: expenseMap.entries.map((e) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.expense,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${e.key}: ${CurrencyFormatter.format(e.value)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Gold Portfolio Analytics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gold Accumulation Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniReportStat(
                                label: 'Total Weight',
                                value: '${repo.totalGoldGrams.toStringAsFixed(2)} g',
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniReportStat(
                                label: 'Total Invested',
                                value: CurrencyFormatter.format(repo.totalGoldInvestedInr),
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniReportStat(
                                label: 'Avg Rate / g',
                                value: CurrencyFormatter.format(repo.averageGoldRatePerGram),
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MiniReportStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniReportStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ),
      ],
    );
  }
}
