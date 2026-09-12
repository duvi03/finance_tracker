import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/gold_model.dart';
import '../../../data/repositories/finance_repository.dart';

class GoldView extends StatefulWidget {
  final bool hideAppBar;

  const GoldView({
    super.key,
    this.hideAppBar = false,
  });

  @override
  State<GoldView> createState() => _GoldViewState();
}

class _GoldViewState extends State<GoldView> with SingleTickerProviderStateMixin {
  final repo = Get.find<FinanceRepository>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: AppColors.gold,
      labelColor: AppColors.gold,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(icon: Icon(Icons.shield_outlined), text: 'Gold Vault'),
        Tab(icon: Icon(Icons.auto_awesome), text: 'Gold SIP / Schemes'),
        Tab(icon: Icon(Icons.handshake_outlined), text: 'Gold Loans'),
      ],
    );

    final tabViews = TabBarView(
      controller: _tabController,
      children: [
        _buildVaultTab(context),
        _buildSipTab(context),
        _buildEmiTab(context),
      ],
    );

    if (widget.hideAppBar) {
      return Column(
        children: [
          Material(
            color: Theme.of(context).cardColor,
            elevation: 1,
            child: tabBar,
          ),
          Expanded(child: tabViews),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold & Precious Metals'),
        bottom: tabBar,
      ),
      body: tabViews,
    );
  }

  // ==========================================
  // TAB 1: GOLD VAULT (BUY / SELL / HOLDINGS)
  // ==========================================
  Widget _buildVaultTab(BuildContext context) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Obx(() {
      final holdings = repo.goldInvestments;
      final totalGrams = repo.totalGoldGrams;
      final totalInvested = repo.totalGoldInvestedInr;
      final avgRate = repo.averageGoldRatePerGram;
      final liveRate = repo.currentGoldRatePerGram.value;
      final currentValue = totalGrams * liveRate;
      final unrealizedPL = currentValue - totalInvested;
      final realizedPL = repo.totalGoldRealizedProfitLoss;

      final now = DateTime.now();
      final openingGrams = repo.getGoldOpeningGrams(now.month, now.year);
      final monthBought = repo.getMonthGoldBoughtGrams(now.month, now.year);
      final monthSold = repo.getMonthGoldSoldGrams(now.month, now.year);
      final closingGrams = repo.getGoldClosingGrams(now.month, now.year);

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Portfolio Summary Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.2),
                    Colors.amber.shade900.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars, color: AppColors.gold, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Digital Gold Vault',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Text(
                          '24K • 99.9%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Gold Holdings', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${totalGrams.toStringAsFixed(3)} g',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Avg: ₹${avgRate.toStringAsFixed(0)}/g',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Current Value', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            curFmt.format(currentValue),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Live: ₹${liveRate.toStringAsFixed(0)}/g',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (unrealizedPL >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Unrealized P&L', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              Text(
                                '${unrealizedPL >= 0 ? '+' : ''}${curFmt.format(unrealizedPL)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: unrealizedPL >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (realizedPL >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Realized P&L', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              Text(
                                '${realizedPL >= 0 ? '+' : ''}${curFmt.format(realizedPL)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: realizedPL >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Monthly Inventory Carry-Forward Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_toggle_off, color: Colors.amber.shade800, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Monthly Inventory Carry-Forward (${DateFormat('MMMM yyyy').format(now)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInventoryItem('Opening Vault', '${openingGrams.toStringAsFixed(3)} g', Colors.grey.shade700),
                      _buildInventoryItem('Bought', '+${monthBought.toStringAsFixed(3)} g', Colors.green.shade700),
                      _buildInventoryItem('Sold', '-${monthSold.toStringAsFixed(3)} g', Colors.deepOrange.shade700),
                      _buildInventoryItem('Closing Vault', '${closingGrams.toStringAsFixed(3)} g', AppColors.gold),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Buy & Sell
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBuyDialog(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Buy Gold'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: totalGrams <= 0 ? null : () => _showSellDialog(context, totalGrams, avgRate),
                  icon: const Icon(Icons.sell_outlined, size: 18),
                  label: const Text('Sell Gold'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange.shade800,
                    side: BorderSide(color: totalGrams <= 0 ? Colors.grey.shade300 : Colors.deepOrange.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Transaction History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vault Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${holdings.length} records', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),

          if (holdings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('No gold transactions yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      const Text('Tap "Buy Gold" to record your first purchase.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holdings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final item = holdings[idx];
                final isBuy = item.isBuy;
                final isLoss = (item.realizedProfitLoss ?? 0) < 0;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBuy
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : Colors.deepOrange.withValues(alpha: 0.15),
                      child: Icon(
                        isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isBuy ? Colors.amber.shade900 : Colors.deepOrange.shade700,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBuy ? 'Bought Gold (${item.grams.toStringAsFixed(3)} g)' : 'Sold Gold (${item.grams.toStringAsFixed(3)} g)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          curFmt.format(item.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBuy ? Colors.black87 : Colors.deepOrange.shade800,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '@ ₹${item.ratePerGram.toStringAsFixed(0)}/g • ${DateFormat('dd MMM yyyy').format(item.date)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            if (!isBuy && item.realizedProfitLoss != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLoss
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'P&L: ${isLoss ? '' : '+'}${curFmt.format(item.realizedProfitLoss!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLoss ? Colors.red.shade700 : Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.notes!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => _confirmDeleteGold(context, item),
                    ),
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildInventoryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ====================================================
  // TAB 2: GOLD SIP & JEWELER SCHEMES (TIERED BENEFIT)
  // ====================================================
  Widget _buildSipTab(BuildContext context) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Obx(() {
      final schemes = repo.goldSipSchemes;
      final totalPaid = repo.totalGoldSipPaidInr;
      final totalJewelleryValue = repo.totalGoldSipJewelleryValueInr;
      final totalBonus = (totalJewelleryValue - totalPaid) > 0 ? (totalJewelleryValue - totalPaid) : 0;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SIP Hero Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.25),
                    Colors.deepOrange.shade900.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.gold, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Gold SIP & Savings Schemes',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Text(
                          '${schemes.length} Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Capital Contributed', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            curFmt.format(totalPaid),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Current Jewellery Value', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            curFmt.format(totalJewelleryValue),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Accrued Bonus Profit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          '+${curFmt.format(totalBonus)} extra jewellery',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _showAddGoldSipDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Start New Gold SIP / Savings Scheme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          if (schemes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('No Gold SIP Schemes started yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      const Text(
                        'Start a 30-Month Tiered Gold SIP (e.g. ₹20,000/mo scaling to 450% benefit) or Jeweler 11-Month Chit Scheme.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...schemes.map((scheme) => _buildGoldSipCard(context, scheme, curFmt)),
        ],
      );
    });
  }

  Widget _buildGoldSipCard(BuildContext context, GoldSipSchemeModel scheme, NumberFormat curFmt) {
    final progress = scheme.totalMonths > 0
        ? (scheme.paidInstallmentsCount / scheme.totalMonths).clamp(0.0, 1.0)
        : 0.0;
    final isMature = scheme.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Jeweler Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.schemeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${scheme.jewelerName} • ${scheme.totalMonths} Months Plan',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    '${curFmt.format(scheme.monthlyInstallment)}/mo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Installments: ${scheme.paidInstallmentsCount} of ${scheme.totalMonths} Paid',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: isMature ? Colors.green : AppColors.gold,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 14),

            // Value comparison grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Capital Contributed', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(curFmt.format(scheme.totalPaidAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Current Jewellery Value', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(curFmt.format(scheme.currentJewelleryValue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accrued Benefit: ${scheme.currentAccruedBenefitPercent > 0 ? "${scheme.currentAccruedBenefitPercent}% (+${curFmt.format(scheme.currentAccruedBenefitAmount)})" : "None yet (< month 6)"}',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Final Target: ${curFmt.format(scheme.finalJewelleryValue)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Maturity Date Info
            Row(
              children: [
                Icon(Icons.event_available, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Maturity: ${DateFormat('dd MMM yyyy').format(scheme.maturityDate)} (${scheme.maturityWaitDays} days grace)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action buttons: View Tier Table & Checklist
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTierScheduleModal(context, scheme),
                    icon: const Icon(Icons.table_chart_outlined, size: 16),
                    label: const Text('Benefit Schedule Table', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete Scheme',
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _confirmDeleteSipScheme(context, scheme),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Expandable Checklist of Monthly Installments
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Payment Checklist (Monthly Installments)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                children: scheme.payments.map((payment) {
                  final benefitPct = scheme.benefitPercentAt(payment.installmentNumber);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: payment.isPaid ? Colors.green : Colors.grey.shade300,
                      child: Icon(
                        payment.isPaid ? Icons.check : Icons.schedule,
                        size: 14,
                        color: payment.isPaid ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    title: Text(
                      'Month #${payment.installmentNumber} • ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: payment.isPaid ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      benefitPct > 0 ? 'Eligible benefit tier: $benefitPct%' : 'Initial lock-in period',
                      style: TextStyle(fontSize: 11, color: benefitPct > 0 ? Colors.amber.shade900 : Colors.grey.shade500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          curFmt.format(payment.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: payment.isPaid,
                          activeColor: Colors.green,
                          onChanged: (_) {
                            repo.toggleGoldSipPayment(scheme.id, payment.id);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: BENEFIT TIER SCHEDULE TABLE
  // ==========================================
  void _showTierScheduleModal(BuildContext context, GoldSipSchemeModel scheme) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final rows = scheme.buildTierSchedule();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${scheme.schemeName} — Benefit Schedule',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Monthly Installment: ${curFmt.format(scheme.monthlyInstallment)} • ${scheme.totalMonths} Months',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    'Jewellery Value* = Cumulative Installments Paid + (Benefit % × Monthly Installment). Final Month ${scheme.totalMonths} yields ${scheme.finalBenefitPercent}% = +${curFmt.format(scheme.finalBenefitAmount)} bonus, delivering ${curFmt.format(scheme.finalJewelleryValue)} jewellery value after ${scheme.maturityWaitDays} days grace.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Installment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Benefit %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Benefit on EMI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Cumulative Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Jewellery Value*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: rows.map((r) {
                          final isCurrentMonth = r.month == scheme.paidInstallmentsCount;
                          final rowBg = isCurrentMonth
                              ? Colors.amber.withValues(alpha: 0.15)
                              : (r.isPaid ? Colors.green.withValues(alpha: 0.05) : null);

                          return DataRow(
                            color: rowBg != null ? WidgetStateProperty.all(rowBg) : null,
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    if (isCurrentMonth)
                                      const Icon(Icons.arrow_right, color: AppColors.gold, size: 16),
                                    Text('Month ${r.month}', style: TextStyle(fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal)),
                                  ],
                                ),
                              ),
                              DataCell(Text(curFmt.format(r.monthlyInstallment))),
                              DataCell(Text(r.benefitPercent > 0 ? '${r.benefitPercent}%' : '—')),
                              DataCell(Text(r.benefitAmount > 0 ? curFmt.format(r.benefitAmount) : '—')),
                              DataCell(Text(curFmt.format(r.cumulativePaid))),
                              DataCell(
                                Text(
                                  curFmt.format(r.jewelleryValue),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: r.benefitPercent > 0 ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                              ),
                              DataCell(
                                r.isPaid
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('Paid', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                      )
                                    : Text('Due ${DateFormat('dd MMM').format(r.dueDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ====================================================
  // TAB 3: GOLD LOANS / BORROW EMI
  // ====================================================
  Widget _buildEmiTab(BuildContext context) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Obx(() {
      final plans = repo.goldEmiPlans;
      final borrowPlans = plans.where((p) => p.isBorrowLoan).toList();

      final totalBorrowPrincipal = borrowPlans.fold<num>(0, (s, p) => s + p.principalAmount);
      final totalBorrowEmi = borrowPlans.fold<num>(0, (s, p) => s + p.monthlyEmi);
      final totalBorrowInterest = borrowPlans.fold<num>(0, (s, p) => s + p.totalInterestPayable);

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Loan Header
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gold Financing & Borrow Loans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Icon(Icons.handshake_outlined, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Loans', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text('${borrowPlans.length} Loans', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Principal Borrowed', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(curFmt.format(totalBorrowPrincipal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Monthly EMI Outflow', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(curFmt.format(totalBorrowEmi), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Total Interest: ${curFmt.format(totalBorrowInterest)}', style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _showAddBorrowLoanDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Gold Borrow Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          if (borrowPlans.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('No Gold Borrow Loans active.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      const Text(
                        'Track jewelry loan repayments with interest rates and EMI schedules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...borrowPlans.map((plan) => _buildBorrowPlanCard(context, plan, curFmt)),
        ],
      );
    });
  }

  Widget _buildBorrowPlanCard(BuildContext context, GoldEmiPlanModel plan, NumberFormat curFmt) {
    final progress = plan.tenureMonths > 0 ? (plan.paidInstallmentsCount / plan.tenureMonths).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.15),
          child: Icon(Icons.handshake_outlined, color: Colors.blue.shade700),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                plan.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${curFmt.format(plan.monthlyEmi)}/mo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${plan.jewelerOrLender} • ${plan.interestRateAnnual}% p.a.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  '${plan.paidInstallmentsCount}/${plan.tenureMonths} Paid',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid: ${curFmt.format(plan.totalPaidAmount)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text('Interest: ${curFmt.format(plan.totalInterestPayable)}', style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                TextButton.icon(
                  onPressed: () => _confirmDeleteEmiPlan(context, plan),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Delete Loan', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.payments.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, idx) {
              final payment = plan.payments[idx];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: payment.isPaid ? Colors.green : Colors.grey.shade300,
                  child: Icon(
                    payment.isPaid ? Icons.check : Icons.schedule,
                    size: 14,
                    color: payment.isPaid ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                title: Text(
                  'Instalment #${payment.installmentNumber} • ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: payment.isPaid ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: payment.paidDate != null
                    ? Text('Paid on ${DateFormat('dd MMM yyyy').format(payment.paidDate!)}', style: const TextStyle(fontSize: 11, color: Colors.green))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      curFmt.format(payment.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: payment.isPaid,
                      activeColor: Colors.blue,
                      onChanged: (_) {
                        repo.toggleGoldEmiPayment(plan.id, payment.id);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGS & ACTIONS
  // ==========================================

  void _showAddGoldSipDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: '30-Month Gold Savings Scheme');
    final jewelerCtrl = TextEditingController(text: 'Tanishq');
    final installmentCtrl = TextEditingController(text: '20000');
    final tenureCtrl = TextEditingController(text: '30');
    final graceDaysCtrl = TextEditingController(text: '30');
    final notesCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    int selectedPreset = 0; // 0: 30-Month Tiered, 1: 11-Month Chit, 2: Custom

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
          final inst = num.tryParse(installmentCtrl.text) ?? 20000;
          final tenure = int.tryParse(tenureCtrl.text) ?? 30;
          final grace = int.tryParse(graceDaysCtrl.text) ?? 30;
          final totalPaid = inst * tenure;
          final finalBenefitPct = selectedPreset == 0 ? 450.0 : (selectedPreset == 1 ? 100.0 : 50.0);
          final finalBenefitAmt = (inst * (finalBenefitPct / 100)).round();
          final finalJewellery = totalPaid + finalBenefitAmt;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.gold),
                SizedBox(width: 8),
                Text('New Gold SIP / Scheme'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Scheme Preset:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('30-Month', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 1, label: Text('11-Month', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 2, label: Text('Custom', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {selectedPreset},
                    onSelectionChanged: (set) {
                      setDlgState(() {
                        selectedPreset = set.first;
                        if (selectedPreset == 0) {
                          nameCtrl.text = '30-Month Gold Savings Scheme';
                          tenureCtrl.text = '30';
                          graceDaysCtrl.text = '30';
                        } else if (selectedPreset == 1) {
                          nameCtrl.text = '11-Month Jeweler Scheme';
                          tenureCtrl.text = '11';
                          graceDaysCtrl.text = '0';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Scheme Name', hintText: 'e.g. Tanishq Golden Harvest'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: jewelerCtrl,
                    decoration: const InputDecoration(labelText: 'Jeweler Name', hintText: 'e.g. Tanishq, Malabar, Kalyan'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: installmentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monthly Installment (₹)', prefixText: '₹', hintText: 'e.g. 20000'),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tenureCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tenure (Months)', suffixText: 'mo'),
                          onChanged: (_) => setDlgState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: graceDaysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Maturity Grace', suffixText: 'days'),
                          onChanged: (_) => setDlgState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Start Date: ${DateFormat('dd MMM yyyy').format(startDate)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDlgState(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Projected Maturity Summary:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                        const SizedBox(height: 4),
                        Text('• Total Capital: ${curFmt.format(totalPaid)} ($tenure installments of ${curFmt.format(inst)})', style: const TextStyle(fontSize: 11)),
                        Text('• Final Benefit: $finalBenefitPct% = +${curFmt.format(finalBenefitAmt)} bonus', style: const TextStyle(fontSize: 11)),
                        Text('• Maximum Jewellery Value: ${curFmt.format(finalJewellery)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        Text('• Maturity: $tenure months + $grace days', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final jeweler = jewelerCtrl.text.trim();
                  final installmentVal = num.tryParse(installmentCtrl.text) ?? 20000;
                  final tenureVal = int.tryParse(tenureCtrl.text) ?? 30;
                  final graceVal = int.tryParse(graceDaysCtrl.text) ?? 30;

                  if (name.isEmpty) {
                    Get.snackbar('Error', 'Please enter a scheme name');
                    return;
                  }
                  if (installmentVal <= 0 || tenureVal <= 0) {
                    Get.snackbar('Error', 'Please enter valid monthly installment and tenure');
                    return;
                  }

                  final schemeId = const Uuid().v4();
                  final payments = GoldSipSchemeModel.generateSchedule(
                    schemeId: schemeId,
                    startDate: startDate,
                    numberOfInstallments: tenureVal,
                    monthlyAmount: installmentVal,
                  );

                  Map<int, double> scheduleMap;
                  if (selectedPreset == 0) {
                    scheduleMap = GoldSipSchemeModel.default30MonthTierSchedule;
                  } else if (selectedPreset == 1) {
                    scheduleMap = GoldSipSchemeModel.default11MonthTierSchedule;
                  } else {
                    scheduleMap = {tenureVal: 100.0};
                  }

                  final scheme = GoldSipSchemeModel(
                    id: schemeId,
                    schemeName: name,
                    jewelerName: jeweler.isEmpty ? 'Jeweler' : jeweler,
                    monthlyInstallment: installmentVal,
                    totalMonths: tenureVal,
                    maturityWaitDays: graceVal,
                    startDate: startDate,
                    monthBenefitPercents: scheduleMap,
                    payments: payments,
                    createdAt: DateTime.now(),
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );

                  repo.addGoldSipScheme(scheme);
                  Navigator.pop(ctx);
                  Get.snackbar('Success', 'Gold SIP Scheme "$name" created!');
                },
                child: const Text('Create Scheme'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddBorrowLoanDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final lenderCtrl = TextEditingController();
    final principalCtrl = TextEditingController();
    final interestRateCtrl = TextEditingController(text: '9.5');
    final tenureCtrl = TextEditingController(text: '12');
    final monthlyEmiCtrl = TextEditingController();
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Add Gold Borrow Loan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Loan Title', hintText: 'e.g. Gold Loan for Wedding'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lenderCtrl,
                    decoration: const InputDecoration(labelText: 'Bank / Lender', hintText: 'e.g. Muthoot / HDFC'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: principalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Principal Amount (₹)', prefixText: '₹'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: interestRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Annual Interest Rate (%)', suffixText: '% p.a.'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tenureCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tenure (Months)', suffixText: 'months'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: monthlyEmiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monthly EMI Amount (₹)', prefixText: '₹', hintText: 'Auto calculated if blank'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Start Date: ${DateFormat('dd MMM yyyy').format(startDate)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDlgState(() => startDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final lender = lenderCtrl.text.trim();
                  final principal = num.tryParse(principalCtrl.text) ?? 0;
                  final rate = double.tryParse(interestRateCtrl.text) ?? 0;
                  final tenure = int.tryParse(tenureCtrl.text) ?? 12;
                  var monthlyEmi = num.tryParse(monthlyEmiCtrl.text) ?? 0;

                  if (title.isEmpty || principal <= 0) {
                    Get.snackbar('Error', 'Please enter title and principal amount');
                    return;
                  }

                  if (monthlyEmi <= 0) {
                    final totalInterest = principal * (rate / 100) * (tenure / 12);
                    monthlyEmi = ((principal + totalInterest) / tenure).round();
                  }

                  final planId = const Uuid().v4();
                  final payments = GoldEmiPlanModel.generateSchedule(
                    planId: planId,
                    startDate: startDate,
                    numberOfInstallments: tenure,
                    monthlyAmount: monthlyEmi,
                  );

                  final totalCost = monthlyEmi * tenure;
                  final totalInterest = totalCost - principal;

                  final plan = GoldEmiPlanModel(
                    id: planId,
                    planName: title,
                    jewelerOrBank: lender.isEmpty ? 'Bank' : lender,
                    type: GoldEmiType.borrowLoan,
                    principalOrTargetAmount: principal,
                    numberOfInstallments: tenure,
                    startDate: startDate,
                    monthlyInstallmentAmount: monthlyEmi,
                    rateOrBonusPercent: rate,
                    extraBenefitOrCostAmount: totalInterest > 0 ? totalInterest : 0,
                    finalMaturityValue: totalCost,
                    payments: payments,
                    createdAt: DateTime.now(),
                  );

                  repo.addGoldEmiPlan(plan);
                  Navigator.pop(ctx);
                  Get.snackbar('Success', 'Gold Loan plan added');
                },
                child: const Text('Save Loan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBuyDialog(BuildContext context) {
    final gramsCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: repo.currentGoldRatePerGram.value.toStringAsFixed(0));
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    void recalculateAmount() {
      final g = double.tryParse(gramsCtrl.text) ?? 0;
      final r = double.tryParse(rateCtrl.text) ?? 0;
      if (g > 0 && r > 0) {
        amountCtrl.text = (g * r).toStringAsFixed(0);
      }
    }

    void recalculateGrams() {
      final a = double.tryParse(amountCtrl.text) ?? 0;
      final r = double.tryParse(rateCtrl.text) ?? 0;
      if (a > 0 && r > 0) {
        gramsCtrl.text = (a / r).toStringAsFixed(3);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart, color: AppColors.gold),
              SizedBox(width: 8),
              Text('Buy Digital Gold'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: gramsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Gold Quantity (Grams)', suffixText: 'g', hintText: 'e.g. 2.5'),
                  onChanged: (_) => recalculateAmount(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate per Gram (₹)', prefixText: '₹', hintText: 'e.g. 7200'),
                  onChanged: (_) => recalculateAmount(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total Purchase Cost (₹)', prefixText: '₹'),
                  onChanged: (_) => recalculateGrams(),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Purchase Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDlgState(() => selectedDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes / Jeweler / Invoice (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              onPressed: () {
                final grams = double.tryParse(gramsCtrl.text) ?? 0;
                final rate = double.tryParse(rateCtrl.text) ?? 0;
                final amount = num.tryParse(amountCtrl.text) ?? (grams * rate);
                if (grams <= 0 || amount <= 0) {
                  Get.snackbar('Error', 'Please enter a valid grams quantity and amount');
                  return;
                }
                repo.addGoldInvestment(
                  amountInr: amount,
                  quantity: grams,
                  unit: GoldUnit.gram,
                  date: selectedDate,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                Get.snackbar('Success', 'Purchased ${grams.toStringAsFixed(3)}g of gold recorded');
              },
              child: const Text('Confirm Purchase'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, num totalGrams, num avgRate) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final gramsCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: repo.currentGoldRatePerGram.value.toStringAsFixed(0));
    final proceedsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final g = double.tryParse(gramsCtrl.text) ?? 0;
          final r = double.tryParse(rateCtrl.text) ?? 0;
          final proceeds = num.tryParse(proceedsCtrl.text) ?? (g * r);
          final costBasis = g * avgRate;
          final pnl = proceeds - costBasis;

          void updateProceeds() {
            final gr = double.tryParse(gramsCtrl.text) ?? 0;
            final rt = double.tryParse(rateCtrl.text) ?? 0;
            if (gr > 0 && rt > 0) {
              proceedsCtrl.text = (gr * rt).toStringAsFixed(0);
            }
            setDlgState(() {});
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.sell, color: Colors.deepOrange.shade700),
                const SizedBox(width: 8),
                const Text('Sell Digital Gold'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Vault Holdings: ${totalGrams.toStringAsFixed(3)} g (Avg Cost: ₹${avgRate.toStringAsFixed(0)}/g)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: gramsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Sell Quantity (Grams)',
                      suffixText: 'g',
                      hintText: 'Max: ${totalGrams.toStringAsFixed(3)}',
                    ),
                    onChanged: (_) => updateProceeds(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Selling Rate per Gram (₹)', prefixText: '₹'),
                    onChanged: (_) => updateProceeds(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: proceedsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Total Sale Proceeds Received (₹)', prefixText: '₹'),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (g > 0)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (pnl >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Realized Profit / Loss:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            '${pnl >= 0 ? '+' : ''}${curFmt.format(pnl)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: pnl >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Sale Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlgState(() => selectedDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes / Reason for sale (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade700, foregroundColor: Colors.white),
                onPressed: () {
                  final grams = double.tryParse(gramsCtrl.text) ?? 0;
                  final rate = double.tryParse(rateCtrl.text) ?? 0;
                  final proceedsVal = num.tryParse(proceedsCtrl.text) ?? (grams * rate);
                  if (grams <= 0 || grams > totalGrams) {
                    Get.snackbar('Error', 'Please enter a valid grams amount up to ${totalGrams.toStringAsFixed(3)}g');
                    return;
                  }
                  repo.sellGoldInvestment(
                    amountInr: proceedsVal,
                    quantity: grams,
                    unit: GoldUnit.gram,
                    date: selectedDate,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  Get.snackbar('Success', 'Sold ${grams.toStringAsFixed(3)}g gold for ${curFmt.format(proceedsVal)}');
                },
                child: const Text('Confirm Sale'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteGold(BuildContext context, GoldInvestmentModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gold Entry?'),
        content: Text('Are you sure you want to delete this ${item.isBuy ? "purchase" : "sale"} of ${item.grams.toStringAsFixed(3)}g gold?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              repo.deleteGoldInvestment(item.id);
              Navigator.pop(ctx);
              Get.snackbar('Deleted', 'Gold entry removed');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSipScheme(BuildContext context, GoldSipSchemeModel scheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gold SIP Scheme?'),
        content: Text('Are you sure you want to delete "${scheme.schemeName}"? All payment records associated with this scheme will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              repo.deleteGoldSipScheme(scheme.id);
              Navigator.pop(ctx);
              Get.snackbar('Deleted', 'Scheme removed');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEmiPlan(BuildContext context, GoldEmiPlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Loan Plan?'),
        content: Text('Are you sure you want to delete "${plan.title}"? All scheduled payments for this loan will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              repo.deleteGoldEmiPlan(plan.id);
              Navigator.pop(ctx);
              Get.snackbar('Deleted', 'Loan removed');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
