import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/data/models/gold_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class GoldView extends StatelessWidget {
  final bool hideAppBar;

  const GoldView({super.key, this.hideAppBar = false});

  void _showNewGoldPurchaseDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();

    final amountController = TextEditingController();
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    GoldUnit selectedUnit = GoldUnit.gram;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Gold Purchase'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '${repo.settings.value.currencySymbol} ',
                    labelText: 'Total Investment Amount',
                    hintText: 'e.g. 5000',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Gold Quantity',
                          hintText: 'e.g. 1.5',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<GoldUnit>(
                        value: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(value: GoldUnit.gram, child: Text('g (grams)')),
                          DropdownMenuItem(value: GoldUnit.milligram, child: Text('mg')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date',
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                    child: Text(DateFormatter.formatShort(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (e.g. 24K Coin, Digital Gold, Jeweler)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                final qty = double.tryParse(quantityController.text.trim()) ?? 0;
                final notes = notesController.text.trim();

                if (amount <= 0 || qty <= 0) return;

                await repo.addGoldInvestment(
                  amountInr: amount,
                  quantity: qty,
                  unit: selectedUnit,
                  date: selectedDate,
                  notes: notes.isNotEmpty ? notes : null,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save Gold Entry', style: TextStyle(color: Colors.black87)),
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
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('Gold Investments', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  tooltip: 'Add Gold Entry',
                  icon: const Icon(Icons.add, color: AppColors.gold),
                  onPressed: () => _showNewGoldPurchaseDialog(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Obx(() {
        final investments = repo.goldInvestments;
        final totalGrams = repo.totalGoldGrams;
        final totalInvested = repo.totalGoldInvestedInr;
        final avgRate = repo.averageGoldRatePerGram;
        final monthGold = repo.getTotalGoldInvested(month: now.month, year: now.year);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Gold Portfolio Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF78350F), const Color(0xFF1E293B)]
                          : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.25),
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
                          const Text(
                            'Total Accumulated Gold',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${investments.length} Purchases',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalGrams.toStringAsFixed(3)} grams',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.black12, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Invested', style: TextStyle(color: Colors.black54, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(totalInvested),
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Average Rate / Gram', style: TextStyle(color: Colors.black54, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.format(avgRate)} / g',
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Gold Investment summary banner
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('This Month\'s Gold Investment', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          CurrencyFormatter.format(monthGold),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Purchases History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Purchase History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Entry'),
                      onPressed: () => _showNewGoldPurchaseDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (investments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.monetization_on_outlined, size: 48, color: AppColors.lightTextMuted),
                            const SizedBox(height: 12),
                            const Text('No gold investments recorded', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text(
                              'Track physical coins, bars, jewelry, or digital gold easily.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...investments.reversed.map((inv) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.monetization_on, color: AppColors.gold, size: 22),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${inv.quantityInGrams.toStringAsFixed(3)} g Gold',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              CurrencyFormatter.format(inv.amountInr),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Rate: ${CurrencyFormatter.format(inv.ratePerGram)} / gram • ${DateFormatter.formatShort(inv.purchaseDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                inv.notes!,
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () => repo.deleteGoldInvestment(inv.id),
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
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black87,
        tooltip: 'Add Gold Entry',
        onPressed: () => _showNewGoldPurchaseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
